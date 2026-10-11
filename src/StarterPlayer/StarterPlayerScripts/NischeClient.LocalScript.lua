-- Client im Krillion-Stil: Lobby (Buttons + Stats) und Tauchgang-Overlay (Match + Solo)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Nische = RS:WaitForChild("Nische")
local Shared = require(Nische:WaitForChild("Shared"))
local Remotes = Nische:WaitForChild("Remotes")
local C = Shared.Config
local lang = Shared.langOf(player)
local function T(k, ...) return Shared.t(lang, k, ...) end
local function catName(c) local info = Shared.Categories[c]; return info and info[lang] or c end
local function serverNow() return workspace:GetServerTimeNow() end

---------------------------------------------------------------- Stil
local COL = {
	navy = Color3.fromRGB(14, 24, 44),
	navy2 = Color3.fromRGB(22, 36, 64),
	edge = Color3.fromRGB(48, 70, 104),
	cyan = Color3.fromRGB(96, 224, 255),
	pink = Color3.fromRGB(255, 84, 132),
	gold = Color3.fromRGB(255, 214, 90),
	text = Color3.fromRGB(232, 240, 250),
	muted = Color3.fromRGB(124, 152, 186),
	red = Color3.fromRGB(255, 96, 96),
	dark = Color3.fromRGB(6, 12, 24),
}
local MONO = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)
local MONO_M = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium)
local PIXEL = Font.fromEnum(Enum.Font.Arcade)

local function ascii(str) return not string.find(str, "[\128-\255]") end
local function spaced(str)
	local out = {}
	for _, cp in utf8.codes(str) do out[#out + 1] = utf8.char(cp) end
	return table.concat(out, " ")
end
local function upper(str)
	local out = {}
	for _, cp in utf8.codes(str) do
		if cp >= 97 and cp <= 122 then cp -= 32
		elseif cp >= 224 and cp <= 254 and cp ~= 247 then cp -= 32
		elseif cp >= 256 and cp <= 383 and cp % 2 == 1 then cp -= 1 end
		out[#out + 1] = utf8.char(cp)
	end
	return table.concat(out)
end
local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 1
	for k, v in pairs(props or {}) do f[k] = v end
	f.Parent = parent
	return f
end
local function text(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextColor3 = COL.text
	l.FontFace = MONO
	l.TextSize = 18
	for k, v in pairs(props or {}) do l[k] = v end
	l.Parent = parent
	return l
end
-- Pixel-Schrift nur für reine ASCII-Texte (Umlaute -> Mono)
local function setPixel(l, str)
	l.FontFace = ascii(str) and PIXEL or MONO
	l.Text = str
end

-- Panel mit abgestuften Pixel-Ecken
local function panel(parent, o)
	local step = o.step or 6
	local bw = o.bw or 2
	local root = frame(nil, { Name = o.name or "Panel", Size = o.size, Position = o.pos or UDim2.new(), AnchorPoint = o.anchor or Vector2.zero, ZIndex = o.z or 1 })
	local parts = { glow = {}, border = {}, fill = {} }
	local function cross(list, color, inset, tr, z, st)
		for i = 1, 2 do
			local f = frame(root, { BackgroundColor3 = color, BackgroundTransparency = tr, ZIndex = z })
			if i == 1 then
				f.Position = UDim2.fromOffset(inset, inset + st); f.Size = UDim2.new(1, -2 * inset, 1, -2 * inset - 2 * st)
			else
				f.Position = UDim2.fromOffset(inset + st, inset); f.Size = UDim2.new(1, -2 * inset - 2 * st, 1, -2 * inset)
			end
			list[#list + 1] = f
		end
	end
	if o.glow then cross(parts.glow, o.glow, -5, 0.8, 0, step + 3) end
	cross(parts.border, o.edge or COL.edge, 0, 0, 1, step)
	cross(parts.fill, o.color or COL.navy, bw, 0, 2, step)
	local content = frame(root, { Name = "Content", Size = UDim2.fromScale(1, 1), ZIndex = 3 })
	root.Parent = parent
	return root, content, parts
end
local function recolor(list, color, tr)
	for _, f in ipairs(list) do
		if color then f.BackgroundColor3 = color end
		if tr then f.BackgroundTransparency = tr end
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "NischeUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local scales = {}
local function addScale(obj) local sc = Instance.new("UIScale"); sc.Parent = obj; scales[#scales + 1] = sc; return sc end
local function updateScale()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1200, 800)
	local sc = math.clamp(math.min(vp.X / 1150, vp.Y / 760), 0.5, 1.15)
	for _, x in ipairs(scales) do x.Scale = sc end
end

---------------------------------------------------------------- LOBBY
local lobby = frame(gui, { Name = "Lobby", Size = UDim2.fromScale(1, 1), ZIndex = 1 })

-- Stats oben
local statsRow = frame(lobby, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(660, 58) })
addScale(statsRow)
local statsLayout = Instance.new("UIListLayout")
statsLayout.FillDirection = Enum.FillDirection.Horizontal; statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statsLayout.Padding = UDim.new(0, 10); statsLayout.Parent = statsRow
local function statBox(key, color)
	local _, c = panel(statsRow, { size = UDim2.fromOffset(150, 56), step = 5 })
	local lbl = text(c, { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 12), TextSize = 12, TextColor3 = COL.muted, TextXAlignment = Enum.TextXAlignment.Left })
	setPixel(lbl, spaced(key))
	local val = text(c, { Position = UDim2.fromOffset(14, 22), Size = UDim2.new(1, -28, 0, 28), TextSize = 26, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Right, FontFace = PIXEL })
	return val
end
local coinsV = statBox(T("coins"), COL.gold)
local winsV = statBox(T("wins"), COL.text)
local iqV = statBox(T("iq"), COL.cyan)
local streakV = statBox(T("streak"), COL.pink)
local function updateStats()
	coinsV.Text = tostring(player:GetAttribute("Coins") or 0)
	winsV.Text = tostring(player:GetAttribute("Wins") or 0)
	iqV.Text = tostring(player:GetAttribute("IQ") or 0)
	streakV.Text = tostring(player:GetAttribute("Streak") or 0)
end
for _, a in ipairs({ "Coins", "Wins", "IQ", "Streak" }) do player:GetAttributeChangedSignal(a):Connect(updateStats) end
updateStats()

-- Große Buttons unten
local btnRow = frame(lobby, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -26), Size = UDim2.fromOffset(720, 100) })
addScale(btnRow)
local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal; btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center; btnLayout.Padding = UDim.new(0, 22); btnLayout.Parent = btnRow
local function bigButton(title, sub, accent)
	local root, c, parts = panel(btnRow, { size = UDim2.fromOffset(330, 92), step = 7, bw = 3, edge = accent, glow = accent })
	local press = Instance.new("UIScale"); press.Parent = root
	local t = text(c, { Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 38), TextSize = 34, RichText = true, FontFace = MONO, TextColor3 = COL.text })
	t.Text = '<font size="20" color="#' .. accent:ToHex() .. '">▼</font>  <font face="Arcade">' .. title .. '</font>  <font size="20" color="#' .. accent:ToHex() .. '">▼</font>'
	text(c, { Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 18), TextSize = 13, TextColor3 = accent, FontFace = MONO_M, Text = spaced(sub) })
	local btn = Instance.new("TextButton")
	btn.BackgroundTransparency = 1; btn.Text = ""; btn.Size = UDim2.fromScale(1, 1); btn.ZIndex = 10; btn.Parent = c
	btn.MouseEnter:Connect(function() recolor(parts.glow, nil, 0.55); recolor(parts.fill, COL.navy2) end)
	btn.MouseLeave:Connect(function() recolor(parts.glow, nil, 0.8); recolor(parts.fill, COL.navy); tween(press, 0.1, { Scale = 1 }) end)
	btn.MouseButton1Down:Connect(function() tween(press, 0.08, { Scale = 0.95 }) end)
	btn.MouseButton1Up:Connect(function() tween(press, 0.12, { Scale = 1 }, Enum.EasingStyle.Back) end)
	-- leichtes Pulsieren des Glows
	task.spawn(function()
		while root.Parent do
			for _, f in ipairs(parts.glow) do tween(f, 1.2, { BackgroundTransparency = 0.65 }, Enum.EasingStyle.Sine) end
			task.wait(1.2)
			for _, f in ipairs(parts.glow) do tween(f, 1.2, { BackgroundTransparency = 0.82 }, Enum.EasingStyle.Sine) end
			task.wait(1.2)
		end
	end)
	return btn
