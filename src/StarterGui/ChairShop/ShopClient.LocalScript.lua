-- Stuhl-Shop UI (Objekte liegen im Studio unter StarterGui.ChairShop, hier nur die Logik)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Nische = RS:WaitForChild("Nische")
local Shared = require(Nische:WaitForChild("Shared"))
local Skins = require(Nische:WaitForChild("ChairSkins"))
local ShopAction = Nische:WaitForChild("Remotes"):WaitForChild("ShopAction")
local lang = Shared.langOf(player)
local de = lang == "de"

local gui = script.Parent
local panel = gui:WaitForChild("Panel")
local scroll = panel:WaitForChild("Scroll")
local template = panel:WaitForChild("CardTemplate")
local chairsButton = player:WaitForChild("PlayerGui"):WaitForChild("MainUI"):WaitForChild("SideButtons"):WaitForChild("ChairsButton")

panel.Title.Text = de and "🪑 Stuhl-Skins" or "🪑 Chair Skins"

-- Skalierung
local function updateScale()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1200, 800)
	panel.Scale.Scale = math.clamp(math.min(vp.X / 820, vp.Y / 560), 0.5, 1)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

-- 3D-Vorschau: echtes Skin-Modell (oder einfacher Stuhl für "Klassik")
local Builders = require(Nische:WaitForChild("ChairBuilders"))
local function buildPreview(vp, skin)
	if skin.build then
		Builders.build(skin.build, CFrame.new(), vp)
	else
		local function part(size, pos, color)
			local p = Instance.new("Part")
			p.Size, p.Position, p.Color, p.Anchored = size, pos, color, true
			p.Material = Enum.Material[skin.material]
			p.Parent = vp
		end
		part(Vector3.new(2.4, 0.5, 2.4), Vector3.new(0, 0, 0), skin.seat)
		part(Vector3.new(2.4, 2.6, 0.4), Vector3.new(0, 1.55, -1), skin.back)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part(Vector3.new(0.4, 1.8, 0.4), Vector3.new(sx, -1.15, sz), skin.legs)
			end
		end
	end
	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	local far = skin.build and 1 or 0.35
	cam.CFrame = CFrame.lookAt(Vector3.new(7, 7.5, 19) * far + Vector3.new(0, 0, 0), Vector3.new(0, 3.8, -1) * (skin.build and 1 or 0.3))
	cam.Parent = vp
	vp.CurrentCamera = cam
end

local buttons = {}
for i, skin in ipairs(Skins.list) do
	local card = template:Clone()
	card.Name = "Card_" .. skin.id
	card.LayoutOrder = i
	card.Visible = true
	card.SkinName.Text = skin[lang]
	card.Stars.Text = string.rep("★", skin.tier) .. string.rep("☆", 6 - skin.tier)
	card.Effects.Text = skin.fxText[lang]
	buildPreview(card.Preview, skin)
	card.Action.Activated:Connect(function()
		local owned = Skins.parseOwned(player:GetAttribute("Owned"))
		ShopAction:FireServer(owned[skin.id] and "equip" or "buy", skin.id)
	end)
	card.Parent = scroll
	buttons[skin.id] = card.Action
end

local function refresh()
	local c = player:GetAttribute("Coins") or 0
	panel.Coins.Text = "🪙 " .. c
	local owned = Skins.parseOwned(player:GetAttribute("Owned"))
	local equipped = player:GetAttribute("Chair") or "default"
	for _, skin in ipairs(Skins.list) do
		local b = buttons[skin.id]
		if equipped == skin.id then
			b.Text = de and "✓ Ausgerüstet" or "✓ Equipped"
			b.BackgroundColor3 = Color3.fromRGB(110, 120, 160)
		elseif owned[skin.id] then
			b.Text = de and "Ausrüsten" or "Equip"
			b.BackgroundColor3 = Color3.fromRGB(70, 140, 235)
		else
			b.Text = "🪙 " .. skin.price
			b.BackgroundColor3 = c >= skin.price and Color3.fromRGB(80, 200, 70) or Color3.fromRGB(150, 90, 90)
		end
	end
end
for _, a in ipairs({ "Coins", "Owned", "Chair" }) do player:GetAttributeChangedSignal(a):Connect(refresh) end
refresh()

-- Öffnen / Schließen
chairsButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then refresh() end
end)
panel.Close.Activated:Connect(function() panel.Visible = false end)

-- im Match/Solo schließen (NischeClient setzt das Attribut)
task.spawn(function()
	local main = player.PlayerGui:WaitForChild("NischeUI")
	main:GetAttributeChangedSignal("InGame"):Connect(function()
		if main:GetAttribute("InGame") then panel.Visible = false end
	end)
end)
