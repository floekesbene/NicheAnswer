-- Stuhl-Skins: Preis in Coins. "default" ist gratis und gehoert jedem Spieler.
-- build = Name des Modells in ChairBuilders, tier = Effekt-Stufe (0-6): je teurer, desto mehr.
local function c(r, g, b) return Color3.fromRGB(r, g, b) end
local V = Vector3.new
local S = {}

S.list = {
	{ id = "default", de = "Klassik", en = "Classic", price = 0, tier = 0, fxText = { de = "Dein normaler Stuhl", en = "Your normal chair" },
		seat = c(235,130,90), back = c(235,130,90), legs = c(60,45,35), material = "Plastic", fx = {} },

	{ id = "candy", de = "Zuckerwatte", en = "Candy", price = 150, tier = 1, build = "candy",
		fxText = { de = "Lollipops · Leuchten · Glitzer", en = "Lollipops · glow · glitter" },
		fx = {
			{ k = "light", color = c(255,130,200), brightness = 1.6, range = 12 },
			{ k = "sparkles", color = c(255,150,220) },
		} },

	{ id = "oak", de = "Baumstumpf", en = "Tree Stump", price = 400, tier = 2, build = "oak",
		fxText = { de = "Lebender Baum · Pilze · Blätter · Glühwürmchen", en = "Living tree · mushrooms · leaves · fireflies" },
		fx = {
			{ k = "light", color = c(255,220,140), brightness = 1.4, range = 12 },
			{ k = "particles", color = c(110,190,70), rate = 8, speed = 1.5, size = 0.4, life = 3.5, accel = Vector3.new(0,-3,0), spread = 180 },
			{ k = "particles", color = c(255,240,120), rate = 4, speed = 0.8, size = 0.3, life = 3, spread = 180 },
		} },

	{ id = "ice", de = "Eisthron", en = "Ice Throne", price = 800, tier = 3, build = "ice",
		fxText = { de = "Riesige Eiskristalle · Schneefall · Frost-Licht", en = "Giant ice crystals · snowfall · frost light" },
		fx = {
			{ k = "light", color = c(150,220,255), brightness = 2.2, range = 16, pulse = true },
			{ k = "particles", color = c(255,255,255), rate = 22, speed = 1.2, size = 0.3, life = 3.5, accel = Vector3.new(0,-2.5,0), spread = 180 },
			{ k = "sparkles", color = c(150,220,255) },
		} },

	{ id = "hell", de = "Höllenstuhl", en = "Hell Chair", price = 1200, tier = 4, build = "hell",
		fxText = { de = "Hörner · Fledermausflügel · Feuer · Pentagramm", en = "Horns · bat wings · fire · pentagram" },
		fx = {
			{ k = "fire", color = c(255,120,20), secondary = c(255,40,0), size = 9, heat = 12 },
			{ k = "light", color = c(255,70,20), brightness = 3.4, range = 20, pulse = true },
			{ k = "particles", color = c(255,150,40), rate = 24, speed = 6, size = 0.3, life = 2, accel = Vector3.new(0,8,0), spread = 50 },
			{ k = "particles", color = c(40,30,30), rate = 6, speed = 3, size = 2.5, life = 2.5, accel = Vector3.new(0,4,0), spread = 40, transparencyStart = 0.6, transparencyEnd = 1 },
		} },

	{ id = "king", de = "Königsstuhl", en = "King's Throne", price = 1800, tier = 4, build = "king",
		fxText = { de = "Krone · goldene Säulen · Löwen · roter Teppich", en = "Crown · golden pillars · lions · red carpet" },
		fx = {
			{ k = "sparkles", color = c(255,215,60) },
			{ k = "light", color = c(255,210,80), brightness = 3, range = 18, pulse = true },
			{ k = "particles", color = c(255,220,90), rate = 22, speed = 3, size = 0.3, life = 2.4, accel = Vector3.new(0,3,0), spread = 70 },
			{ k = "particles", color = c(255,255,200), rate = 5, speed = 0.5, size = 0.9, life = 1.4, spread = 180, transparencyEnd = 1 },
		} },

	{ id = "cyber", de = "Cyber-Thron", en = "Cyber Throne", price = 2500, tier = 5, build = "cyber",
		fxText = { de = "Neon-Flügel · drehende Hologramm-Ringe · Datenwürfel", en = "Neon wings · spinning hologram rings · data cubes" },
		fx = {
			{ k = "light", color = c(0,255,255), brightness = 4, range = 20, pulse = true },
			{ k = "particles", color = c(255,0,200), rate = 26, speed = 7, size = 0.3, life = 1.3, shape = "Disc", spread = 10, accel = Vector3.new(0,1,0) },
			{ k = "particles", color = c(0,255,255), rate = 18, speed = 5, size = 0.25, life = 1.5, accel = Vector3.new(0,6,0), spread = 25 },
			{ k = "sparkles", color = c(0,255,255) },
		} },

	{ id = "galaxy", de = "Galaxie-Thron", en = "Galaxy Throne", price = 3500, tier = 5, build = "galaxy",
		fxText = { de = "Sternenhimmel · kreisende Planeten · Nebel", en = "Starfield · orbiting planets · nebula" },
		fx = {
			{ k = "light", color = c(150,80,255), brightness = 4, range = 22, pulse = true },
			{ k = "particles", color = c(255,255,255), rate = 32, speed = 2.5, size = 0.22, life = 2.8, spread = 180, accel = Vector3.new(0,0.5,0) },
			{ k = "particles", color = c(190,100,255), rate = 10, speed = 1, size = 2.2, life = 2.6, spread = 180, transparencyStart = 0.7, transparencyEnd = 1 },
			{ k = "particles", color = c(255,120,220), rate = 14, speed = 6, size = 0.3, life = 1.6, shape = "Disc", accel = Vector3.new(0,2,0) },
			{ k = "sparkles", color = c(170,120,255) },
		} },

	{ id = "angel", de = "Engelsthron", en = "Angel Throne", price = 5000, tier = 5, build = "angel",
		fxText = { de = "Riesige Federflügel · Heiligenschein · Wolken · Federregen", en = "Giant feather wings · halo · clouds · feather rain" },
		fx = {
			{ k = "light", color = c(255,250,230), brightness = 4.5, range = 24, pulse = true },
			{ k = "particles", color = c(255,255,255), rate = 14, speed = 1.2, size = 0.6, life = 4, accel = Vector3.new(0,-1.5,0), spread = 180 },
			{ k = "particles", color = c(255,225,140), rate = 22, speed = 4, size = 0.3, life = 2, accel = Vector3.new(0,5,0), spread = 40 },
			{ k = "particles", color = c(255,240,200), rate = 8, speed = 6, size = 0.4, life = 1.2, shape = "Disc" },
			{ k = "sparkles", color = c(255,230,150) },
		} },

	{ id = "dragon", de = "Drachenthron", en = "Dragon Throne", price = 7500, tier = 6, build = "dragon",
		fxText = { de = "Feuerspuckender Drache · Riesenflügel · Goldschatz · Rauch", en = "Fire-breathing dragon · giant wings · gold hoard · smoke" },
		fx = {
			{ k = "fire", color = c(255,130,20), secondary = c(255,40,0), size = 12, heat = 16 },
			{ k = "light", color = c(255,120,30), brightness = 5, range = 26, pulse = true },
			{ k = "particles", color = c(255,160,50), rate = 40, speed = 8, size = 0.35, life = 2.2, accel = Vector3.new(0,7,0), spread = 55 },
			{ k = "particles", color = c(35,35,35), rate = 8, speed = 3, size = 3, life = 3, accel = Vector3.new(0,4,0), spread = 40, transparencyStart = 0.6, transparencyEnd = 1 },
			{ k = "sparkles", color = c(255,200,80) },
		} },

	{ id = "god", de = "Götterthron", en = "God Throne", price = 12000, tier = 6, build = "god",
		fxText = { de = "ALLES: Regenbogen-Kristalle · goldene Flügel · kreisende Ringe & Kristalle", en = "EVERYTHING: rainbow crystals · golden wings · orbiting rings & crystals" },
		fx = {
			{ k = "rainbow" },
			{ k = "light", color = c(255,255,255), brightness = 6, range = 30, pulse = true },
			{ k = "particles", color = "rainbow", rate = 50, speed = 8, size = 0.35, life = 2, accel = Vector3.new(0,6,0), spread = 50 },
			{ k = "particles", color = "rainbow", rate = 24, speed = 9, size = 0.4, life = 1.4, shape = "Disc" },
			{ k = "particles", color = c(255,255,255), rate = 30, speed = 1.5, size = 0.3, life = 3, spread = 180, accel = Vector3.new(0,-1,0) },
			{ k = "particles", color = c(255,230,150), rate = 8, speed = 1, size = 3, life = 2, spread = 180, transparencyStart = 0.75, transparencyEnd = 1 },
			{ k = "fire", color = c(255,255,200), secondary = c(255,120,255), size = 6, heat = 10 },
			{ k = "sparkles", color = c(255,255,255) },
		} },
}

S.byId = {}
for _, s in ipairs(S.list) do S.byId[s.id] = s end

-- "default,candy" -> { default = true, candy = true }
function S.parseOwned(str)
	local set = { default = true }
	for id in string.gmatch(tostring(str or ""), "[^,]+") do set[id] = true end
	return set
end

return S