end
local quickBtn = bigButton(T("quickPlay"), T("quickSub"), COL.cyan)
local soloBtn = bigButton(T("soloPlay"), T("soloSub"), COL.pink)
quickBtn.Activated:Connect(function() Remotes.QuickPlay:FireServer() end)
soloBtn.Activated:Connect(function() Remotes.SoloAction:FireServer("start") end)

local seatHint = text(lobby, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.fromOffset(520, 26), TextSize = 16, FontFace = MONO_M, TextColor3 = COL.text, Text = T("leaveHint"), Visible = false, TextStrokeTransparency = 0.4 })
addScale(seatHint)

-- Toast
local toastRoot, toastC = panel(gui, { anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5, 0, 0, 84), size = UDim2.fromOffset(560, 46), step = 5, edge = COL.pink, z = 20 })
addScale(toastRoot)
toastRoot.Visible = false
local toastL = text(toastC, { Size = UDim2.fromScale(1, 1), TextSize = 17 })
local toastToken = 0
local function showToast(str, color)
	toastToken += 1
	local my = toastToken
	toastL.Text = str; toastL.TextColor3 = color or COL.text
	toastRoot.Position = UDim2.new(0.5, 0, 0, 70)
	toastRoot.Visible = true
	tween(toastRoot, 0.25, { Position = UDim2.new(0.5, 0, 0, 84) }, Enum.EasingStyle.Back)
	task.delay(2.8, function() if my == toastToken then toastRoot.Visible = false end end)
end

-- Countdown
local cdRoot, cdC = panel(gui, { anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromScale(0.5, 0.4), size = UDim2.fromOffset(360, 170), step = 7, bw = 3, edge = COL.cyan, glow = COL.cyan, z = 15 })
addScale(cdRoot)
cdRoot.Visible = false
local cdTitle = text(cdC, { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 20), TextSize = 16, TextColor3 = COL.pink })
setPixel(cdTitle, spaced(T("starting")))
local cdNum = text(cdC, { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 100), TextSize = 96, FontFace = PIXEL, TextColor3 = COL.cyan })

---------------------------------------------------------------- TAUCHGANG-OVERLAY
local dive = frame(gui, { Name = "Dive", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = COL.dark, ZIndex = 5, Visible = false })
local WATER = 0.2

-- Himmel
local sky = frame(dive, { Size = UDim2.fromScale(1, WATER), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 1 })
local skyGrad = Instance.new("UIGradient"); skyGrad.Rotation = 90
skyGrad.Color = ColorSequence.new(Color3.fromRGB(104, 180, 226), Color3.fromRGB(200, 232, 248)); skyGrad.Parent = sky
local sunGlow = frame(sky, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.82, 0.5), Size = UDim2.fromOffset(120, 120), BackgroundTransparency = 0.7, BackgroundColor3 = Color3.fromRGB(255, 244, 190), ZIndex = 2 })
Instance.new("UICorner", sunGlow).CornerRadius = UDim.new(1, 0)
local sun = frame(sky, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.82, 0.5), Size = UDim2.fromOffset(66, 66), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(255, 232, 140), ZIndex = 3 })
Instance.new("UICorner", sun).CornerRadius = UDim.new(1, 0)
local function cloud(x, y, w)
	local c = frame(sky, { Position = UDim2.fromScale(x, y), Size = UDim2.fromOffset(w, w * 0.4), ZIndex = 4 })
	frame(c, { Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.5), BackgroundTransparency = 0.05, BackgroundColor3 = Color3.new(1, 1, 1) })
	frame(c, { Position = UDim2.fromScale(0.18, 0.2), Size = UDim2.fromScale(0.45, 0.5), BackgroundTransparency = 0.05, BackgroundColor3 = Color3.new(1, 1, 1) })
	frame(c, { Position = UDim2.fromScale(0.45, 0), Size = UDim2.fromScale(0.3, 0.6), BackgroundTransparency = 0.05, BackgroundColor3 = Color3.new(1, 1, 1) })
	return c
end
local clouds = { cloud(0.05, 0.35, 140), cloud(0.38, 0.15, 110), cloud(0.62, 0.55, 160), cloud(0.9, 0.2, 100) }

-- Wasser
local water = frame(dive, { Position = UDim2.fromScale(0, WATER), Size = UDim2.fromScale(1, 1 - WATER), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 1, ClipsDescendants = true })
local wGrad = Instance.new("UIGradient"); wGrad.Rotation = 90
wGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 108, 154)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(24, 72, 120)),
	ColorSequenceKeypoint.new(0.65, Color3.fromRGB(10, 32, 64)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 8, 18)),
})
wGrad.Parent = water
frame(dive, { Position = UDim2.new(0, 0, WATER, -2), Size = UDim2.new(1, 0, 0, 4), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(130, 196, 228), ZIndex = 2 })
for i = 1, 5 do
	frame(water, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.1 + i * 0.16, 0, 0, -20), Size = UDim2.new(0, 70 + i * 8, 0.85, 0), Rotation = 14, BackgroundTransparency = 0.94, BackgroundColor3 = Color3.fromRGB(200, 235, 255), ZIndex = 2 })
