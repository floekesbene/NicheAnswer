-- Hauptskript: Spieler, Tische, Quick Play, Solo, Schwerer Modus, Overhead
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")

local Shared = require(RS.Nische.Shared)
local Remotes = RS.Nische.Remotes
local mods = SS.Nische
local PromptBank = require(mods.PromptBank)
local PlayerData = require(mods.PlayerData)
local MatchService = require(mods.MatchService)
local SoloService = require(mods.SoloService)
local Activity = require(mods.Activity)
local C = Shared.Config

print(("[Nische] %d Prompts geladen"):format(PromptBank.count()))

local function notify(player, key, ...)
	Remotes.Notify:FireClient(player, key, { ... })
end

---------------------------------------------------------------- Overhead (IQ + Streak über dem Kopf)
local function buildOverhead(player, character)
	local head = character:WaitForChild("Head", 10)
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "NischeOverhead"; bb.Size = UDim2.fromOffset(190, 40); bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 80; bb.AlwaysOnTop = false; bb.LightInfluence = 0
	local list = Instance.new("UIListLayout"); list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6); list.Parent = bb
	local MONO = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)
	local function pill(name, color)
		local f = Instance.new("TextLabel"); f.Name = name
		f.AutomaticSize = Enum.AutomaticSize.X; f.Size = UDim2.fromOffset(0, 28)
		f.BackgroundColor3 = Color3.fromRGB(14, 24, 44); f.BackgroundTransparency = 0.1
		f.FontFace = MONO; f.TextSize = 17; f.TextColor3 = color
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 9); pad.PaddingRight = UDim.new(0, 9); pad.Parent = f
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
		local st = Instance.new("UIStroke"); st.Thickness = 2; st.Color = color; st.Transparency = 0.2
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = f
		f.Parent = bb
		return f
	end
	pill("IQ", Color3.fromRGB(96, 224, 255))
	pill("Streak", Color3.fromRGB(255, 84, 132))
	bb.Parent = head
end

local function updateOverhead(player)
	local char = player.Character
	local bb = char and char:FindFirstChild("Head") and char.Head:FindFirstChild("NischeOverhead")
	if not bb then return end
	bb.IQ.Text = "🧠 IQ " .. tostring(player:GetAttribute("IQ") or 0)
	local streak = player:GetAttribute("Streak") or 0
	bb.Streak.Text = "🔥 " .. tostring(streak)
	bb.Streak.Visible = streak > 0
end

---------------------------------------------------------------- Schwerer Modus: Tür
local door = workspace.Map.HardMode:FindFirstChild("Door")
pcall(function()
	PhysicsService:RegisterCollisionGroup("HardDoor")
	PhysicsService:RegisterCollisionGroup("HardOK")
	PhysicsService:CollisionGroupSetCollidable("HardDoor", "HardOK", false)
end)
if door then door.CollisionGroup = "HardDoor" end

local function qualifies(player)
	return (player:GetAttribute("Wins") or 0) >= C.HARD_REQUIRED_WINS
end

local function applyDoorAccess(player)
	local char = player.Character
	if not char then return end
	local group = qualifies(player) and "HardOK" or "Default"
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then p.CollisionGroup = group end
	end
end

if door then
	local lastWarn = {}
	door.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and not qualifies(player) and (not lastWarn[player] or os.clock() - lastWarn[player] > 3) then
			lastWarn[player] = os.clock()
			notify(player, "hardLocked", C.HARD_REQUIRED_WINS)
		end
	end)
end

---------------------------------------------------------------- Spieler
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		buildOverhead(player, char)
		updateOverhead(player)
		applyDoorAccess(player)
		char.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") and qualifies(player) then d.CollisionGroup = "HardOK" end
		end)
	end)
	PlayerData.load(player)
	for _, attr in ipairs({ "IQ", "Streak" }) do
		player:GetAttributeChangedSignal(attr):Connect(function() updateOverhead(player) end)
	end
	player:GetAttributeChangedSignal("Wins"):Connect(function() applyDoorAccess(player) end)
	updateOverhead(player)
	applyDoorAccess(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local a = Activity[player]
	if a and a.kind == "match" then MatchService.leave(player, a.session) end
	if a and a.kind == "solo" then a.session.quit = true end
	Activity[player] = nil
	PromptBank.forget(player)
end)

