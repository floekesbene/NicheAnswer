-- Macht Eingaben vergleichbar: klein, ohne Akzente/Umlaute, ohne Leer- und Sonderzeichen
local Normalize = {}

local MAP = {
	[228]="a",[196]="a",[246]="o",[214]="o",[252]="u",[220]="u",[223]="ss",
	[224]="a",[225]="a",[226]="a",[227]="a",[229]="a",[230]="ae",
	[231]="c",[232]="e",[233]="e",[234]="e",[235]="e",
	[236]="i",[237]="i",[238]="i",[239]="i",[241]="n",
	[242]="o",[243]="o",[244]="o",[245]="o",[248]="o",
	[249]="u",[250]="u",[251]="u",[253]="y",[255]="y",
	[259]="a",[258]="a",[537]="s",[536]="s",[351]="s",[350]="s",[539]="t",[538]="t",[355]="t",
	[269]="c",[268]="c",[263]="c",[262]="c",[353]="s",[352]="s",[382]="z",[381]="z",
	[322]="l",[321]="l",[339]="oe",[338]="oe",[287]="g",[305]="i",[275]="e",[333]="o",[363]="u",
	[345]="r",[344]="r",[283]="e",[282]="e",[273]="d",[272]="d",[257]="a",[299]="i",
}

local ARTICLES = { "der ", "die ", "das ", "den ", "dem ", "ein ", "eine ", "einen ", "the ", "a ", "an " }

function Normalize.key(text)
	if type(text) ~= "string" then return "" end
	local out = {}
	local ok = pcall(function()
		for _, cp in utf8.codes(text) do
			if cp < 128 then
				local ch = string.lower(string.char(cp))
				if ch:match("%w") then out[#out+1] = ch else out[#out+1] = " " end
			else
				local c = cp
				if c >= 192 and c <= 222 and c ~= 215 then c = c + 32 end
				local m = MAP[c] or MAP[cp]
				if m then out[#out+1] = m else out[#out+1] = utf8.char(c) end
			end
		end
	end)
	if not ok then return "" end
	local s = table.concat(out):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
	for _, art in ipairs(ARTICLES) do
		if #s > #art and string.sub(s, 1, #art) == art then s = string.sub(s, #art + 1); break end
	end
	s = s:gsub(" ", "")
	s = s:gsub("ae", "a"):gsub("oe", "o"):gsub("ue", "u")
	return s
end

local SUFFIXES = { "en", "es", "er", "s", "e", "n" }
function Normalize.stem(key)
	if #key <= 5 then return key end
	for _, suf in ipairs(SUFFIXES) do
		if string.sub(key, -#suf) == suf then return string.sub(key, 1, #key - #suf) end
	end
	return key
end

-- Levenshtein mit Abbruch, sobald maxD überschritten ist
function Normalize.distance(a, b, maxD)
	local la, lb = #a, #b
	if math.abs(la - lb) > maxD then return maxD + 1 end
	local prev = {}
	for j = 0, lb do prev[j] = j end
	for i = 1, la do
		local cur = { [0] = i }
		local rowMin = i
		local ca = string.byte(a, i)
		for j = 1, lb do
			local cost = (ca == string.byte(b, j)) and 0 or 1
			local v = math.min(prev[j] + 1, cur[j-1] + 1, prev[j-1] + cost)
			cur[j] = v
			if v < rowMin then rowMin = v end
		end
		if rowMin > maxD then return maxD + 1 end
		prev = cur
	end
	return prev[lb]
end

return Normalize