end
-- Seetang
local function kelp(x, h, color)
	local k = frame(water, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(x, 1), Size = UDim2.fromOffset(40, h), ZIndex = 3 })
	frame(k, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0, 4, 1, 0), BackgroundTransparency = 0, BackgroundColor3 = color })
	for y = 0.08, 0.9, 0.11 do
		local side = (math.floor(y * 100) % 2 == 0) and 1 or -1
		frame(k, { AnchorPoint = Vector2.new(side > 0 and 0 or 1, 0), Position = UDim2.fromScale(0.5, y), Size = UDim2.fromOffset(14, 5), Rotation = side * -25, BackgroundTransparency = 0, BackgroundColor3 = color })
	end
	return k
end
kelp(0.04, 260, Color3.fromRGB(16, 34, 52)); kelp(0.09, 180, Color3.fromRGB(12, 26, 42)); kelp(0.15, 120, Color3.fromRGB(14, 30, 48))
kelp(0.86, 200, Color3.fromRGB(14, 30, 48)); kelp(0.92, 280, Color3.fromRGB(16, 34, 52))

-- Boot
local boat = frame(dive, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.25, 0, WATER, 4), Size = UDim2.fromOffset(90, 52), ZIndex = 3 })
local hullC = Color3.fromRGB(20, 34, 52)
frame(boat, { Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 0, BackgroundColor3 = hullC })
frame(boat, { Position = UDim2.new(0, 8, 1, -4), Size = UDim2.new(1, -16, 0, 4), BackgroundTransparency = 0, BackgroundColor3 = hullC })
frame(boat, { Position = UDim2.new(0, 28, 1, -24), Size = UDim2.fromOffset(34, 12), BackgroundTransparency = 0, BackgroundColor3 = hullC })
frame(boat, { Position = UDim2.new(0, 40, 0, 0), Size = UDim2.fromOffset(4, 30), BackgroundTransparency = 0, BackgroundColor3 = hullC })
frame(boat, { Position = UDim2.new(0, 24, 0, 2), Size = UDim2.fromOffset(16, 9), BackgroundTransparency = 0, BackgroundColor3 = COL.pink })

-- Tiefenbereich (Lineal, Zonen, Karten, Marker)
local depthArea = frame(dive, { Position = UDim2.new(0, 0, WATER, 8), Size = UDim2.new(1, 0, 1 - WATER, -200), ZIndex = 4 })
local ruler = frame(depthArea, { Position = UDim2.new(1, -78, 0, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundTransparency = 0.5, BackgroundColor3 = COL.muted, ZIndex = 4 })
local tickLabels = {}
for i = 0, 10 do
	local major = i % 2 == 0
	frame(ruler, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0, i / 10), Size = UDim2.fromOffset(major and 14 or 7, 2), BackgroundTransparency = 0.4, BackgroundColor3 = COL.muted, ZIndex = 4 })
	if major then
		tickLabels[i] = text(ruler, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0, -18, i / 10, 0), Size = UDim2.fromOffset(70, 12), TextSize = 11, FontFace = MONO_M, TextColor3 = COL.muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4 })
	end
end
local zoneFolder = frame(depthArea, { Size = UDim2.fromScale(1, 1), ZIndex = 4 })
local cardLayer = frame(depthArea, { Size = UDim2.fromScale(1, 1), ZIndex = 6 })
local markerLayer = frame(depthArea, { Size = UDim2.fromScale(1, 1), ZIndex = 7 })

local scaleMax = 400
local function fracOf(m) return math.clamp(m / scaleMax, 0, 1) end
local function makeMarker(name, color)
	local m = frame(markerLayer, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -74, 0, 0), Size = UDim2.fromOffset(72, 18), ZIndex = 8 })
	text(m, { Size = UDim2.fromScale(1, 1), TextSize = 13, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, Text = "◀ " .. name, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8, TextStrokeTransparency = 0.5 })
	return m
end
local markers = {}   -- name -> {frame, depth}
local function setMarker(key, name, color, depth)
	local mk = markers[key]
	if not mk then mk = { f = makeMarker(name, color), depth = 0 }; markers[key] = mk end
	mk.depth = depth
	tween(mk.f, 1.2, { Position = UDim2.new(1, -74, fracOf(depth), 0) })
end
local function clearMarkers()
	for _, mk in pairs(markers) do mk.f:Destroy() end
	markers = {}
end
local function rebuildRuler()
	for i, lbl in pairs(tickLabels) do lbl.Text = (i == 0) and "0m" or ("-" .. math.floor(scaleMax * i / 10) .. "m") end
	for _, c in ipairs(zoneFolder:GetChildren()) do c:Destroy() end
	local left = true
	for _, z in ipairs(Shared.Zones) do
		if z.m <= scaleMax then
			local row = frame(zoneFolder, { AnchorPoint = Vector2.new(left and 0 or 1, 0.5), Position = left and UDim2.new(0, 70, fracOf(z.m), 0) or UDim2.new(1, -110, fracOf(z.m), 0), Size = UDim2.fromOffset(340, 16), ZIndex = 4 })
			text(row, { Size = UDim2.fromScale(1, 1), TextSize = 13, FontFace = MONO_M, TextColor3 = Color3.fromRGB(150, 190, 220), TextTransparency = 0.35, TextXAlignment = left and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right, Text = left and ("—— " .. z[lang]) or (z[lang] .. " ——"), ZIndex = 4 })
			left = not left
		end
	end
	for _, mk in pairs(markers) do mk.f.Position = UDim2.new(1, -74, fracOf(mk.depth), 0) end
end
local function ensureScale(maxDepth)
	local want = math.max(400, math.ceil(maxDepth * 1.3 / 200) * 200)
	if want ~= scaleMax then scaleMax = want; rebuildRuler() end
end
rebuildRuler()

-- HUD oben
local leftRoot, leftC = panel(dive, { pos = UDim2.fromOffset(64, 12), size = UDim2.fromOffset(176, 64), step = 6, z = 10 })
addScale(leftRoot)
local leftLbl = text(leftC, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 12), TextSize = 12, TextColor3 = COL.muted, TextXAlignment = Enum.TextXAlignment.Left })
local leftVal = text(leftC, { Position = UDim2.fromOffset(16, 26), Size = UDim2.new(1, -32, 0, 30), TextSize = 30, FontFace = PIXEL, TextColor3 = COL.cyan, TextXAlignment = Enum.TextXAlignment.Left })
local rightRoot, rightC = panel(dive, { anchor = Vector2.new(1, 0), pos = UDim2.new(1, -64, 0, 12), size = UDim2.fromOffset(196, 64), step = 6, z = 10 })
addScale(rightRoot)
local rightLbl = text(rightC, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 12), TextSize = 12, TextColor3 = COL.muted, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd })
local rightVal = text(rightC, { Position = UDim2.fromOffset(16, 26), Size = UDim2.new(1, -32, 0, 30), TextSize = 30, FontFace = PIXEL, TextColor3 = COL.pink, TextXAlignment = Enum.TextXAlignment.Right })

