-- Stuhl-Shop: kaufen, ausruesten, Skin auf den Stuhl anwenden auf dem man sitzt
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

local Skins = require(RS.Nische.ChairSkins)
local PlayerData = require(SS.Nische.PlayerData)
local Remotes = RS.Nische.Remotes

local Shop = {}

local function notify(player, key, ...)
	Remotes.Notify:FireClient(player, key, { ... })
end

local function skinName(player, skin)
	return skin[string.sub(string.lower(player.LocaleId or "en"), 1, 2) == "de" and "de" or "en"]
end

---------------------------------------------------------------- Skin auf Stuhl
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Builders = require(RS.Nische.ChairBuilders)

local originals = {}  -- Original-Stuhlteil -> Eigenschaften
local applied = {}    -- seat -> Zustand

local function chairParts(seat)
	local list = { seat }
	for _, p in ipairs(seat.Parent:GetChildren()) do
		if p:IsA("BasePart") and (p.Name == "ChairBack" or p.Name == "ChairLeg") then
			local rel = seat.CFrame:PointToObjectSpace(p.Position)
			if math.abs(rel.X) < 1.7 and math.abs(rel.Z) < 1.9 then list[#list+1] = p end
		end
	end
	return list
end

local function restore(seat)
	local st = applied[seat]
	if not st then return end
	applied[seat] = nil
	for _, t in ipairs(st.tweens) do t:Cancel() end
	if st.model then st.model:Destroy() end
	for _, e in ipairs(st.effects) do e:Destroy() end
	for _, p in ipairs(chairParts(seat)) do
		local o = originals[p]
		if o then p.Color, p.Material, p.Reflectance, p.Transparency = o.Color, o.Material, o.Reflectance, o.Transparency end
	end
end

local function colorSeq(color)
	if color == "rainbow" then
		local pts = {}
		for i = 0, 5 do pts[#pts+1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV(i / 6, 0.8, 1)) end
		return ColorSequence.new(pts)
	end
	return ColorSequence.new(color)
end

local function addEffect(st, main, fx)
	local obj
	if fx.k == "light" then
		obj = Instance.new("PointLight")
		obj.Color, obj.Brightness, obj.Range = fx.color, fx.brightness, fx.range
		obj.Parent = main
		if fx.pulse then
			local tw = TweenService:Create(obj, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Brightness = fx.brightness * 0.35 })
			tw:Play(); st.tweens[#st.tweens+1] = tw
		end
		st.light = st.light or obj
	elseif fx.k == "particles" then
		obj = Instance.new("ParticleEmitter")
		obj.Color = colorSeq(fx.color)
		obj.Rate = fx.rate
		obj.Speed = NumberRange.new(fx.speed * 0.7, fx.speed)
		obj.Lifetime = NumberRange.new(fx.life * 0.7, fx.life)
		obj.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, fx.size), NumberSequenceKeypoint.new(1, 0) })
		obj.Transparency = NumberSequence.new(fx.transparencyStart or 0, fx.transparencyEnd or 1)
		obj.SpreadAngle = Vector2.new(fx.spread or 30, fx.spread or 30)
		obj.Acceleration = fx.accel or Vector3.zero
		obj.LightEmission = 1
		obj.Rotation = NumberRange.new(0, 360)
		obj.RotSpeed = NumberRange.new(-90, 90)
		if fx.shape == "Disc" then
			obj.Shape = Enum.ParticleEmitterShape.Disc
			obj.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			obj.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		end
		obj.Parent = main
	elseif fx.k == "fire" then
		obj = Instance.new("Fire")
		obj.Color, obj.SecondaryColor, obj.Size, obj.Heat = fx.color, fx.secondary, fx.size, fx.heat
		obj.Parent = main
	elseif fx.k == "sparkles" then
		obj = Instance.new("Sparkles")
		obj.SparkleColor = fx.color
		obj.Parent = main
	elseif fx.k == "rainbow" then
		st.rainbow = true
	end
	if obj then st.effects[#st.effects+1] = obj end
end

local function apply(seat, skin)
	restore(seat)
	if not skin or skin.id == "default" or not skin.build then return end
	local st = { effects = {}, tweens = {}, spinners = {}, rbParts = {}, rainbow = false }
	applied[seat] = st

	local back
	for _, p in ipairs(chairParts(seat)) do
		if not originals[p] then
			originals[p] = { Color = p.Color, Material = p.Material, Reflectance = p.Reflectance, Transparency = p.Transparency }
		end
		if p.Name == "ChairBack" then back = p end
		p.Transparency = 1 -- originalen Stuhl verstecken, das Skin-Modell ersetzt ihn
	end

	-- Stuhl-Raum: Rücken soll bei -Z liegen
	local F = seat.CFrame
	if back and seat.CFrame:PointToObjectSpace(back.Position).Z > 0 then F = F * CFrame.Angles(0, math.pi, 0) end

	local model = Instance.new("Model")
	model.Name = "ChairSkin"
	local ctx = Builders.build(skin.build, F, model)
	model.Parent = workspace
	st.model, st.spinners, st.rbParts = model, ctx.spinners, ctx.rainbow
	for _, fx in ipairs(skin.fx or {}) do addEffect(st, ctx.main, fx) end
end

-- Drehende Teile & Regenbogen animieren
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then return end
	acc = 0
	local t = os.clock()
	for _, st in pairs(applied) do
		for _, sp in ipairs(st.spinners) do
			local a = t * sp.speed
			local r = (sp.axis == "X" and CFrame.Angles(a, 0, 0)) or (sp.axis == "Y" and CFrame.Angles(0, a, 0)) or CFrame.Angles(0, 0, a)
			sp.part.CFrame = sp.pivot * r * sp.rel
		end
		if st.rainbow then
			local hue = (t * 0.25) % 1
			for i, p in ipairs(st.rbParts) do p.Color = Color3.fromHSV((hue + i * 0.07) % 1, 0.8, 1) end
			if st.light then st.light.Color = Color3.fromHSV(hue, 0.4, 1) end
		end
	end
end)

