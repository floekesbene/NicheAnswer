local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = require(RS.Nische.Shared)
local Remotes = RS.Nische.Remotes
local PromptBank = require(script.Parent.PromptBank)
local Rarity = require(script.Parent.Rarity)
local PlayerData = require(script.Parent.PlayerData)
local Activity = require(script.Parent.Activity)
local C = Shared.Config

local MatchService = {}

local function now() return workspace:GetServerTimeNow() end
local function send(p, kind, payload)
	if p.Parent == Players then Remotes.MatchEvent:FireClient(p, kind, payload) end
end

local function aliveList(s)
	local t = {}
	for _, p in ipairs(s.players) do if s.alive[p] then t[#t+1] = p end end
	return t
end

-- Startet ein Match an einem Tisch. onFinished wird am Ende aufgerufen.
function MatchService.start(tableModel, players, onFinished)
	local mode = tableModel:GetAttribute("Mode") or "Normal"
	local category = tableModel:GetAttribute("Category") or "alles"
	local s = {
		table = tableModel, players = players, alive = {}, totals = {}, iq = {}, lang = {},
		hard = (mode == "Schwer"), category = category, lastSubmit = {},
	}
	s.roundTime = s.hard and C.HARD_ROUND_TIME or C.ROUND_TIME
	for _, p in ipairs(players) do
		s.alive[p] = true; s.totals[p] = 0; s.iq[p] = 0; s.lang[p] = Shared.langOf(p)
		Activity[p] = { kind = "match", session = s }
	end

	task.spawn(function()
		local diffs = s.hard and C.HARD_DIFFICULTY or ((mode == "Party") and C.PARTY_DIFFICULTY or C.MATCH_DIFFICULTY)
		local prompts = PromptBank.pickFor(category, C.ROUNDS, players, diffs)
		for _, pr in ipairs(prompts) do Rarity.preload(pr.id) end

		for _, p in ipairs(players) do
			local names = {}
			for _, o in ipairs(players) do if o ~= p then names[#names+1] = o.DisplayName end end
			send(p, "Start", { category = category, opponents = names, rounds = #prompts, hard = s.hard })
		end

		for i, prompt in ipairs(prompts) do
			if #aliveList(s) < 2 then break end
			local round = { prompt = prompt, deadline = {}, locked = {}, closed = false }
			s.round = round
			local t0 = now()
			for _, p in ipairs(aliveList(s)) do
				round.deadline[p] = t0 + s.roundTime
				PromptBank.markSeen(p, prompt.id)
				send(p, "Round", { i = i, n = #prompts, text = PromptBank.text(prompt, s.lang[p]), deadline = round.deadline[p], total = s.totals[p], d = prompt.d, cat = prompt.cat })
			end
			-- warten bis alle geantwortet haben oder die Zeit um ist
			while true do
				task.wait(0.1)
				local alive = aliveList(s)
				if #alive < 2 then break end
				local done = true
				for _, p in ipairs(alive) do
					if not round.locked[p] and now() < round.deadline[p] then done = false break end
				end
				if done then break end
			end
			round.closed = true
			if #aliveList(s) < 2 then break end

			-- Auflösung
			for _, viewer in ipairs(aliveList(s)) do
				local rows = {}
				for _, p in ipairs(s.players) do
					if s.alive[p] then
						local l = round.locked[p]
						rows[#rows+1] = {
							name = p.DisplayName, me = (p == viewer),
							answer = l and PromptBank.display(l.entry, s.lang[viewer]) or nil,
							tier = l and l.tier or 0, points = l and l.points or 0, total = s.totals[p],
						}
					end
				end
				send(viewer, "Reveal", {
					rows = rows, last = (i == #prompts),
					niche = prompt.niche and PromptBank.display(prompt.niche, s.lang[viewer]) or nil,
				})
			end
			task.wait(C.REVEAL_TIME)
		end
		s.round = nil

		-- Ergebnis
		local alive = aliveList(s)
		local best = -1
		for _, p in ipairs(alive) do best = math.max(best, s.totals[p]) end
		local topCount = 0
		for _, p in ipairs(alive) do if s.totals[p] == best then topCount += 1 end end
		local ranking = {}
		for _, p in ipairs(alive) do ranking[#ranking+1] = { name = p.DisplayName, total = s.totals[p] } end
		table.sort(ranking, function(a, b) return a.total > b.total end)

		for _, p in ipairs(alive) do
			local result
			if #alive == 1 then result = "win"
			elseif s.totals[p] == best then result = (topCount > 1) and "draw" or "win"
			else result = "lose" end
			local coins = (result == "win" and C.COINS_WIN) or (result == "draw" and C.COINS_DRAW) or C.COINS_LOSS
			PlayerData.add(p, "Coins", coins)
			PlayerData.add(p, "Matches", 1)
			if result == "win" then
				PlayerData.add(p, "Wins", 1); PlayerData.add(p, "Streak", 1)
			elseif result == "lose" then
				PlayerData.add(p, "Losses", 1); PlayerData.set(p, "Streak", 0)
			else
				PlayerData.add(p, "Draws", 1)
			end
			send(p, "End", {
				result = result, coins = coins, iq = s.iq[p], total = s.totals[p],
				depth = s.totals[p] * C.METERS_PER_POINT, ranking = ranking,
				streak = PlayerData.get(p, "Streak") or 0,
			})
			if Activity[p] and Activity[p].session == s then Activity[p] = nil end
		end
		s.finished = true
		if onFinished then onFinished() end
	end)
	return s
end

function MatchService.submit(player, s, text)
	local round = s.round
	if not round or round.closed or round.locked[player] or not s.alive[player] then return end
	local t = now()
	if t > (round.deadline[player] or 0) then return end
	if s.lastSubmit[player] and t - s.lastSubmit[player] < 0.25 then return end
	s.lastSubmit[player] = t
	if type(text) ~= "string" or #text == 0 or #text > 60 then return end

	local entry = PromptBank.match(round.prompt, text)
	if not entry then
		round.deadline[player] -= C.WRONG_PENALTY
		Rarity.reject(round.prompt, text)
		send(player, "Wrong", { deadline = round.deadline[player], penalty = C.WRONG_PENALTY })
		return
	end
	local tier = Rarity.tier(round.prompt, entry)
	local info = Shared.Tiers[tier]
	local points = info.points
	if s.hard and tier <= 2 then points = 0 end -- Schwerer Modus: Plankton & Zu clever zählen nicht
	Rarity.record(round.prompt, entry)
	round.locked[player] = { entry = entry, tier = tier, points = points }
	s.totals[player] += points
	s.iq[player] += info.iq
	PlayerData.add(player, "IQ", info.iq)
	send(player, "Locked", { answer = PromptBank.display(entry, s.lang[player]), tier = tier, points = points, total = s.totals[player], iq = info.iq })
	for _, o in ipairs(s.players) do
		if o ~= player and s.alive[o] then send(o, "OpponentLocked", { name = player.DisplayName }) end
	end
end

-- Spieler verlässt das Match (aufgestanden oder Server verlassen) = Niederlage
function MatchService.leave(player, s)
	if not s.alive[player] or s.finished then return end
	s.alive[player] = nil
	if player.Parent == Players then
		PlayerData.add(player, "Losses", 1)
		PlayerData.add(player, "Matches", 1)
		PlayerData.set(player, "Streak", 0)
		send(player, "Abort", {})
	end
	if Activity[player] and Activity[player].session == s then Activity[player] = nil end
	for _, o in ipairs(s.players) do
		if s.alive[o] then send(o, "Forfeit", { name = player.DisplayName }) end
	end
end

return MatchService
