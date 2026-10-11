-- Nur für Entwickler (Studio-Befehlsleiste): Listen aufräumen und prüfen
local DevTools = {}

local function firstName(rest)
	local de = rest:match("^(.-) = ") or rest
	return (de:match("^([^/]+)") or de):gsub("%s+$", "")
end

-- entfernt: Zeilen mit "?", exakte Dubletten, Zeilen die dieselbe Antwort wie die Nische haben
function DevTools.clean(mod)
	local removed = 0
	mod.Source = mod.Source:gsub("a = %[%[\n(.-)%]%]", function(block)
		local niche = {}
		for line in block:gmatch("([^\n]*)\n") do
			local t, rest = line:match("^(%d) (.+)$")
			if t == "6" then niche[firstName(rest)] = true end
		end
		local seen, lines = {}, {}
		for line in block:gmatch("([^\n]*)\n") do
			local t, rest = line:match("^(%d) (.+)$")
			local drop = false
			if t then
				if rest:find("?", 1, true) or seen[line] then drop = true end
				if t ~= "6" and niche[firstName(rest)] then drop = true end
			end
			if drop then removed += 1 else seen[line] = true; lines[#lines + 1] = line end
		end
		return "a = [[\n" .. table.concat(lines, "\n") .. "\n]]"
	end)
	return removed
end

-- prüft alles, gibt Text zurück
function DevTools.check(folder)
	local tmp = (folder or script.Parent):Clone()
	local PB = require(tmp.PromptBank)
	local problems = PB.validate()
	local counts, diffs = {}, {}
	for _, p in ipairs(PB.all()) do
		counts[p.cat] = (counts[p.cat] or 0) + 1
		diffs[p.cat .. p.d] = (diffs[p.cat .. p.d] or 0) + 1
	end
	tmp:Destroy()
	local parts = {}
	for cat, n in pairs(counts) do
		parts[#parts + 1] = string.format("%s=%d (%d/%d/%d)", cat, n, diffs[cat .. 1] or 0, diffs[cat .. 2] or 0, diffs[cat .. 3] or 0)
	end
	table.sort(parts)
	return PB.count() .. " | " .. table.concat(parts, " ") .. (#problems > 0 and ("\nPROBLEME: " .. table.concat(problems, " || ")) or "")
end

-- entfernt einzelne Zeilen (exakter Text ohne Zeilenumbruch)
function DevTools.drop(mod, lines)
	local s, n = mod.Source, 0
	for _, line in ipairs(lines) do
		local i, j = string.find(s, "\n" .. line .. "\n", 1, true)
		if i then s = string.sub(s, 1, i) .. string.sub(s, j + 1); n += 1 end
	end
	mod.Source = s
	return n
end

return DevTools
