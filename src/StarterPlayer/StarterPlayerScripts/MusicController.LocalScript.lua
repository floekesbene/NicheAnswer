-- Hintergrundmusik: Playlist mit Überblendung, Mute-Button, (temporärer) Skip-Button
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local FADE_OUT = 3     -- Sekunden leiser werden am Songende
local FADE_IN = 3      -- Sekunden lauter werden am Songanfang
local SKIP_FADE = 1    -- schnellere Blende beim Skippen
local PAUSE = 0.5      -- kurze Stille zwischen den Songs

local group = SoundService:WaitForChild("MusicGroup")
local folder = SoundService:WaitForChild("Playlist")

local songs = folder:GetChildren()
table.sort(songs, function(a, b)
	return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
end)
for _, s in ipairs(songs) do s.Volume = 0; s.Looped = false end

local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainUI")
local side = gui:WaitForChild("SideButtons")
local musicButton = side:WaitForChild("MusicButton")
local skipButton = side:FindFirstChild("SkipButton")

local muted = false
local skipRequested = false

local function tweenVolume(obj, to, t)
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Volume = to})
	tw:Play()
	return tw
end

-- Mute / Unmute (über die SoundGroup, damit es sich nicht mit den Blenden beißt)
local normalColor = musicButton.BackgroundColor3
local mutedColor = Color3.fromRGB(140, 140, 150)
local function updateMusicButton()
	musicButton.Icon.Text = muted and "🔇" or "🎵"
	musicButton.BackgroundColor3 = muted and mutedColor or normalColor
end
musicButton.Activated:Connect(function()
	muted = not muted
	tweenVolume(group, muted and 0 or 1, 0.4)
	updateMusicButton()
end)
updateMusicButton()

if skipButton then
	skipButton.Activated:Connect(function() skipRequested = true end)
end

local function waitLoaded(s)
	local t0 = os.clock()
	while not s.IsLoaded and os.clock() - t0 < 10 do task.wait(0.1) end
	return s.IsLoaded and s.TimeLength > 0
end

local function playSong(s)
	local target = s:GetAttribute("BaseVolume") or 0.5
	skipRequested = false
	s.TimePosition = 0
	s.Volume = 0
	s:Play()
	tweenVolume(s, target, FADE_IN)

	while s.IsPlaying and not skipRequested and (s.TimeLength - s.TimePosition) > FADE_OUT do
		task.wait(0.1)
	end

	local fade = skipRequested and SKIP_FADE or FADE_OUT
	skipRequested = false
	tweenVolume(s, 0, fade).Completed:Wait()
	s:Stop()
end

local index = 1
while #songs > 0 do
	local s = songs[index]
	if waitLoaded(s) then
		playSong(s)
	else
		warn("[Music] Song konnte nicht geladen werden: " .. s.Name .. " (" .. s.SoundId .. ")")
	end
	index = index % #songs + 1
	task.wait(PAUSE)
end
