-- Baut komplette Stuhl-Modelle (Throne etc.) in "Stuhl-Raum": Ursprung = Sitzmitte, Rücken bei -Z, vorne +Z, Boden y = -2.
local B = {}
local PI = math.pi
local V = Vector3.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local FL = -2.2

local function newCtx(F, parent)
	local c = { F = F, parts = {}, spinners = {}, rainbow = {} }

	function c.at(x, y, z, rx, ry, rz)
		return F * CFrame.new(x or 0, y or 0, z or 0) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
	end

	local function finish(p, color, mat, o)
		p.Color = color
		p.Material = Enum.Material[mat or "SmoothPlastic"]
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if o then p.Transparency = o.t or 0; p.Reflectance = o.r or 0 end
		p.Parent = parent
		c.parts[#c.parts + 1] = p
		return p
	end
	function c.box(size, cf, color, mat, o)
		local p = Instance.new("Part"); p.Size = size; p.CFrame = cf
		return finish(p, color, mat, o)
	end
	function c.ball(d, cf, color, mat, o)
		local p = Instance.new("Part"); p.Shape = Enum.PartType.Ball; p.Size = V(d, d, d); p.CFrame = cf
		return finish(p, color, mat, o)
	end
	-- Zylinder, Achse = Y-Achse von cf
	function c.cyl(d, h, cf, color, mat, o)
		local p = Instance.new("Part"); p.Shape = Enum.PartType.Cylinder; p.Size = V(h, d, d); p.CFrame = cf * CFrame.Angles(0, 0, PI / 2)
		return finish(p, color, mat, o)
	end
	function c.wedge(size, cf, color, mat, o)
		local p = Instance.new("WedgePart"); p.Size = size; p.CFrame = cf
		return finish(p, color, mat, o)
	end

	-- Drehung: axis in Pivot-Raum ("X"/"Y"/"Z"), speed rad/s
	function c.spin(p, axis, speed, pivot)
		pivot = pivot or p.CFrame
		c.spinners[#c.spinners + 1] = { part = p, axis = axis, speed = speed, pivot = pivot, rel = pivot:ToObjectSpace(p.CFrame) }
	end
	function c.rb(p)
		c.rainbow[#c.rainbow + 1] = p
		p.Color = Color3.fromHSV((#c.rainbow * 0.07) % 1, 0.8, 1)
	end

	-- Fächer aus "Federn"; side = -1/1
	function c.wing(side, o)
		for i = 1, o.n do
			local t = o.n > 1 and (i - 1) / (o.n - 1) or 0
			local ang = math.rad(o.a0 + o.da * (i - 1))
			local len = o.len(t)
			local w = o.w or 0.5
			if o.solid then w = math.max(w, len * math.rad(math.abs(o.da)) * 1.15) end
			local dir = V(side * math.sin(ang), math.cos(ang), 0)
			local ctr = V(side * o.px, o.py, o.pz + (o.zStep or 0.03) * i) + dir * (len / 2)
			local color = (o.colorFn and o.colorFn(i, t)) or o.color or Color3.new(1, 1, 1)
			local p = c.box(V(w, len, o.th or 0.12), c.at(ctr.X, ctr.Y, ctr.Z, 0, 0, -side * ang), color, o.mat, o.o)
			if o.rb then c.rb(p) end
		end
	end

	-- Pentagramm / Kreis am Boden
	function c.star(r, color, y)
		local pts = {}
		for i = 0, 4 do local a = i * 2 * PI / 5; pts[i] = V(math.sin(a) * r, 0, math.cos(a) * r) end
		for i = 0, 4 do
			local a, b = pts[i], pts[(i + 2) % 5]
			local mid, d = (a + b) / 2, b - a
			c.box(V(0.16, 0.05, d.Magnitude), c.at(mid.X, y, mid.Z, 0, math.atan2(d.X, d.Z), 0), color, "Neon")
		end
		c.cyl(r * 2.1, 0.05, c.at(0, y, 0), color, "Neon", { t = 0.35 })
	end
	return c
end

local Builders = {}

---------------------------------------------------------------- 150 Zuckerwatte
Builders.candy = function(c)
	local pink, hot, white = rgb(255,150,200), rgb(255,85,160), rgb(255,255,255)
	c.cyl(3.6, 2.1, c.at(0,-1.2,0), white)
	for i = 0, 7 do
		local a = i / 8 * PI * 2
		c.box(V(0.5,1.7,0.12), c.at(math.sin(a)*1.79,-1.15,math.cos(a)*1.79,0,a,0), hot)
	end
	c.cyl(3.9, 0.25, c.at(0,-0.32,0), hot)
	c.cyl(3.5, 0.55, c.at(0,-0.02,0), pink)
	c.cyl(0.45, 5.4, c.at(0,2.7,-1.6), white)
	local cols, ds, head = { hot, white, pink, white, hot }, { 5.2, 4.3, 3.4, 2.5, 1.6 }, nil
	for i = 1, 5 do
		local p = c.cyl(ds[i], 0.5, c.at(0,6.6,-1.6+0.04*i,PI/2), cols[i])
		head = head or p
	end
	for _, s in ipairs({ -1, 1 }) do
		c.cyl(0.3, 3.4, c.at(s*2.8,1.3,-0.5), white)
		local rc, rd = { pink, white, hot }, { 2.4, 1.7, 1.0 }
		for i = 1, 3 do c.cyl(rd[i], 0.35, c.at(s*2.8,3.4,-0.5+0.03*i,PI/2), rc[i]) end
		c.ball(1.3, c.at(s*2.0,0.8,0.9), s > 0 and rgb(120,230,150) or rgb(255,225,90), "Glass", { t = 0.15 })
		c.ball(0.9, c.at(s*2.1,0.6,2.0), s > 0 and rgb(255,120,120) or rgb(120,200,255), "Glass", { t = 0.15 })
	end
	return head
end

---------------------------------------------------------------- 400 Baumstumpf
Builders.oak = function(c)
	local bark, wood, leaf = rgb(95,62,35), rgb(190,150,100), rgb(70,160,60)
	c.cyl(4.0, 2.1, c.at(0,-1.2,0), bark, "Wood")
	for i = 0, 5 do -- Wurzeln
		local a = i / 6 * PI * 2 + 0.3
		c.box(V(0.7,0.5,2.2), c.at(math.sin(a)*2.3,-1.8,math.cos(a)*2.3,0,a,0), bark, "Wood")
	end
	c.cyl(3.6, 0.6, c.at(0,-0.05,0), wood, "WoodPlanks")
	for i = 1, 3 do c.cyl(0.9 + i * 0.9, 0.04, c.at(0,0.27,0), rgb(150,110,65), "Wood", { t = 0 }) end
	local trunk
	for _, s in ipairs({ -1, 1 }) do
		local p = c.cyl(1.1, 7, c.at(s*1.3,3.3,-1.6,0,0,-s*0.12), bark, "Wood")
		trunk = trunk or p
		c.cyl(0.55, 3, c.at(s*3.0,5.4,-1.5,0,0,-s*1.0), bark, "Wood") -- Ast nach außen
		c.ball(3.4, c.at(s*3.8,6.6,-1.4), leaf, "Grass")
		c.ball(2.4, c.at(s*3.0,5.4,-0.6), rgb(95,185,70), "Grass")
		-- Pilze
		c.cyl(0.4, 0.9, c.at(s*2.3,0.2,1.2), rgb(240,230,210))
		c.ball(1.2, c.at(s*2.3,0.7,1.2), rgb(220,40,40)).Size = V(1.4,0.7,1.4)
		c.ball(0.22, c.at(s*2.3+0.3,0.95,1.3), rgb(255,255,255))
		c.ball(0.22, c.at(s*2.3-0.2,0.95,1.0), rgb(255,255,255))
	end
	c.ball(4.6, c.at(0,8.0,-1.7), leaf, "Grass")
	c.ball(3.2, c.at(-1.6,7.2,-0.8), rgb(85,175,65), "Grass")
	c.ball(3.2, c.at(1.6,7.2,-0.8), rgb(85,175,65), "Grass")
	for i = 1, 6 do
		local a = i * 1.1
		c.ball(0.5, c.at(math.sin(a)*3.2, 6.2 + (i % 3), -1.6 + math.cos(a)*1.4), i % 2 == 0 and rgb(255,120,160) or rgb(255,230,90), "SmoothPlastic")
	end
	return trunk
end

---------------------------------------------------------------- 800 Eisthron
Builders.ice = function(c)
	local ice, deep = rgb(190,235,255), rgb(120,200,255)
	c.box(V(3.6,2.1,3.6), c.at(0,-1.2,0), ice, "Ice", { t = 0.1 })
	c.box(V(3.9,0.2,3.9), c.at(0,-0.2,0), rgb(235,250,255), "Ice")
	c.box(V(3.0,0.5,3.0), c.at(0,0,0), rgb(225,245,255), "Ice")
	local shards = {
		{ 0, 8.4, 0, 1.2 }, { -1.3, 6.8, 0.14, 1.0 }, { 1.3, 6.8, -0.14, 1.0 }, { -2.5, 5.4, 0.3, 0.9 }, { 2.5, 5.4, -0.3, 0.9 },
		{ -3.5, 4.0, 0.55, 0.8 }, { 3.5, 4.0, -0.55, 0.8 }, { -4.3, 2.8, 0.85, 0.7 }, { 4.3, 2.8, -0.85, 0.7 },
	}
	local main
	for i, sh in ipairs(shards) do
		local x, h, tilt, w = sh[1], sh[2], sh[3], sh[4]
		local ctr = V(x, 0, -1.7) + V(-math.sin(tilt), math.cos(tilt), 0) * (h / 2) + V(0, -0.2, 0)
		local p = c.box(V(w, h, w * 0.8), c.at(ctr.X, ctr.Y, ctr.Z, 0, PI / 4, tilt), i % 2 == 0 and deep or ice, "Ice", { t = 0.2 })
		main = main or p
		-- Spitze
		local tip = V(x, 0, -1.7) + V(-math.sin(tilt), math.cos(tilt), 0) * h + V(0, -0.2, 0)
		c.wedge(V(w, 0.9, w), c.at(tip.X, tip.Y + 0.4, tip.Z, 0, 0, tilt), rgb(235,250,255), "Ice", { t = 0.1 })
	end
	for _, s in ipairs({ -1, 1 }) do
		c.box(V(0.5,0.5,3), c.at(s*1.9,0.7,0), ice, "Ice", { t = 0.1 })
		c.box(V(0.45,1.9,0.45), c.at(s*2.7,1.2,1.4,0,PI/4,-s*0.4), deep, "Ice", { t = 0.2 })
		c.box(V(0.45,1.4,0.45), c.at(s*2.3,0.9,2.1,0,PI/4,-s*0.2), ice, "Ice", { t = 0.2 })
	end
	for i = 1, 8 do -- Schneehäufchen
		local a = i / 8 * PI * 2
		c.ball(0.9 + (i % 3) * 0.3, c.at(math.sin(a)*2.9, -1.7, math.cos(a)*2.9), rgb(250,252,255), "Snow")
	end
	return main
end

---------------------------------------------------------------- 1200 Höllenstuhl
Builders.hell = function(c)
	local black, dred, lava, bone = rgb(28,22,24), rgb(110,10,10), rgb(255,70,0), rgb(235,225,205)
	c.box(V(3.6,2.1,3.6), c.at(0,-1.2,0), black, "Basalt")
	c.box(V(3.8,0.2,3.8), c.at(0,-0.28,0), lava, "Neon")
	c.box(V(3.0,0.5,3.0), c.at(0,0,0), dred, "Fabric")
	local slab = c.box(V(3.6,6.6,0.8), c.at(0,3.1,-1.6), black, "Basalt")
	for i, x in ipairs({ -1.1, -0.2, 0.7 }) do
		c.box(V(0.14,4.6 - i*0.5,0.05), c.at(x,2.9,-1.17,0,0,(i-2)*0.08), lava, "Neon")
	end
	for i, h in ipairs({ 1.6, 2.4, 3.4, 2.4, 1.6 }) do
		local x = (i - 3) * 0.78
		c.box(V(0.45,h,0.45), c.at(x,6.4+h/2,-1.6,0,PI/4,0), black, "Basalt")
		c.box(V(0.2,0.5,0.2), c.at(x,6.4+h+0.15,-1.6,0,PI/4,0), lava, "Neon")
	end
	-- Hörner
	for _, s in ipairs({ -1, 1 }) do
		local segs = { { 1.9,7.1,-0.35,2.0,0.8 }, { 2.7,8.6,-0.65,1.9,0.58 }, { 3.7,9.6,-1.0,1.7,0.4 }, { 4.6,10.2,-1.3,1.3,0.26 } }
		for _, sg in ipairs(segs) do
			c.box(V(sg[5],sg[4],sg[5]), c.at(s*sg[1],sg[2],-1.6,0,PI/4,sg[3]*s), bone, "Slate")
		end
		-- Armlehnen mit Totenköpfen
		c.box(V(0.6,0.5,3.2), c.at(s*1.9,0.75,0.1), black, "Basalt")
		c.ball(1.2, c.at(s*1.9,1.2,1.9), bone, "Slate")
		c.box(V(0.7,0.35,0.5), c.at(s*1.9,0.75,2.35), bone, "Slate")
		c.ball(0.26, c.at(s*1.9-0.28,1.3,2.4), lava, "Neon")
		c.ball(0.26, c.at(s*1.9+0.28,1.3,2.4), lava, "Neon")
		-- Fledermausflügel
		c.wing(s, { n = 7, a0 = 30, da = 15, px = 1.9, py = 4.6, pz = -1.9, len = function(t) return 4.2 + 2.4 * math.sin(t * PI * 0.9) end,
			solid = true, th = 0.1, mat = "SmoothPlastic", colorFn = function(i) return i % 2 == 0 and rgb(90,0,0) or rgb(60,0,5) end })
		c.wing(s, { n = 7, a0 = 30, da = 15, px = 1.9, py = 4.6, pz = -1.95, len = function(t) return 4.4 + 2.4 * math.sin(t * PI * 0.9) end,
			w = 0.18, th = 0.16, mat = "Basalt", color = black })
	end
	c.star(4.2, lava, FL + 0.03)
	return slab
end

---------------------------------------------------------------- 1800 Königsstuhl
Builders.king = function(c)
	local gold, red, dred, ivory = rgb(255,200,50), rgb(165,15,35), rgb(105,8,22), rgb(240,232,210)
	local go = { r = 0.2 }
	c.box(V(4.6,0.4,4.4), c.at(0,-2.0,0.2), gold, "Metal", go)
	c.box(V(3.6,1.7,3.6), c.at(0,-1.05,0), rgb(200,150,30), "Metal", go)
	c.box(V(3.8,0.18,3.8), c.at(0,-0.18,0), gold, "Metal", go)
	c.box(V(3.1,0.5,3.1), c.at(0,0,0), red, "Fabric")
	c.box(V(3.3,6.7,0.8), c.at(0,3.45,-1.6), red, "Fabric")
	for _, s in ipairs({ -1, 1 }) do
		c.box(V(0.55,7.3,1.0), c.at(s*1.95,3.7,-1.6), gold, "Metal", go)
		c.box(V(0.7,0.7,1.2), c.at(s*1.95,7.3,-1.6), gold, "Metal", go)
		-- Säulen
		c.cyl(0.9, 7.6, c.at(s*3.3,1.8,-1.4), ivory, "Marble")
		c.box(V(1.4,0.35,1.4), c.at(s*3.3,5.75,-1.4), gold, "Metal", go)
		c.box(V(1.4,0.35,1.4), c.at(s*3.3,-1.85,-1.4), gold, "Metal", go)
		c.ball(0.9, c.at(s*3.3,6.2,-1.4), gold, "Metal", go)
		-- Armlehnen mit Löwenköpfen
		c.box(V(0.65,0.45,3.1), c.at(s*1.95,0.75,0.1), gold, "Metal", go)
		c.box(V(0.5,1.2,0.5), c.at(s*1.95,0.1,1.4), gold, "Metal", go)
		c.ball(1.1, c.at(s*1.95,1.3,1.8), gold, "Metal", go)
		c.ball(0.55, c.at(s*1.95,1.15,2.3), rgb(230,170,40), "Metal", go)
		c.ball(0.18, c.at(s*1.95-0.25,1.5,2.2), rgb(40,200,255), "Neon")
		c.ball(0.18, c.at(s*1.95+0.25,1.5,2.2), rgb(40,200,255), "Neon")
	end
	local bar = c.box(V(4.5,0.65,1.2), c.at(0,7.5,-1.6), gold, "Metal", go)
	for _, x in ipairs({ -2.0, 0, 2.0 }) do c.ball(0.8, c.at(x,8.05,-1.6), gold, "Metal", go) end
	-- Krone
	c.cyl(2.6, 0.75, c.at(0,8.4,-1.6), gold, "Metal", go)
	local gems = { rgb(255,40,60), rgb(60,140,255), rgb(60,230,120), rgb(60,140,255), rgb(255,40,60) }
	for i = 0, 4 do
		local x = (i - 2) * 0.55
		local h = (i % 2 == 0) and 1.5 or 1.0
		c.box(V(0.34,h,0.34), c.at(x,8.75+h/2,-1.6,0,PI/4,0), gold, "Metal", go)
		c.ball(0.32, c.at(x,8.75+h+0.1,-1.6), gems[i+1], "Neon")
	end
	c.ball(0.8, c.at(0,8.6,-1.1), rgb(255,40,60), "Neon")
	-- Wappen
	c.cyl(1.9, 0.12, c.at(0,4.7,-1.17,PI/2), gold, "Metal", go)
	c.ball(0.9, c.at(0,4.7,-1.1), rgb(60,140,255), "Neon")
	-- Teppich
	c.box(V(3.2,0.06,6.5), c.at(0,FL+0.03,4.4), dred, "Fabric")
	for _, s in ipairs({ -1, 1 }) do c.box(V(0.2,0.07,6.5), c.at(s*1.5,FL+0.03,4.4), gold, "Metal") end
	return bar
end

---------------------------------------------------------------- 2500 Cyber-Thron
Builders.cyber = function(c)
	local dark, cyan, mag = rgb(22,24,40), rgb(0,255,255), rgb(255,0,200)
	c.box(V(3.6,2.1,3.6), c.at(0,-1.2,0), dark, "Metal")
	c.box(V(3.8,0.14,3.8), c.at(0,-0.25,0), cyan, "Neon")
	c.box(V(3.0,0.5,3.0), c.at(0,0,0), rgb(30,32,55), "SmoothPlastic")
	c.box(V(0.1,0.1,3.0), c.at(-1.45,0.27,0), cyan, "Neon")
	c.box(V(0.1,0.1,3.0), c.at(1.45,0.27,0), cyan, "Neon")
	local slab = c.box(V(3.0,6.0,0.5), c.at(0,3.1,-1.7), dark, "Metal")
	for _, x in ipairs({ -0.9, 0, 0.9 }) do c.box(V(0.14,5,0.05), c.at(x,3.1,-1.43), cyan, "Neon") end
	for _, s in ipairs({ -1, 1 }) do
		c.box(V(0.35,5.4,1.8), c.at(s*2.4,3.9,-1.5,0,0,-s*0.38), dark, "Metal")
		c.box(V(0.16,5.2,0.16), c.at(s*2.45,3.9,-0.62,0,0,-s*0.38), mag, "Neon")
		c.box(V(0.35,4.0,1.4), c.at(s*3.5,3.4,-1.5,0,0,-s*0.7), dark, "Metal")
		c.box(V(0.16,3.8,0.16), c.at(s*3.55,3.4,-0.8,0,0,-s*0.7), cyan, "Neon")
		c.box(V(0.6,0.5,3.2), c.at(s*1.9,0.75,0.1), dark, "Metal")
		c.box(V(0.1,0.1,3.0), c.at(s*1.9,1.03,0.1), mag, "Neon")
	end
	-- Hologramm-Ringe
	local r1 = c.cyl(6.2, 0.14, c.at(0,4.6,-2.5,PI/2), cyan, "Neon", { t = 0.15 })
	c.spin(r1, "X", 1.2)
	local r2 = c.cyl(4.4, 0.14, c.at(0,4.6,-2.45,PI/2), mag, "Neon", { t = 0.15 })
	c.spin(r2, "X", -1.8)
	for i = 0, 3 do -- Datenwürfel kreisen
		local cube = c.box(V(0.6,0.6,0.6), c.at(3.9,1.8,0), i % 2 == 0 and cyan or mag, "Neon")
		local piv = c.at(0,0,0)
		local p = c.at(0,0,0)
		cube.CFrame = piv * CFrame.Angles(0, i * PI / 2, 0) * CFrame.new(3.9, 1.8 + (i % 2) * 1.4, 0)
		c.spin(cube, "Y", 1.4, piv)
	end
	local grid = c.cyl(9, 0.05, c.at(0,FL+0.03,0), cyan, "Neon", { t = 0.55 })
	c.cyl(6, 0.05, c.at(0,FL+0.04,0), mag, "Neon", { t = 0.5 })
	return slab
end

---------------------------------------------------------------- 3500 Galaxie-Thron
Builders.galaxy = function(c)
	local deep, purple, star = rgb(18,8,50), rgb(150,80,255), rgb(255,255,255)
	c.cyl(3.8, 2.1, c.at(0,-1.2,0), rgb(35,18,85), "Slate")
	c.cyl(4.1, 0.2, c.at(0,-0.25,0), purple, "Neon")
	c.cyl(3.4, 0.55, c.at(0,-0.02,0), rgb(60,30,130), "Fabric")
	local disc = c.cyl(7.4, 0.35, c.at(0,3.8,-2.0,PI/2), deep, "Slate")
	for i = 1, 22 do
		local a = i * 2.399 -- goldener Winkel
		local r = 3.3 * math.sqrt(i / 22)
		local sz = (i % 4 == 0) and 0.28 or 0.16
		c.ball(sz, c.at(math.sin(a)*r, 3.8 + math.cos(a)*r, -1.8), i % 5 == 0 and rgb(255,200,120) or star, "Neon")
	end
	for i = 0, 12 do -- Bogen aus leuchtenden Kugeln
		local a = math.rad(-110 + i * (220 / 12))
		c.ball(0.6 + (i % 2) * 0.25, c.at(math.sin(a)*3.9, 3.8 + math.cos(a)*3.9, -1.7), i % 2 == 0 and purple or rgb(110,200,255), "Neon")
	end
	for _, s in ipairs({ -1, 1 }) do
		c.box(V(0.6,0.5,3.2), c.at(s*1.95,0.75,0.1), rgb(45,22,100), "Slate")
		c.ball(1.0, c.at(s*1.95,1.15,1.9), purple, "Neon", { t = 0.2 })
	end
	-- Planeten
	local piv = c.at(0,0,0)
	local function planet(d, r, h, ang, color, speed, ring)
		local p = c.ball(d, c.at(math.sin(ang)*r, h, math.cos(ang)*r), color, "SmoothPlastic")
		c.spin(p, "Y", speed, piv)
		if ring then
			local rg = c.cyl(d * 2.1, 0.08, c.at(math.sin(ang)*r, h, math.cos(ang)*r, 0.4, 0, 0.3), rgb(255,230,170), "Neon", { t = 0.2 })
			c.spin(rg, "Y", speed, piv)
		end
	end
	planet(1.3, 4.6, 2.6, 0.0, rgb(255,140,60), 0.6)
	planet(0.9, 3.9, 4.2, 2.1, rgb(80,200,255), -0.8)
	planet(1.1, 5.2, 1.2, 4.2, rgb(190,120,255), 0.45, true)
	planet(0.5, 3.4, 5.6, 1.0, rgb(240,240,240), 1.1)
	return disc
end

---------------------------------------------------------------- 5000 Engelsthron
Builders.angel = function(c)
	local white, cream, gold = rgb(250,250,255), rgb(255,244,215), rgb(255,205,60)
	c.box(V(3.7,2.1,3.7), c.at(0,-1.2,0), white, "Marble")
	c.box(V(3.95,0.2,3.95), c.at(0,-0.25,0), gold, "Metal", { r = 0.25 })
	c.box(V(3.1,0.5,3.1), c.at(0,0,0), white, "Fabric")
	for i = 0, 9 do -- Wolken
		local a = i / 10 * PI * 2
		c.ball(1.8 + (i % 3) * 0.7, c.at(math.sin(a)*2.9, -1.5 + (i % 2) * 0.3, math.cos(a)*2.9), white, "SmoothPlastic", { t = 0.1 })
	end
	local arch
	for _, s in ipairs({ -1, 1 }) do
		c.cyl(0.8, 6.6, c.at(s*1.5,1.3,-1.7), white, "Marble")
		c.box(V(1.2,0.3,1.2), c.at(s*1.5,4.75,-1.7), gold, "Metal")
		c.box(V(0.6,0.5,3.2), c.at(s*1.95,0.75,0.1), white, "Marble")
		c.ball(1.0, c.at(s*1.95,1.2,1.9), gold, "Metal")
		-- große Flügel (hintere Reihe cremefarben, vordere weiß)
		c.wing(s, { n = 10, a0 = 15, da = 12, px = 1.9, py = 4.2, pz = -2.0, len = function(t) return 4.8 + 4.5 * math.sin(t * PI * 0.85 + 0.2) end,
			solid = true, th = 0.12, mat = "SmoothPlastic", colorFn = function(i) return i % 2 == 0 and cream or white end })
		c.wing(s, { n = 8, a0 = 28, da = 13, px = 1.9, py = 3.9, pz = -1.8, len = function(t) return 3.0 + 2.8 * math.sin(t * PI * 0.85 + 0.2) end,
			solid = true, th = 0.12, mat = "SmoothPlastic", color = white })
	end
	arch = c.box(V(4.0,0.7,0.9), c.at(0,5.1,-1.7), white, "Marble")
	c.ball(1.0, c.at(0,5.8,-1.7), gold, "Metal", { r = 0.2 })
	-- Heiligenschein
	local halo = c.cyl(3.4, 0.2, c.at(0,8.8,-1.7), gold, "Neon")
	c.spin(halo, "X", 0.0001) -- bleibt waagerecht (Platzhalter)
	local halo2 = c.cyl(2.6, 0.12, c.at(0,9.0,-1.7,0.0,0,0.35), rgb(255,240,160), "Neon")
	c.spin(halo2, "X", 1.6)
	return arch
end

---------------------------------------------------------------- 7500 Drachenthron
Builders.dragon = function(c)
	local black, green, dgreen, bone, fire = rgb(25,28,26), rgb(40,120,60), rgb(20,70,38), rgb(235,225,200), rgb(255,110,20)
	c.box(V(3.7,2.1,3.7), c.at(0,-1.2,0), black, "Basalt")
	c.box(V(3.9,0.2,3.9), c.at(0,-0.28,0), fire, "Neon")
	c.box(V(3.1,0.5,3.1), c.at(0,0,0), rgb(140,20,20), "Fabric")
	local slab = c.box(V(3.4,6.4,0.9), c.at(0,3.0,-1.7), dgreen, "Slate")
	for i = 0, 6 do -- Rückenstacheln
		local y = 0.8 + i * 0.85
		c.box(V(0.3,1.0+((i%2)*0.5),0.9), c.at(0,y,-2.3,0,0,0), bone, "Slate")
	end
	for _, s in ipairs({ -1, 1 }) do
		c.wing(s, { n = 6, a0 = 25, da = 19, px = 1.9, py = 4.2, pz = -2.0, len = function(t) return 6.0 + 3.2 * math.sin(t * PI * 0.8 + 0.1) end,
			solid = true, th = 0.1, mat = "SmoothPlastic", colorFn = function(i) return i % 2 == 0 and green or dgreen end })
		c.wing(s, { n = 6, a0 = 25, da = 19, px = 1.9, py = 4.2, pz = -2.05, len = function(t) return 6.2 + 3.2 * math.sin(t * PI * 0.8 + 0.1) end,
			w = 0.3, th = 0.2, mat = "Slate", color = black })
		-- Klauen-Armlehnen
		c.box(V(0.7,0.5,3.2), c.at(s*1.95,0.75,0.1), dgreen, "Slate")
		for k = -1, 1 do
			c.box(V(0.2,0.2,0.9), c.at(s*1.95 + k*0.22, 0.75, 2.0, -0.5, 0, 0), bone, "Slate")
		end
	end
	-- Kopf
	c.box(V(1.4,2.8,1.4), c.at(0,7.4,-1.8,-0.4,0,0), dgreen, "Slate") -- Hals
	local head = c.box(V(2.0,1.5,2.2), c.at(0,8.7,-1.0,0.15,0,0), green, "Slate")
	local snout = c.box(V(1.3,0.9,1.9), c.at(0,8.4,0.6,0.15,0,0), green, "Slate")
	c.box(V(1.2,0.3,1.7), c.at(0,7.85,0.5,0.1,0,0), bone, "Slate") -- Unterkiefer
	for _, s in ipairs({ -1, 1 }) do
		c.ball(0.4, c.at(s*0.75,9.2,-0.3), rgb(255,230,40), "Neon")
		c.ball(0.18, c.at(s*0.28,8.65,1.5), fire, "Neon")
		c.box(V(0.4,2.4,0.4), c.at(s*0.8,10.0,-1.5,-0.7,0,s*0.3), bone, "Slate") -- Hörner
		c.box(V(0.28,1.8,0.28), c.at(s*1.1,11.0,-2.1,-1.0,0,s*0.5), bone, "Slate")
		for k = 0, 2 do c.box(V(0.14,0.4,0.14), c.at(s*0.45,8.0,0.1+k*0.55), bone, "Slate") end
	end
	-- Goldschatz
	for i = 1, 16 do
		local a = i * 2.4
		local r = 2.7 + (i % 3) * 0.5
		c.cyl(0.9, 0.12, c.at(math.sin(a)*r, FL+0.08+(i%2)*0.1, math.cos(a)*r, (i%3)*0.2, 0, (i%2)*0.3), rgb(255,205,50), "Metal", { r = 0.2 })
	end
	return snout
end

---------------------------------------------------------------- 12000 Götterthron
Builders.god = function(c)
	local gold, white = rgb(255,210,70), rgb(255,252,245)
	c.cyl(7.0, 0.35, c.at(0,FL+0.17,0), gold, "Metal", { r = 0.25 })
	c.cyl(5.6, 0.35, c.at(0,FL+0.5,0), white, "Marble")
	c.cyl(4.4, 1.0, c.at(0,-0.95,0), gold, "Metal", { r = 0.25 })
	c.cyl(4.6, 0.18, c.at(0,-0.38,0), white, "Neon")
	local cushion = c.cyl(3.5, 0.55, c.at(0,-0.02,0), white, "Fabric")
	-- Kristall-Strahlen
	local main
	for i = 0, 12 do
		local a = math.rad(-84 + i * 14)
		local L = 6.4 + 1.6 * math.cos((i - 6) / 6 * PI / 2)
		local base = V(0, 3.4, -2.0)
		local dir = V(math.sin(a), math.cos(a), 0)
		local ctr = base + dir * (L / 2)
		local p = c.box(V(0.55, L, 0.55), c.at(ctr.X, ctr.Y, ctr.Z, 0, PI / 4, -a), white, "Neon", { t = 0.1 })
		c.rb(p)
		main = main or p
	end
	local orb = c.ball(2.6, c.at(0,3.4,-2.1), white, "Neon", { t = 0.1 })
	c.rb(orb)
	main = orb
	for _, s in ipairs({ -1, 1 }) do
		c.cyl(0.9, 7.2, c.at(s*3.4,1.6,-1.2), white, "Marble")
		c.box(V(1.4,0.35,1.4), c.at(s*3.4,5.4,-1.2), gold, "Metal")
		c.box(V(1.4,0.35,1.4), c.at(s*3.4,-1.7,-1.2), gold, "Metal")
		local gem = c.ball(0.9, c.at(s*3.4,6.0,-1.2), white, "Neon"); c.rb(gem)
		c.box(V(0.65,0.45,3.2), c.at(s*1.95,0.75,0.1), gold, "Metal", { r = 0.25 })
		c.ball(1.0, c.at(s*1.95,1.25,1.9), white, "Neon", { t = 0.1 })
		c.wing(s, { n = 11, a0 = 12, da = 11, px = 1.9, py = 4.0, pz = -2.4, len = function(t) return 5.5 + 5.0 * math.sin(t * PI * 0.85 + 0.2) end,
			solid = true, th = 0.12, mat = "Metal", o = { r = 0.25 }, colorFn = function(i) return i % 2 == 0 and gold or rgb(255,235,150) end })
		c.wing(s, { n = 9, a0 = 20, da = 12, px = 1.9, py = 3.8, pz = -2.2, len = function(t) return 3.4 + 3.2 * math.sin(t * PI * 0.85 + 0.2) end,
			solid = true, th = 0.12, mat = "Neon", o = { t = 0.25 }, rb = true })
	end
	local h1 = c.cyl(4.0, 0.22, c.at(0,9.4,-1.9), gold, "Neon")
	c.spin(h1, "X", 0.0001)
	local h2 = c.cyl(3.0, 0.14, c.at(0,9.4,-1.9,0.5,0,0), white, "Neon"); c.rb(h2)
	c.spin(h2, "Y", 2.0)
	local h3 = c.cyl(3.4, 0.14, c.at(0,9.4,-1.9,-0.5,0,0), white, "Neon"); c.rb(h3)
	c.spin(h3, "Y", -2.4)
	local piv = c.at(0,0,0)
	for i = 0, 7 do -- kreisende Kristalle
		local cr = c.box(V(0.7,1.2,0.7), c.at(0,0,0), white, "Neon", { t = 0.1 })
		c.rb(cr)
		cr.CFrame = piv * CFrame.Angles(0, i * PI / 4, 0) * CFrame.new(5.2, 1.6 + (i % 3) * 1.2, 0) * CFrame.Angles(0.5, i, 0.5)
		c.spin(cr, "Y", 0.9, piv)
	end
	return main
end

function B.build(name, F, parent)
	local c = newCtx(F, parent)
	local fn = Builders[name]
	if not fn then return c end
	c.main = fn(c)
	if not c.main then c.main = c.parts[1] end
	return c
end

return B