local progress = frame(dive, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(260, 46), ZIndex = 10 })
addScale(progress)
local squares = frame(progress, { Size = UDim2.new(1, 0, 0, 20), ZIndex = 10 })
local sqLayout = Instance.new("UIListLayout")
sqLayout.FillDirection = Enum.FillDirection.Horizontal; sqLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sqLayout.Padding = UDim.new(0, 4); sqLayout.Parent = squares
local progressCap = text(progress, { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 12), TextSize = 10, TextColor3 = COL.muted, ZIndex = 10 })
local function setSquares(n, current)
	for _, c in ipairs(squares:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for i = 1, n do
		local col = (i < current) and COL.cyan or (i == current and COL.pink or COL.navy)
		local sq = frame(squares, { Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 0, BackgroundColor3 = col, ZIndex = 10, LayoutOrder = i })
		local st = Instance.new("UIStroke"); st.Color = COL.edge; st.Thickness = 2; st.Parent = sq
	end
end

-- Quit (Solo)
local quitRoot, quitC = panel(dive, { anchor = Vector2.new(1, 0), pos = UDim2.new(1, -64, 0, 84), size = UDim2.fromOffset(44, 40), step = 4, z = 10 })
addScale(quitRoot)
local quitBtn = Instance.new("TextButton")
quitBtn.BackgroundTransparency = 1; quitBtn.Size = UDim2.fromScale(1, 1); quitBtn.FontFace = PIXEL; quitBtn.Text = "X"; quitBtn.TextSize = 22; quitBtn.TextColor3 = COL.pink; quitBtn.ZIndex = 11; quitBtn.Parent = quitC

-- Prompt-Panel
local promptRoot, promptC = panel(dive, { anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5, 0, WATER, 16), size = UDim2.fromOffset(640, 156), step = 7, z = 10 })
addScale(promptRoot)
local promptCap = text(promptC, { Position = UDim2.fromOffset(26, 18), Size = UDim2.new(1, -52, 0, 14), TextSize = 14, TextColor3 = COL.pink, TextXAlignment = Enum.TextXAlignment.Left })
local promptBadge = text(promptC, { Position = UDim2.fromOffset(26, 18), Size = UDim2.new(1, -52, 0, 14), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right })
local promptText = text(promptC, { Position = UDim2.fromOffset(26, 42), Size = UDim2.new(1, -52, 0, 70), TextScaled = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center })
local ptc = Instance.new("UITextSizeConstraint"); ptc.MaxTextSize = 32; ptc.MinTextSize = 16; ptc.Parent = promptText
local promptHint = text(promptC, { Position = UDim2.fromOffset(26, 120), Size = UDim2.new(1, -52, 0, 16), TextSize = 13, FontFace = MONO_M, TextColor3 = COL.muted, TextXAlignment = Enum.TextXAlignment.Left, Text = T("sinkHint") })

-- Eingabeleiste unten
local bar = frame(dive, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(720, 150), ZIndex = 10 })
addScale(bar)
local feedback = text(bar, { Position = UDim2.fromOffset(96, 0), Size = UDim2.fromOffset(500, 22), TextSize = 17, ZIndex = 10, TextStrokeTransparency = 0.6 })
local status = text(bar, { Position = UDim2.fromOffset(96, 26), Size = UDim2.fromOffset(500, 18), TextSize = 14, FontFace = MONO_M, TextColor3 = COL.muted, ZIndex = 10 })
local ring = frame(bar, { Position = UDim2.fromOffset(0, 54), Size = UDim2.fromOffset(76, 76), BackgroundTransparency = 0, BackgroundColor3 = COL.navy, ZIndex = 10 })
Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
local ringStroke = Instance.new("UIStroke"); ringStroke.Color = COL.cyan; ringStroke.Thickness = 3; ringStroke.Parent = ring
local ringInner = frame(ring, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -16, 1, -16), ZIndex = 10 })
Instance.new("UICorner", ringInner).CornerRadius = UDim.new(1, 0)
local ringInnerStroke = Instance.new("UIStroke"); ringInnerStroke.Color = COL.edge; ringInnerStroke.Thickness = 1; ringInnerStroke.Parent = ringInner
local ringNum = text(ring, { Size = UDim2.fromScale(1, 1), TextSize = 28, FontFace = PIXEL, TextColor3 = COL.cyan, ZIndex = 11 })

local inputRoot, inputC, inputParts = panel(bar, { pos = UDim2.fromOffset(96, 58), size = UDim2.fromOffset(472, 66), step = 5, z = 10 })
local box = Instance.new("TextBox")
box.BackgroundTransparency = 1; box.Position = UDim2.fromOffset(18, 0); box.Size = UDim2.new(1, -36, 1, 0)
box.FontFace = MONO_M; box.TextSize = 22; box.TextColor3 = COL.text; box.PlaceholderColor3 = Color3.fromRGB(90, 112, 140)
box.PlaceholderText = T("typeHere"); box.Text = ""; box.ClearTextOnFocus = false; box.TextXAlignment = Enum.TextXAlignment.Left
box.ZIndex = 11; box.Parent = inputC
local timeBarBg = frame(bar, { Position = UDim2.fromOffset(96, 130), Size = UDim2.fromOffset(472, 4), BackgroundTransparency = 0, BackgroundColor3 = COL.navy2, ZIndex = 10 })
local timeBar = frame(timeBarBg, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = COL.cyan, ZIndex = 10 })

local diveRoot, diveC, diveParts = panel(bar, { pos = UDim2.fromOffset(584, 58), size = UDim2.fromOffset(136, 66), step = 5, color = COL.pink, edge = Color3.fromRGB(255, 150, 180), z = 10 })
local diveBtn = Instance.new("TextButton")
diveBtn.BackgroundTransparency = 1; diveBtn.Size = UDim2.fromScale(1, 1); diveBtn.TextColor3 = COL.dark
diveBtn.TextScaled = true; diveBtn.ZIndex = 11; diveBtn.Parent = diveC
local dpad = Instance.new("UIPadding"); dpad.PaddingLeft = UDim.new(0, 14); dpad.PaddingRight = UDim.new(0, 14); dpad.PaddingTop = UDim.new(0, 20); dpad.PaddingBottom = UDim.new(0, 20); dpad.Parent = diveBtn
diveBtn.FontFace = ascii(T("dive")) and PIXEL or MONO; diveBtn.Text = T("dive")

local skipRoot, skipC = panel(bar, { anchor = Vector2.new(1, 0), pos = UDim2.new(1, 0, 0, 14), size = UDim2.fromOffset(190, 34), step = 4, z = 10 })
local skipBtn = Instance.new("TextButton")
skipBtn.BackgroundTransparency = 1; skipBtn.Size = UDim2.fromScale(1, 1); skipBtn.FontFace = MONO_M; skipBtn.TextSize = 14
skipBtn.TextColor3 = COL.muted; skipBtn.Text = T("skip", C.SOLO_SKIP); skipBtn.ZIndex = 11; skipBtn.Parent = skipC