---------------------------------------------------------------- Tische
local tables = {}
for _, d in ipairs(workspace.Map.Tables:GetDescendants()) do
	if d:IsA("Model") and d:GetAttribute("MaxPlayers") then tables[#tables+1] = d end
end

local function seatsOf(t)
	local list = {}
	for _, c in ipairs(t:GetChildren()) do if c:IsA("Seat") then list[#list+1] = c end end
	return list
end

local function seatedPlayers(t)
	local list = {}
	for _, seat in ipairs(seatsOf(t)) do
		local hum = seat.Occupant
		local p = hum and Players:GetPlayerFromCharacter(hum.Parent)
		if p then list[#list+1] = p end
	end
	return list
end

local tryStart

local function setupTable(t)
	t:SetAttribute("State", "Waiting")
	t:SetAttribute("Players", 0)
	local seatOwner = {}

	local function refresh()
		t:SetAttribute("Players", #seatedPlayers(t))
	end

	for _, seat in ipairs(seatsOf(t)) do
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local hum = seat.Occupant
			if hum then
				local p = Players:GetPlayerFromCharacter(hum.Parent)
				if p then
					local a = Activity[p]
					local blocked = nil
					if a then blocked = "busy" end
					if t:GetAttribute("Mode") == "Schwer" and not qualifies(p) then blocked = "hardLocked" end
					if t:GetAttribute("State") == "Playing" then blocked = blocked or "busy" end
					if blocked then
						task.defer(function()
							hum.Sit = false
							local root = hum.Parent:FindFirstChild("HumanoidRootPart")
							if root then root.CFrame = root.CFrame + Vector3.new(0, 3, 0) + seat.CFrame.LookVector * -4 end
						end)
						if blocked == "hardLocked" then notify(p, "hardLocked", C.HARD_REQUIRED_WINS) else notify(p, "busy") end
						return
					end
					seatOwner[seat] = p
				end
			else
				local p = seatOwner[seat]
				seatOwner[seat] = nil
				if p then
					local a = Activity[p]
					if a and a.kind == "match" and a.session.table == t then MatchService.leave(p, a.session) end
				end
			end
			refresh()
			tryStart(t)
		end)
	end
end

tryStart = function(t)
	if t:GetAttribute("State") ~= "Waiting" then return end
	local max = t:GetAttribute("MaxPlayers")
	if #seatedPlayers(t) < max then return end
	t:SetAttribute("State", "Countdown")
	task.spawn(function()
		for i = C.START_COUNTDOWN, 1, -1 do
			local seated = seatedPlayers(t)
			if #seated < max then
				for _, p in ipairs(seated) do Remotes.MatchEvent:FireClient(p, "CountdownCancel", {}) end
				t:SetAttribute("State", "Waiting")
				return
			end
			for _, p in ipairs(seated) do Remotes.MatchEvent:FireClient(p, "Countdown", { n = i }) end
			task.wait(1)
		end
		local seated = seatedPlayers(t)
		if #seated < max then
			for _, p in ipairs(seated) do Remotes.MatchEvent:FireClient(p, "CountdownCancel", {}) end
			t:SetAttribute("State", "Waiting")
			return
		end
		t:SetAttribute("State", "Playing")
		MatchService.start(t, seated, function()
			t:SetAttribute("State", "Cooldown")
			task.wait(6)
			t:SetAttribute("State", "Waiting")
			t:SetAttribute("Players", #seatedPlayers(t))
			tryStart(t) -- wer sitzen bleibt, spielt ein Rematch
		end)
	end)
end

for _, t in ipairs(tables) do setupTable(t) end

---------------------------------------------------------------- Remotes
Remotes.Submit.OnServerEvent:Connect(function(player, text)
	local a = Activity[player]
	if not a then return end
	if a.kind == "match" then MatchService.submit(player, a.session, text)
	elseif a.kind == "solo" then SoloService.submit(player, a.session, text) end
end)

Remotes.SoloAction.OnServerEvent:Connect(function(player, action)
	local a = Activity[player]
	if action == "start" then
		if a then notify(player, "busy") return end
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.SeatPart then notify(player, "busy") return end
		SoloService.start(player)
	elseif a and a.kind == "solo" then
		SoloService.action(player, a.session, action)
	end
end)

Remotes.QuickPlay.OnServerEvent:Connect(function(player)
	if Activity[player] then notify(player, "busy") return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return end
	if hum.SeatPart then return end
	-- bevorzugt: Tisch, an dem schon jemand wartet
	local waiting, empty = {}, {}
	for _, t in ipairs(tables) do
		if t:GetAttribute("Mode") == "Normal" and t:GetAttribute("State") == "Waiting" then
			local n = #seatedPlayers(t)
			if n > 0 and n < t:GetAttribute("MaxPlayers") then waiting[#waiting+1] = t
			elseif n == 0 then empty[#empty+1] = t end
		end
	end
	local pool = (#waiting > 0) and waiting or empty
	if #pool == 0 then notify(player, "noTable") return end
	local t = pool[math.random(1, #pool)]
	for _, seat in ipairs(seatsOf(t)) do
		if not seat.Occupant then
			root.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
			task.wait(0.15)
			seat:Sit(hum)
			return
		end
	end
end)

require(mods.ShopService)
