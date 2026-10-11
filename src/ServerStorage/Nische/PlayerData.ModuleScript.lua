-- Spielerdaten: IQ, Siege, Streak, Coins … gespeichert im DataStore, gespiegelt als Attribute + leaderstats
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local PlayerData = {}

local DEFAULTS = { IQ = 0, Wins = 0, Losses = 0, Draws = 0, Streak = 0, BestStreak = 0, Coins = 0, BestDive = 0, Matches = 0, Owned = "", Chair = "default" }
local LEADERSTATS = { { "IQ", "IQ" }, { "Siege", "Wins" }, { "Coins", "Coins" } }

local store
pcall(function() store = DataStoreService:GetDataStore("NischePlayer_v1") end)

local data = {}      -- player -> table
local canSave = {}   -- nur speichern, wenn das Laden geklappt hat

local function apply(player)
	local d = data[player]
	if not d then return end
	for k, v in pairs(d) do player:SetAttribute(k, v) end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		for _, pair in ipairs(LEADERSTATS) do
			local v = ls:FindFirstChild(pair[1])
			if v then v.Value = d[pair[2]] or 0 end
		end
	end
end

function PlayerData.load(player)
	local d = table.clone(DEFAULTS)
	local loaded = false
	if store then
		for attempt = 1, 3 do
			local ok, saved = pcall(function() return store:GetAsync("u" .. player.UserId) end)
			if ok then
				loaded = true
				if type(saved) == "table" then
					for k, v in pairs(saved) do if DEFAULTS[k] ~= nil then d[k] = v end end
				end
				break
			end
			task.wait(1)
		end
	end
	canSave[player] = loaded
	if not loaded then warn("[Nische] Daten nicht geladen für", player.Name, "(Studio: API-Zugriff aktivieren?)") end

	local ls = Instance.new("Folder"); ls.Name = "leaderstats"
	for _, pair in ipairs(LEADERSTATS) do
		local v = Instance.new("IntValue"); v.Name = pair[1]; v.Parent = ls
	end
	ls.Parent = player
	data[player] = d
	apply(player)
	player:SetAttribute("DataLoaded", true)
end

function PlayerData.get(player, key)
	local d = data[player]
	return d and d[key]
end

function PlayerData.add(player, key, delta)
	local d = data[player]
	if not d then return end
	d[key] = (d[key] or 0) + delta
	if key == "IQ" and d.IQ < 0 then d.IQ = 0 end
	if key == "Streak" and d.Streak > d.BestStreak then d.BestStreak = d.Streak end
	apply(player)
end

function PlayerData.set(player, key, value)
	local d = data[player]
	if not d then return end
	d[key] = value
	if key == "Streak" and d.Streak > d.BestStreak then d.BestStreak = d.Streak end
	apply(player)
end

function PlayerData.save(player)
	local d = data[player]
	if not d or not store or not canSave[player] then return end
	pcall(function() store:SetAsync("u" .. player.UserId, d) end)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.save(player)
	data[player] = nil
	canSave[player] = nil
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(PlayerData.save, p) end
	task.wait(2)
end)

task.spawn(function()
	while true do
		task.wait(120)
		for _, p in ipairs(Players:GetPlayers()) do task.spawn(PlayerData.save, p) end
	end
end)

return PlayerData