-- Auflösung
local revealRoot, revealC = panel(dive, { anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromScale(0.5, 0.55), size = UDim2.fromOffset(680, 300), step = 7, bw = 3, edge = COL.cyan, z = 30 })
addScale(revealRoot)
revealRoot.Visible = false
local revealCap = text(revealC, { Position = UDim2.fromOffset(28, 20), Size = UDim2.new(1, -56, 0, 14), TextSize = 14, TextColor3 = COL.pink, TextXAlignment = Enum.TextXAlignment.Left })
local revealPrompt = text(revealC, { Position = UDim2.fromOffset(28, 40), Size = UDim2.new(1, -56, 0, 26), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
local revealList = frame(revealC, { Position = UDim2.fromOffset(28, 78), Size = UDim2.new(1, -56, 1, -130), ZIndex = 31 })
local rl = Instance.new("UIListLayout"); rl.Padding = UDim.new(0, 8); rl.Parent = revealList
local revealNiche = text(revealC, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 28, 1, -18), Size = UDim2.new(1, -56, 0, 22), TextSize = 16, TextColor3 = COL.gold, TextXAlignment = Enum.TextXAlignment.Left })

-- Endscreen
local endRoot, endC = panel(dive, { anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromScale(0.5, 0.5), size = UDim2.fromOffset(560, 440), step = 8, bw = 3, edge = COL.cyan, glow = COL.cyan, z = 40 })
addScale(endRoot)
endRoot.Visible = false
local endTitle = text(endC, { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 56), TextSize = 52 })
local endDepthLbl = text(endC, { Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 12), TextSize = 12, TextColor3 = COL.muted })
local endDepth = text(endC, { Position = UDim2.fromOffset(0, 116), Size = UDim2.new(1, 0, 0, 50), TextSize = 50, FontFace = PIXEL, TextColor3 = COL.cyan })
local endSub = text(endC, { Position = UDim2.fromOffset(0, 168), Size = UDim2.new(1, 0, 0, 18), TextSize = 14, TextColor3 = COL.pink })
local rewardsRow = frame(endC, { Position = UDim2.fromOffset(40, 198), Size = UDim2.new(1, -80, 0, 56), ZIndex = 41 })
local rwl = Instance.new("UIListLayout"); rwl.FillDirection = Enum.FillDirection.Horizontal; rwl.HorizontalAlignment = Enum.HorizontalAlignment.Center; rwl.Padding = UDim.new(0, 10); rwl.Parent = rewardsRow
local endRanking = text(endC, { Position = UDim2.fromOffset(40, 266), Size = UDim2.new(1, -80, 0, 90), TextSize = 16, FontFace = MONO_M, TextYAlignment = Enum.TextYAlignment.Top, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41 })
local okRoot, okC, okParts = panel(endC, { anchor = Vector2.new(0.5, 1), pos = UDim2.new(0.5, 0, 1, -22), size = UDim2.fromOffset(240, 56), step = 5, bw = 3, edge = COL.cyan, z = 41 })
local okBtn = Instance.new("TextButton")
okBtn.BackgroundTransparency = 1; okBtn.Size = UDim2.fromScale(1, 1); okBtn.TextSize = 24; okBtn.TextColor3 = COL.text; okBtn.ZIndex = 42; okBtn.Parent = okC
okBtn.FontFace = ascii(T("continue")) and PIXEL or MONO; okBtn.Text = T("continue")
okBtn.MouseEnter:Connect(function() recolor(okParts.fill, COL.navy2) end)
okBtn.MouseLeave:Connect(function() recolor(okParts.fill, COL.navy) end)

local function rewardBox(label, value, color)
	local _, c = panel(rewardsRow, { size = UDim2.fromOffset(150, 54), step = 4, color = COL.navy2, z = 41 })
	local l = text(c, { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 11), TextSize = 11, TextColor3 = COL.muted, ZIndex = 42 })
	setPixel(l, spaced(label))
	text(c, { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 26), TextSize = 24, FontFace = PIXEL, TextColor3 = color, Text = value, ZIndex = 42 })
end

---------------------------------------------------------------- Ambient-Animationen
local function animateAmbient()
	task.spawn(function()
		while dive.Visible do
			-- Blase
			local x = math.random(5, 95) / 100
			local sz = math.random(4, 10)
			local b = frame(water, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, 1, 10), Size = UDim2.fromOffset(sz, sz), ZIndex = 3 })
			Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
			local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(170, 215, 240); st.Transparency = 0.4; st.Parent = b
			local dur = math.random(50, 90) / 10
			tween(b, dur, { Position = UDim2.new(x + (math.random() - 0.5) * 0.05, 0, 0, 0) }, Enum.EasingStyle.Linear)
			task.delay(dur, function() b:Destroy() end)
			-- Fisch
			if math.random() < 0.25 then
				local dir = math.random() < 0.5 and 1 or -1
				local y = math.random(10, 70) / 100
				local fsz = math.random(10, 22)
				local fish = frame(water, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(dir > 0 and -0.05 or 1.05, 0, y, 0), Size = UDim2.fromOffset(fsz, fsz * 0.45), BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(8, 22, 40), ZIndex = 3 })
				Instance.new("UICorner", fish).CornerRadius = UDim.new(1, 0)
				frame(fish, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(dir > 0 and -0.05 or 1.05, 0.5), Size = UDim2.fromOffset(fsz * 0.4, fsz * 0.4), Rotation = 45, BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(8, 22, 40), ZIndex = 3 })
				local fd = math.random(80, 160) / 10
				tween(fish, fd, { Position = UDim2.new(dir > 0 and 1.05 or -0.05, 0, y + (math.random() - 0.5) * 0.06, 0) }, Enum.EasingStyle.Linear)
				task.delay(fd, function() fish:Destroy() end)
			end
			task.wait(0.35)
		end
	end)
	task.spawn(function()
		local t = 0
		while dive.Visible do
			t += 0.05
			boat.Rotation = math.sin(t * 1.4) * 3
			boat.Position = UDim2.new(0.25, 0, WATER, 4 + math.sin(t * 1.4) * 2)
			for i, c in ipairs(clouds) do
				local x = c.Position.X.Scale + 0.00012 * i
				if x > 1.05 then x = -0.2 end
				c.Position = UDim2.new(x, 0, c.Position.Y.Scale, 0)
			end
			task.wait(0.05)
		end
	end)
end

---------------------------------------------------------------- Zustand
local mode = nil            -- "match" / "solo"
local deadline, maxTime = nil, C.ROUND_TIME
local locked, inReveal = false, false
local matchCategory, matchHard, matchRounds = "alles", false, 5
local myTotal, oppNames = 0, {}
local depthShown = Instance.new("NumberValue")
depthShown.Changed:Connect(function(v) leftVal.Text = tostring(math.floor(v + 0.5)) .. "m" end)
local currentPromptText, currentRound = "", 0
local soloCount = 0

local function setDepth(m)
	ensureScale(m)
	tween(depthShown, 1.4, { Value = m })
	setMarker("me", T("you"), COL.pink, m)
end

local function setInputEnabled(on)
	box.TextEditable = on
	recolor(diveParts.fill, on and COL.pink or Color3.fromRGB(110, 70, 90))
	recolor(inputParts.border, on and COL.cyan or COL.edge)
	if on then task.defer(function() if mode and not locked and not inReveal then box:CaptureFocus() end end) end
