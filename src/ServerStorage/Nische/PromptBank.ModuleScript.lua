-- Lädt alle Prompts aus ServerStorage.Nische.Prompts und prüft Antworten
local Normalize = require(script.Parent.Normalize)
local PromptBank = {}

local all, byId, byCat = {}, {}, {}

local function split(s, sep)
	local t = {}
	for part in string.gmatch(s, "([^" .. sep .. "]+)") do
		part = part:gsub("^%s+", ""):gsub("%s+$", "")
		if part ~= "" then t[#t+1] = part end
	end
	return t
end

local function parse(cat, p)
	local prompt = { id = p.id, cat = cat, de = p.de, en = p.en, d = p.d, entries = {}, keys = {}, stems = {}, keyList = {} }
	for line in string.gmatch(p.a, "[^\n]+") do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		local tier = tonumber(string.sub(line, 1, 1))
		if tier and #line > 2 then
			local rest = string.sub(line, 3)
			local dePart, enPart = rest, rest
			local a, b = string.find(rest, " = ", 1, true)
			if a then dePart = string.sub(rest, 1, a - 1); enPart = string.sub(rest, b + 1) end
			local deA, enA = split(dePart, "/"), split(enPart, "/")
			if #deA > 0 and #enA > 0 then
				local entry = { tier = tier, de = deA[1], en = enA[1], id = Normalize.key(deA[1]) }
				prompt.entries[#prompt.entries+1] = entry
				if tier == 6 and not prompt.niche then prompt.niche = entry end
				local aliases = {}
				for _, x in ipairs(deA) do aliases[#aliases+1] = x end
				for _, x in ipairs(enA) do aliases[#aliases+1] = x end
				for _, alias in ipairs(aliases) do
					local k = Normalize.key(alias)
					if k ~= "" and prompt.keys[k] == nil then
						prompt.keys[k] = entry
						prompt.keyList[#prompt.keyList+1] = k
					end
					local st = Normalize.stem(k)
					if st ~= "" then
						if prompt.stems[st] == nil then prompt.stems[st] = entry
						elseif prompt.stems[st] ~= entry then prompt.stems[st] = false end
					end
				end
			end
		end
	end
	-- ohne Angabe: Schwierigkeit aus der Anzahl gültiger Antworten
	if not prompt.d then
		local n = #prompt.entries
		prompt.d = (n >= 50 and 1) or (n >= 20 and 2) or 3
	end
	return prompt
end

for _, mod in ipairs(script.Parent.Prompts:GetChildren()) do
	if mod:IsA("ModuleScript") then
		local ok, list = pcall(require, mod)
		-- Kategorie = Modulname bis zum ersten "_" (z. B. "geo_2" -> "geo")
		local cat = string.match(mod.Name, "^[^_]+")
		if ok and type(list) == "table" then
			byCat[cat] = byCat[cat] or {}
			for _, p in ipairs(list) do
				if byId[p.id] then warn("[Nische] Doppelte Prompt-ID:", p.id) end
				local prompt = parse(cat, p)
				all[#all+1] = prompt
				byId[prompt.id] = prompt
				table.insert(byCat[cat], prompt)
			end
		else
			warn("[Nische] Prompt-Modul fehlerhaft:", mod.Name, list)
		end
	end
end

function PromptBank.all() return all end

-- Findet Probleme in den Listen (für Entwickler)
function PromptBank.validate()
	local problems = {}
	for _, p in ipairs(all) do
		local nicheCount = 0
		for _, e in ipairs(p.entries) do
			if e.tier == 6 then nicheCount += 1 end
			if p.keys[Normalize.key(e.de)] ~= e then
				problems[#problems+1] = p.id .. ": '" .. e.de .. "' ist schon als andere Antwort vergeben"
			end
		end
		if nicheCount ~= 1 then problems[#problems+1] = p.id .. ": " .. nicheCount .. "x Nische" end
	end
	return problems
end

function PromptBank.get(id) return byId[id] end
function PromptBank.count() return #all end

-- n zufällige Prompts aus einer Kategorie ("alles" = alle Kategorien)
function PromptBank.pick(category, n, exclude)
	local pool = (category == "alles" or not byCat[category]) and all or byCat[category]
	local copy = {}
	for _, p in ipairs(pool) do
		if not (exclude and exclude[p.id]) then copy[#copy+1] = p end
	end
	if #copy < n then copy = table.clone(pool) end
	for i = #copy, 2, -1 do
		local j = math.random(1, i); copy[i], copy[j] = copy[j], copy[i]
	end
	local out = {}
	for i = 1, math.min(n, #copy) do out[i] = copy[i] end
	return out
end

-- Verlauf pro Spieler: welcher Prompt wurde wann zuletzt gesehen
local seenAt, counter = {}, {}

function PromptBank.markSeen(player, id)
	counter[player] = (counter[player] or 0) + 1
	seenAt[player] = seenAt[player] or {}
	seenAt[player][id] = counter[player]
end

function PromptBank.forget(player)
	seenAt[player] = nil
	counter[player] = nil
end

-- Wählt n Prompts, die die Spieler noch nie oder am längsten nicht gesehen haben.
-- So wiederholt sich nichts, bis alle Prompts einer Kategorie einmal dran waren.
-- diffs (optional): gewünschte Schwierigkeit pro Platz, z. B. {1,1,2,2,3}
-- Ungesehene Prompts haben immer Vorrang; innerhalb davon wird die Schwierigkeit beachtet.
function PromptBank.pickFor(category, n, players, diffs)
	local pool = (category == "alles" or not byCat[category]) and all or byCat[category]
	local list = {}
	for _, p in ipairs(pool) do
		local last = 0
		for _, pl in ipairs(players) do
			local s = seenAt[pl]
			if s and s[p.id] and s[p.id] > last then last = s[p.id] end
		end
		list[#list+1] = { prompt = p, last = last, r = math.random() }
	end
	table.sort(list, function(a, b)
		if a.last ~= b.last then return a.last < b.last end
		return a.r < b.r
	end)
	local out, used = {}, {}
	for i = 1, math.min(n, #list) do
		local want = diffs and diffs[i]
		local pick
		-- Kandidaten = alle noch nicht gewählten mit dem "ältesten" Stand
		local bestLast
		for _, e in ipairs(list) do if not used[e] then bestLast = e.last break end end
		if bestLast == nil then break end
		if want then
			for _, e in ipairs(list) do
				if not used[e] and e.last == bestLast and e.prompt.d == want then pick = e break end
			end
			if not pick then
				for _, e in ipairs(list) do
					if not used[e] and e.last == bestLast and math.abs(e.prompt.d - want) == 1 then pick = e break end
				end
			end
		end
		if not pick then
			for _, e in ipairs(list) do if not used[e] then pick = e break end end
		end
		used[pick] = true
		out[#out+1] = pick.prompt
	end
	-- leichte zuerst, schwere am Ende (wie gewünscht pro Platz)
	if diffs then table.sort(out, function(a, b) return a.d < b.d end) end
	return out
end

-- Gibt den passenden Eintrag zurück oder nil
function PromptBank.match(prompt, text)
	local k = Normalize.key(text)
	if k == "" or #k > 48 then return nil end
	local e = prompt.keys[k]
	if e then return e end
	local st = Normalize.stem(k)
	e = prompt.stems[st]
	if e then return e end
	local maxD = (#k >= 9 and 2) or (#k >= 5 and 1) or 0
	if maxD == 0 then return nil end
	local best, bestD, ambiguous = nil, maxD + 1, false
	for _, key in ipairs(prompt.keyList) do
		if math.abs(#key - #k) <= maxD and #key >= 4 then
			local d = Normalize.distance(k, key, maxD)
			if d < bestD then best, bestD, ambiguous = prompt.keys[key], d, false
			elseif d == bestD and best and prompt.keys[key] ~= best then ambiguous = true end
		end
	end
	if best and not ambiguous then return best end
	return nil
end

function PromptBank.text(prompt, lang) return prompt[lang] or prompt.en end
function PromptBank.display(entry, lang) return entry[lang] or entry.en end

return PromptBank
