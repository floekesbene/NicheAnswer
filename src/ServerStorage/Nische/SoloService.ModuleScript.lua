-- Solo Play: Lufttimer. Luft läuft nur während eines Prompts ab, richtige Antworten geben Luft zurück.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = require(RS.Nische.Shared)
local Remotes = RS.Nische.Remotes
local PromptBank = require(script.Parent.PromptBank)
local Rarity = require(script.Parent.Rarity)
local PlayerData = require(script.Parent.PlayerData)
local Activity = require(script.Parent.Activity)
local C = Shared.Config

local SoloService = {}
local function now() return workspace:GetServerTimeNow() end
local function send(p, kind, payload)
	if p.Parent == Players then Remotes.SoloEvent:FireClient(p, kind, payload) end
end

function SoloService.start(player)
	local s = { player = player, lang = Shared.langOf(player), points = 0, iq = 0, used = {}, answered = 0 }
	Activity[player] = { kind = "solo", session = s }
	task.spawn(function()
		local air = C.SOLO_AIR
		send(player, "Start", { air = air })
		task.wait(1)
		while air > 0 and not s.quit and player.Parent == Players do
			local n = s.answered
			local want
			if n < 3 then want = 1
			elseif n < 7 then want = (math.random() < 0.7) and 2 or 1
			elseif n < 12 then want = (math.random() < 0.5) and 3 or 2
			else want = (math.random() < 0.7) and 3 or 2 end
			local prompt = PromptBank.pickFor("alles", 1, { player }, { want })[1]
			PromptBank.markSeen(player, prompt.id)
			Rarity.preload(prompt.id)
			local round = { prompt = prompt, deadline = now() + air }
			s.round = round
			send(player, "Round", { text = PromptBank.text(prompt, s.lang), deadline = round.deadline, points = s.points, d = prompt.d, cat = prompt.cat })
			while not round.locked and not round.skipped and not s.quit and now() < round.deadline and player.Parent == Players do
				task.wait(0.1)
			end
			round.closed = true
			local remaining = math.max(0, round.deadline - now())
			if round.locked then
				air = remaining + Shared.Tiers[round.locked.tier].air
				task.wait(1.6) -- kurze Pause, Luft läuft nicht
			elseif round.skipped then
				air = remaining
				task.wait(0.4)
			else
				air = 0
			end
		end
		s.round = nil
		if player.Parent ~= Players then return end
		local depth = s.points * C.METERS_PER_POINT
		local coins = math.floor(s.points / 10)
		PlayerData.add(player, "Coins", coins)
		if depth > (PlayerData.get(player, "BestDive") or 0) then PlayerData.set(player, "BestDive", depth) end
		send(player, "End", { points = s.points, depth = depth, coins = coins, iq = s.iq, answered = s.answered, best = PlayerData.get(player, "BestDive") or depth })
		if Activity[player] and Activity[player].session == s then Activity[player] = nil end
	end)
end

function SoloService.submit(player, s, text)
	local round = s.round
	if not round or round.closed or round.locked then return end
	local t = now()
	if t > round.deadline then return end
	if s.last and t - s.last < 0.25 then return end
	s.last = t
	if type(text) ~= "string" or #text == 0 or #text > 60 then return end
	local entry = PromptBank.match(round.prompt, text)
	if not entry then
		round.deadline -= C.SOLO_WRONG
		Rarity.reject(round.prompt, text)
		send(player, "Wrong", { deadline = round.deadline, penalty = C.SOLO_WRONG })
		return
	end
	local tier = Rarity.tier(round.prompt, entry)
	local info = Shared.Tiers[tier]
	Rarity.record(round.prompt, entry)
	round.locked = { entry = entry, tier = tier }
	s.points += info.points
	s.iq += info.iq
	s.answered += 1
	PlayerData.add(player, "IQ", info.iq)
	send(player, "Locked", {
		answer = PromptBank.display(entry, s.lang), tier = tier, points = info.points, total = s.points, air = info.air,
		niche = round.prompt.niche and PromptBank.display(round.prompt.niche, s.lang) or nil,
	})
end

function SoloService.action(player, s, action)
	if action == "skip" and s.round and not s.round.closed and not s.round.locked then
		s.round.deadline -= C.SOLO_SKIP
		if s.round.deadline > now() then s.round.skipped = true end
	elseif action == "quit" then
		s.quit = true
	end
end

return SoloService