end

local function showRoundUI(on)
	promptRoot.Visible = on
	bar.Visible = on
	revealRoot.Visible = false
end

local function clearCards()
	for _, c in ipairs(cardLayer:GetChildren()) do c:Destroy() end
end

local function openDive(kind)
	mode = kind
	endRoot.Visible = false
	revealRoot.Visible = false
	cdRoot.Visible = false
	clearCards(); clearMarkers()
	scaleMax = 400; rebuildRuler()
	myTotal = 0
	depthShown.Value = 0; leftVal.Text = "0m"
	setPixel(leftLbl, spaced(T("depth")))
	setMarker("me", T("you"), COL.pink, 0)
	quitRoot.Visible = (kind == "solo")
	skipRoot.Visible = false
	feedback.Text = ""; status.Text = ""; box.Text = ""
	promptText.Text = ""; promptCap.Text = ""; promptBadge.Text = ""
	showRoundUI(true)
	dive.Visible = true
	lobby.Visible = false
	animateAmbient()
end

local function closeDive()
	mode = nil; deadline = nil
	dive.Visible = false
	lobby.Visible = true
	box:ReleaseFocus()
end

local function setPrompt(caption, textStr, d, cat)
	setPixel(promptCap, spaced(caption))
	local parts = {}
	if cat and cat ~= "alles" then parts[#parts + 1] = upper(catName(cat)) end
	local dinfo = d and Shared.Difficulty[d]
	if dinfo then parts[#parts + 1] = dinfo[lang] end
	local badge = table.concat(parts, "  ·  ")
	promptBadge.FontFace = MONO
	promptBadge.Text = badge
	promptBadge.TextColor3 = dinfo and dinfo.color or COL.muted
	promptText.Text = textStr
	currentPromptText = textStr
	-- kleiner Einblend-Effekt
	promptRoot.Position = UDim2.new(0.5, 0, WATER, 0)
	tween(promptRoot, 0.35, { Position = UDim2.new(0.5, 0, WATER, 16) }, Enum.EasingStyle.Back)
end

local function newRound(dl)
	inReveal = false
	locked = false
	deadline = dl
	feedback.Text = ""; status.Text = ""; box.Text = ""
	showRoundUI(true)
	-- alte Karten verblassen lassen
	for _, c in ipairs(cardLayer:GetChildren()) do
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("Frame") and d.BackgroundTransparency < 1 then tween(d, 0.6, { BackgroundTransparency = 0.75 }) end
			if d:IsA("TextLabel") then tween(d, 0.6, { TextTransparency = 0.7 }) end
		end
	end
	setInputEnabled(true)
end

-- Antwortkarte, die auf die erreichte Tiefe sinkt
local function sinkCard(answer, tier, points, toDepth)
	local info = Shared.Tiers[tier]
	local holder = frame(cardLayer, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromOffset(330, 64), ZIndex = 6 })
	addScale(holder)
	updateScale()
	local root, c = panel(holder, { size = UDim2.fromScale(1, 1), step = 5, edge = info.color, z = 6 })
	root.Rotation = -8
	local lbl = text(c, { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 1, -16), TextScaled = true, Text = "“" .. upper(answer) .. "” ▶", ZIndex = 7 })
	local tsc = Instance.new("UITextSizeConstraint"); tsc.MaxTextSize = 24; tsc.Parent = lbl
	local tag = text(holder, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 18, 0.5, 0), Size = UDim2.fromOffset(260, 22), TextSize = 16, TextColor3 = info.color, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 7, TextStrokeTransparency = 0.5, Text = "◆ " .. info[lang] .. "   +" .. points .. " · +" .. (points * C.METERS_PER_POINT) .. "m" })
	local target = math.clamp(fracOf(toDepth), 0.12, 0.9)
	tween(holder, 1.6, { Position = UDim2.fromScale(0.5, target) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	tween(root, 1.6, { Rotation = 6 }, Enum.EasingStyle.Sine)
	task.delay(1.0, function() tween(tag, 0.5, { TextTransparency = 0 }) end)
	if tier == 6 then
		-- Nische: goldenes Aufblitzen
		local flash = frame(dive, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.6, BackgroundColor3 = COL.gold, ZIndex = 50 })
		tween(flash, 0.8, { BackgroundTransparency = 1 })
		task.delay(0.9, function() flash:Destroy() end)
	end
end

local function submit()
	if not mode or locked or inReveal then return end
	local str = box.Text
	if str:gsub("%s", "") == "" then return end
	box.Text = ""
	Remotes.Submit:FireServer(str)
	task.defer(function() if mode and not locked and not inReveal then box:CaptureFocus() end end)
end
box.FocusLost:Connect(function(enter) if enter then submit() end end)
diveBtn.Activated:Connect(submit)
skipBtn.Activated:Connect(function() Remotes.SoloAction:FireServer("skip") end)
quitBtn.Activated:Connect(function() Remotes.SoloAction:FireServer("quit") end)
okBtn.Activated:Connect(function() endRoot.Visible = false; closeDive() end)

local function shake()
	local orig = UDim2.fromOffset(96, 58)
	recolor(inputParts.border, COL.red)
	for _, dx in ipairs({ -10, 10, -7, 7, -3, 0 }) do
		inputRoot.Position = orig + UDim2.fromOffset(dx, 0)
		task.wait(0.035)
	end
	inputRoot.Position = orig
	if not locked then recolor(inputParts.border, COL.cyan) end
end

local function showWrong(d)
	deadline = d.deadline
	feedback.TextColor3 = COL.red
	feedback.Text = T("wrong", d.penalty)
	task.spawn(shake)
end

local function showLocked(d)
	locked = true
	setInputEnabled(false)
	box:ReleaseFocus()
	local info = Shared.Tiers[d.tier]
	feedback.TextColor3 = info.color
	feedback.Text = "» " .. upper(d.answer)
	myTotal = d.total
	sinkCard(d.answer, d.tier, d.points, d.total * C.METERS_PER_POINT)
	task.delay(0.4, function() setDepth(myTotal * C.METERS_PER_POINT) end)
end

-- Timer
RunService.RenderStepped:Connect(function()
	if not mode or not deadline or inReveal then return end
	local rem = math.max(0, deadline - serverNow())
	local frac = math.clamp(rem / maxTime, 0, 1)
	timeBar.Size = UDim2.fromScale(frac, 1)
	local col = (rem <= 5) and COL.red or COL.cyan
	timeBar.BackgroundColor3 = col
	ringStroke.Color = col
	ringNum.TextColor3 = col
	ringNum.Text = tostring(math.ceil(rem))
end)

---------------------------------------------------------------- Match-Events
Remotes.MatchEvent.OnClientEvent:Connect(function(kind, d)
	if kind == "Countdown" then
		cdRoot.Visible = true
		cdNum.Text = tostring(d.n)
		cdNum.TextSize = 130
		tween(cdNum, 0.4, { TextSize = 96 }, Enum.EasingStyle.Back)
	elseif kind == "CountdownCancel" then
		cdRoot.Visible = false
	elseif kind == "Start" then
		matchCategory, matchHard, matchRounds = d.category, d.hard, d.rounds
		oppNames = d.opponents
		openDive("match")
		local oppName = (#d.opponents == 1) and d.opponents[1] or (#d.opponents .. "x " .. T("opponent"))
		rightLbl.FontFace = MONO; rightLbl.Text = upper(spaced(T("opponent"))) .. " · " .. oppName
		rightVal.Text = "0m"
		setSquares(d.rounds, 1)
		setPixel(progressCap, spaced(T("promptOf", 1, d.rounds)))
		setPrompt(matchHard and T("hardMode") or catName(matchCategory), T("vs", table.concat(d.opponents, ", ")), nil, nil)
		bar.Visible = false
		for i, n in ipairs(d.opponents) do setMarker("opp" .. i, n, COL.cyan, 0) end
	elseif kind == "Round" then
		currentRound = d.i
		maxTime = math.max(1, d.deadline - serverNow())
		setSquares(d.n, d.i)
		setPixel(progressCap, spaced(T("promptOf", d.i, d.n)))
		setPrompt(T("promptOf", d.i, d.n), d.text, d.d, d.cat)
		newRound(d.deadline)
	elseif kind == "Wrong" then
		showWrong(d)
	elseif kind == "Locked" then
		showLocked(d)
		status.Text = T("waitingOthers")
	elseif kind == "OpponentLocked" then
		if not locked then status.Text = "● " .. T("answered", d.name) end
	elseif kind == "Reveal" then
		inReveal = true
		showRoundUI(false)
		for _, c in ipairs(revealList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		setPixel(revealCap, spaced(T("results", currentRound)))
		revealPrompt.Text = currentPromptText
		local maxDepth, oppIndex = 0, 0
		for _, r in ipairs(d.rows) do
			local info = Shared.Tiers[r.tier]
			local row = frame(revealList, { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 0, BackgroundColor3 = r.me and COL.navy2 or Color3.fromRGB(16, 28, 50), ZIndex = 31 })
			local st = Instance.new("UIStroke"); st.Color = r.me and COL.pink or COL.edge; st.Thickness = 1; st.Parent = row
			text(row, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.24, 0, 1, 0), TextSize = 14, FontFace = MONO_M, TextColor3 = r.me and COL.pink or COL.cyan, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = r.name, ZIndex = 32 })
			text(row, { Position = UDim2.new(0.26, 0, 0, 0), Size = UDim2.new(0.38, 0, 1, 0), TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = r.answer and COL.text or COL.muted, Text = r.answer and ("“" .. upper(r.answer) .. "”") or T("noAnswer"), ZIndex = 32 })
			text(row, { Position = UDim2.new(0.65, 0, 0, 0), Size = UDim2.new(0.2, 0, 1, 0), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = info and info.color or COL.muted, Text = info and ("◆ " .. info[lang]) or "", ZIndex = 32 })
			text(row, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0.14, 0, 1, 0), TextSize = 20, FontFace = PIXEL, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = COL.cyan, Text = "+" .. r.points, ZIndex = 32 })
			local m = r.total * C.METERS_PER_POINT
			maxDepth = math.max(maxDepth, m)
			if not r.me then
				oppIndex += 1
				setMarker("opp" .. oppIndex, r.name, COL.cyan, m)
				if oppIndex == 1 then rightVal.Text = m .. "m" end
			end
		end
		ensureScale(maxDepth)
		revealRoot.Size = UDim2.fromOffset(680, 140 + #d.rows * 52)
		revealNiche.Text = d.niche and T("nicheWas", upper(d.niche)) or ""
		revealRoot.Visible = true
		revealRoot.Position = UDim2.fromScale(0.5, 0.6)
		tween(revealRoot, 0.35, { Position = UDim2.fromScale(0.5, 0.55) }, Enum.EasingStyle.Back)
	elseif kind == "Forfeit" then
		showToast(T("forfeit", d.name), COL.gold)
	elseif kind == "Abort" then
		closeDive()
	elseif kind == "End" then
		inReveal = true
		deadline = nil
		showRoundUI(false)
		local title, color
		if d.result == "win" then title, color = T("win"), COL.gold
		elseif d.result == "lose" then title, color = T("lose"), COL.pink
		else title, color = T("draw"), COL.cyan end
		setPixel(endTitle, title); endTitle.TextColor3 = color
		setPixel(endDepthLbl, spaced(T("depth")))
		endDepth.Text = d.depth .. "m"
		endSub.Text = ""
		setDepth(d.depth)
		for _, c in ipairs(rewardsRow:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
		rewardBox(T("coins"), "+" .. d.coins, COL.gold)
		rewardBox(T("iq"), string.format("%+d", d.iq), COL.cyan)
		rewardBox(T("streak"), tostring(d.streak or 0), COL.pink)
		local lines = {}
		for i, r in ipairs(d.ranking) do lines[#lines + 1] = string.format("%d.  %s  —  %dm", i, r.name, r.total * C.METERS_PER_POINT) end
		endRanking.Text = table.concat(lines, "\n")
		endRoot.Visible = true
		endRoot.Position = UDim2.fromScale(0.5, 0.56)
		tween(endRoot, 0.4, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back)
		local my = d
		task.delay(12, function() if endRoot.Visible and mode == "match" then endRoot.Visible = false; closeDive() end end)
	end
end)

---------------------------------------------------------------- Solo-Events
Remotes.SoloEvent.OnClientEvent:Connect(function(kind, d)
	if kind == "Start" then
		openDive("solo")
		soloCount = 0
		rightLbl.FontFace = PIXEL; rightLbl.Text = spaced(T("record"))
		rightVal.Text = tostring(player:GetAttribute("BestDive") or 0) .. "m"
		setSquares(0, 0)
		setPixel(progressCap, spaced(T("air") .. " " .. C.SOLO_AIR .. "s"))
		setPrompt(T("soloPlay"), "…", nil, nil)
		bar.Visible = false
	elseif kind == "Round" then
		soloCount += 1
		maxTime = math.max(C.SOLO_AIR, d.deadline - serverNow())
		setPixel(progressCap, spaced(T("promptN", soloCount)))
		setPrompt(T("promptN", soloCount), d.text, d.d, d.cat)
		newRound(d.deadline)
		skipRoot.Visible = true
	elseif kind == "Wrong" then
		showWrong(d)
	elseif kind == "Locked" then
		showLocked(d)
		skipRoot.Visible = false
		status.Text = "+" .. d.air .. "s " .. T("air") .. (d.niche and ("    " .. T("nicheWas", upper(d.niche))) or "")
	elseif kind == "End" then
		inReveal = true
		deadline = nil
		showRoundUI(false)
		setPixel(endTitle, T("soloOver")); endTitle.TextColor3 = COL.cyan
		setPixel(endDepthLbl, spaced(T("depth")))
		endDepth.Text = d.depth .. "m"
		local isRecord = d.depth > 0 and d.depth >= (d.best or 0)
		endSub.Text = isRecord and spaced(T("newRecord")) or (T("record") .. ": " .. (d.best or 0) .. "m")
		for _, c in ipairs(rewardsRow:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
		rewardBox(T("coins"), "+" .. d.coins, COL.gold)
		rewardBox(T("iq"), string.format("%+d", d.iq), COL.cyan)
		rewardBox("PROMPTS", tostring(d.answered or 0), COL.pink)
		endRanking.Text = ""
		endRoot.Visible = true
		endRoot.Position = UDim2.fromScale(0.5, 0.56)
		tween(endRoot, 0.4, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back)
	end
end)

Remotes.Notify.OnClientEvent:Connect(function(key, args)
	showToast(T(key, table.unpack(args or {})), COL.gold)
end)

---------------------------------------------------------------- Deine MainUI einbinden (Buttons, Coin-/Pokal-Leiste)
local mainUI = player:WaitForChild("PlayerGui"):WaitForChild("MainUI", 10)
local mainPlay = mainUI and mainUI:FindFirstChild("PlayButtons")
local useMain = mainPlay ~= nil and mainPlay:FindFirstChild("QuickPlay") ~= nil

local function hookButton(btn, onClick)
	if not btn then return end
	local sc = btn:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", btn)
	local glow = btn:FindFirstChild("Glow")
	local gs = glow and glow:FindFirstChildOfClass("UIStroke")
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = COL.navy2
		if gs then tween(gs, 0.15, { Transparency = 0.35 }) end
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = COL.navy
		if gs then tween(gs, 0.15, { Transparency = 0.75 }) end
		tween(sc, 0.1, { Scale = 1 })
	end)
	btn.MouseButton1Down:Connect(function() tween(sc, 0.08, { Scale = 0.95 }) end)
	btn.MouseButton1Up:Connect(function() tween(sc, 0.12, { Scale = 1 }, Enum.EasingStyle.Back) end)
	btn.Activated:Connect(onClick)
	-- Glow pulsiert leicht
	if gs then
		task.spawn(function()
			while btn.Parent do
				if btn.BackgroundColor3 == COL.navy then tween(gs, 1.2, { Transparency = 0.55 }, Enum.EasingStyle.Sine) end
				task.wait(1.2)
				if btn.BackgroundColor3 == COL.navy then tween(gs, 1.2, { Transparency = 0.8 }, Enum.EasingStyle.Sine) end
				task.wait(1.2)
			end
		end)
	end
end

if useMain then
	local q, s = mainPlay:FindFirstChild("QuickPlay"), mainPlay:FindFirstChild("SoloPlay")
	hookButton(q, function() Remotes.QuickPlay:FireServer() end)
	hookButton(s, function() Remotes.SoloAction:FireServer("start") end)
	if q and q:FindFirstChild("Sub") then q.Sub.Text = spaced(T("quickSub")) end
	if s and s:FindFirstChild("Sub") then s.Sub.Text = spaced(T("soloSub")) end
	btnRow:Destroy()
	statsRow:Destroy()
	-- Coin-/Pokal-Leiste mit echten Werten füllen
	local top = mainUI:FindFirstChild("TopBar")
	local coinsAmount = top and top:FindFirstChild("Coins") and top.Coins:FindFirstChild("Amount")
	local trophyAmount = top and top:FindFirstChild("Trophies") and top.Trophies:FindFirstChild("Amount")
	local function updTop()
		if coinsAmount then coinsAmount.Text = tostring(player:GetAttribute("Coins") or 0) end
		if trophyAmount then trophyAmount.Text = tostring(player:GetAttribute("Wins") or 0) end
	end
	player:GetAttributeChangedSignal("Coins"):Connect(updTop)
	player:GetAttributeChangedSignal("Wins"):Connect(updTop)
	updTop()
end

---------------------------------------------------------------- Lobby-Sichtbarkeit
RunService.Heartbeat:Connect(function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seated = hum and hum.SeatPart ~= nil
	local free = (mode == nil) and not seated
	if useMain then
		mainUI.Enabled = not dive.Visible
		mainPlay.Visible = free
	else
		btnRow.Visible = free
		statsRow.Visible = (mode == nil)
	end
	gui:SetAttribute("InGame", mode ~= nil)
	seatHint.Visible = seated and mode == nil and not cdRoot.Visible
	if not seated and cdRoot.Visible and mode == nil then cdRoot.Visible = false end
end)

---------------------------------------------------------------- Tischanzeigen
local function setupTableDisplay(t)
	local top = t:WaitForChild("TableTop", 10)
	if not top then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "TableDisplay"; bb.Size = UDim2.fromScale(9, 4); bb.StudsOffset = Vector3.new(0, 6, 0)
	bb.MaxDistance = 220; bb.LightInfluence = 0; bb.Adornee = top; bb.Parent = gui
	local cat = t:GetAttribute("Category") or "alles"
	local info = Shared.Categories[cat]
	local catL = text(bb, { Size = UDim2.fromScale(1, 0.46), TextScaled = true, TextColor3 = info and info.color or COL.text, TextStrokeTransparency = 0, TextStrokeColor3 = COL.dark })
	setPixel(catL, upper(catName(cat)))
	local countL = text(bb, { Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.5), TextScaled = true, FontFace = PIXEL, TextColor3 = COL.cyan, TextStrokeTransparency = 0, TextStrokeColor3 = COL.dark })
	local function upd()
		countL.Text = tostring(t:GetAttribute("Players") or 0) .. "/" .. tostring(t:GetAttribute("MaxPlayers") or 2)
	end
	t:GetAttributeChangedSignal("Players"):Connect(upd)
	upd()
end
task.spawn(function()
	local map = workspace:WaitForChild("Map", 30)
	local tablesFolder = map and map:WaitForChild("Tables", 30)
	if not tablesFolder then return end
	task.wait(1)
	for _, d in ipairs(tablesFolder:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("MaxPlayers") then task.spawn(setupTableDisplay, d) end
	end
	local hard = map:FindFirstChild("HardMode")
	local door = hard and hard:FindFirstChild("Door")
	if door then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(26, 9); bb.StudsOffset = Vector3.new(0, 16, 0); bb.MaxDistance = 400
		bb.LightInfluence = 0; bb.Adornee = door; bb.Parent = gui
		local a = text(bb, { Size = UDim2.fromScale(1, 0.55), TextScaled = true, TextColor3 = COL.pink, TextStrokeTransparency = 0, TextStrokeColor3 = COL.dark })
		setPixel(a, T("hardMode"))
		local b = text(bb, { Position = UDim2.fromScale(0, 0.6), Size = UDim2.fromScale(1, 0.38), TextScaled = true, TextColor3 = COL.gold, TextStrokeTransparency = 0, TextStrokeColor3 = COL.dark })
		setPixel(b, C.HARD_REQUIRED_WINS .. " " .. T("wins"))
	end
end)

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()