local function playerOfSeat(seat)
	local hum = seat.Occupant
	return hum and Players:GetPlayerFromCharacter(hum.Parent)
end

local function refreshSeat(seat)
	local p = playerOfSeat(seat)
	if p then
		apply(seat, Skins.byId[PlayerData.get(p, "Chair") or "default"])
	else
		restore(seat)
	end
end

for _, d in ipairs(workspace.Map.Tables:GetDescendants()) do
	if d:IsA("Seat") then
		d:GetPropertyChangedSignal("Occupant"):Connect(function() refreshSeat(d) end)
	end
end

---------------------------------------------------------------- Kaufen / Ausruesten
local function ownedSet(player)
	return Skins.parseOwned(PlayerData.get(player, "Owned"))
end

local function saveOwned(player, set)
	local ids = {}
	for id in pairs(set) do if id ~= "default" then ids[#ids+1] = id end end
	table.sort(ids)
	PlayerData.set(player, "Owned", table.concat(ids, ","))
end

local function equip(player, skin)
	PlayerData.set(player, "Chair", skin.id)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if seat and seat:IsA("Seat") and applied ~= nil and seat:IsDescendantOf(workspace.Map.Tables) then refreshSeat(seat) end
end

local busy = {}
Remotes.ShopAction.OnServerEvent:Connect(function(player, action, id)
	if type(action) ~= "string" or type(id) ~= "string" then return end
	local skin = Skins.byId[id]
	if not skin or busy[player] or not PlayerData.get(player, "Coins") then return end
	busy[player] = true
	local set = ownedSet(player)
	if action == "buy" then
		if set[id] then
			-- schon gekauft -> nur ausruesten
		elseif (PlayerData.get(player, "Coins") or 0) < skin.price then
			notify(player, "shopNoCoins")
			busy[player] = nil
			return
		else
			PlayerData.add(player, "Coins", -skin.price)
			set[id] = true
			saveOwned(player, set)
			notify(player, "shopBought", skinName(player, skin))
		end
		equip(player, skin)
	elseif action == "equip" and set[id] then
		equip(player, skin)
		notify(player, "shopEquipped", skinName(player, skin))
	end
	busy[player] = nil
end)

Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)

return Shop
