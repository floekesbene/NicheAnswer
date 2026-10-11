-- Seltenheit als Mix: feste Stufe aus der Liste + echte Statistik, wie oft Spieler die Antwort geben.
-- Je mehr Daten, desto stärker zählt die Statistik (max. 60 %). "Die Nische" (Stufe 6) bleibt immer fest.
local DataStoreService = game:GetService("DataStoreService")
local Rarity = {}

local MIN_SAMPLES = 30
local FULL_WEIGHT_AT = 330
local MAX_WEIGHT = 0.6

local statsStore, rejectStore
pcall(function()
	statsStore = DataStoreService:GetDataStore("NischeAnswerStats_v1")
	rejectStore = DataStoreService:GetDataStore("NischeRejected_v1")
end)

local remote = {}   -- promptId -> {total, c = {entryId = n}}
local pending = {}  -- lokale, noch nicht gespeicherte Zähler
local rejects = {}  -- promptId -> {text = n}
local loading = {}

function Rarity.preload(promptId)
	if loading[promptId] or not statsStore then return end
	loading[promptId] = true
	task.spawn(function()
		local ok, data = pcall(function() return statsStore:GetAsync(promptId) end)
		if ok and type(data) == "table" then remote[promptId] = data end
	end)
end

local function counts(promptId, entryId)
	local r, p = remote[promptId], pending[promptId]
	local total = (r and r.total or 0) + (p and p.total or 0)
	local c = (r and r.c and r.c[entryId] or 0) + (p and p.c[entryId] or 0)
	return total, c
end

function Rarity.tier(prompt, entry)
	local base = entry.tier
	if base == 6 then return 6 end
	local total, c = counts(prompt.id, entry.id)
	if total < MIN_SAMPLES then return base end
	local share = c / total
	local dyn = (share >= 0.15 and 1) or (share >= 0.06 and 3) or (share >= 0.02 and 4) or 5
	local w = math.clamp((total - MIN_SAMPLES) / (FULL_WEIGHT_AT - MIN_SAMPLES), 0, 1) * MAX_WEIGHT
	local t = math.floor(base * (1 - w) + dyn * w + 0.5)
	return math.clamp(t, 1, 5)
end

function Rarity.record(prompt, entry)
	local p = pending[prompt.id]
	if not p then p = { total = 0, c = {} }; pending[prompt.id] = p end
	p.total += 1
	p.c[entry.id] = (p.c[entry.id] or 0) + 1
end

-- Falsche Antworten sammeln, um die Listen später zu erweitern
function Rarity.reject(prompt, text)
	if type(text) ~= "string" then return end
	text = string.lower(string.sub(text, 1, 40))
	local r = rejects[prompt.id]
	if not r then r = {}; rejects[prompt.id] = r end
	r[text] = (r[text] or 0) + 1
end

function Rarity.flush()
	if statsStore then
		for promptId, p in pairs(pending) do
			if p.total > 0 then
				pending[promptId] = { total = 0, c = {} }
				local ok, result = pcall(function()
					return statsStore:UpdateAsync(promptId, function(old)
						old = type(old) == "table" and old or { total = 0, c = {} }
						old.c = old.c or {}
						old.total = (old.total or 0) + p.total
						for k, v in pairs(p.c) do old.c[k] = (old.c[k] or 0) + v end
						return old
					end)
				end)
				if ok and result then
					remote[promptId] = result
				else
					-- zurücklegen, beim nächsten Mal erneut versuchen
					local q = pending[promptId]
					q.total += p.total
					for k, v in pairs(p.c) do q.c[k] = (q.c[k] or 0) + v end
				end
			end
		end
	end
	if rejectStore then
		for promptId, r in pairs(rejects) do
			rejects[promptId] = nil
			pcall(function()
				rejectStore:UpdateAsync(promptId, function(old)
					old = type(old) == "table" and old or {}
					local n = 0
					for _ in pairs(old) do n += 1 end
					for k, v in pairs(r) do
						if old[k] or n < 300 then
							if not old[k] then n += 1 end
							old[k] = (old[k] or 0) + v
						end
					end
					return old
				end)
			end)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(90)
		Rarity.flush()
	end
end)
game:BindToClose(function() Rarity.flush() end)

return Rarity
