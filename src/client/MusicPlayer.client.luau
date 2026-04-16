local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PLAYLIST = {
	{ id = "rbxassetid://139980792764947", name = "Track 1" },
	{ id = "rbxassetid://98059622986262", name = "Track 2" },
	{ id = "rbxassetid://104784657242827", name = "Track 3" },
	{ id = "rbxassetid://123472922752577", name = "Track 4" },
	{ id = "rbxassetid://87744289969843", name = "Track 5" },
}

local DEFAULT_VOLUME = 0.3

-- State
local currentOrder: { number } = {}
local currentIndex: number = 1
local isPaused: boolean = false
local isMinimized: boolean = false
local skipRequested: boolean = false
local slideDragging: boolean = false

-- Sound instance
local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.Volume = DEFAULT_VOLUME
music.Parent = SoundService

-- Shuffle helper
local function shuffle(count: number): { number }
	local indices = {}
	for i = 1, count do
		table.insert(indices, i)
	end
	for i = #indices, 2, -1 do
		local j = math.random(1, i)
		indices[i], indices[j] = indices[j], indices[i]
	end
	return indices
end

-- ============================================================
-- UI
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MusicPlayerUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- Mini button (shown when minimized)
local miniButton = Instance.new("TextButton")
miniButton.Name = "MiniButton"
miniButton.Size = UDim2.new(0, 36, 0, 36)
miniButton.Position = UDim2.new(0, 10, 1, -46)
miniButton.BackgroundColor3 = Color3.fromRGB(25, 22, 50)
miniButton.Text = "♪"
miniButton.TextColor3 = Color3.fromRGB(255, 200, 50)
miniButton.TextScaled = true
miniButton.Font = Enum.Font.GothamBold
miniButton.ZIndex = 50
miniButton.Visible = false
miniButton.Parent = screenGui

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 10)
miniCorner.Parent = miniButton

local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(255, 200, 50)
miniStroke.Thickness = 1
miniStroke.Transparency = 0.5
miniStroke.Parent = miniButton

-- Main panel
local panel = Instance.new("Frame")
panel.Name = "MusicPanel"
panel.Size = UDim2.new(0, 240, 0, 170)
panel.Position = UDim2.new(0, 10, 1, -180)
panel.BackgroundColor3 = Color3.fromRGB(14, 12, 32)
panel.BorderSizePixel = 0
panel.ZIndex = 50
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(60, 50, 100)
panelStroke.Thickness = 1
panelStroke.Parent = panel

-- ============================================================
-- Dragging (only from the title bar)
-- ============================================================
local dragging = false
local dragStart: Vector3? = nil
local startPos: UDim2? = nil

-- Drag is set up later after titleBar is created (see below)

-- ============================================================
-- Title bar
-- ============================================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 18, 42)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 51
titleBar.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

-- Fill the bottom corners of title bar
local titleFill = Instance.new("Frame")
titleFill.Size = UDim2.new(1, 0, 0, 14)
titleFill.Position = UDim2.new(0, 0, 1, -14)
titleFill.BackgroundColor3 = Color3.fromRGB(20, 18, 42)
titleFill.BorderSizePixel = 0
titleFill.ZIndex = 51
titleFill.Parent = titleBar

-- Attach drag to title bar
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = panel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and not slideDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		if dragStart and startPos then
			local delta = input.Position - dragStart
			panel.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 80, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "♪ MUSIC"
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 52
titleLabel.Parent = titleBar

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -60, 0, 2)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 45, 80)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 210)
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.ZIndex = 52
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 52
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- ============================================================
-- Content area
-- ============================================================

-- Song name
local songLabel = Instance.new("TextLabel")
songLabel.Name = "SongLabel"
songLabel.Size = UDim2.new(1, -20, 0, 22)
songLabel.Position = UDim2.new(0, 10, 0, 36)
songLabel.BackgroundTransparency = 1
songLabel.Text = "Loading..."
songLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
songLabel.TextScaled = true
songLabel.Font = Enum.Font.GothamBold
songLabel.TextXAlignment = Enum.TextXAlignment.Left
songLabel.TextTruncate = Enum.TextTruncate.AtEnd
songLabel.ZIndex = 51
songLabel.Parent = panel

-- Song progress bar
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, -20, 0, 4)
progressBg.Position = UDim2.new(0, 10, 0, 62)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
progressBg.BorderSizePixel = 0
progressBg.ZIndex = 51
progressBg.Parent = panel

local progCorner = Instance.new("UICorner")
progCorner.CornerRadius = UDim.new(1, 0)
progCorner.Parent = progressBg

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
progressFill.BorderSizePixel = 0
progressFill.ZIndex = 52
progressFill.Parent = progressBg

local progFillCorner = Instance.new("UICorner")
progFillCorner.CornerRadius = UDim.new(1, 0)
progFillCorner.Parent = progressFill

-- ============================================================
-- Playback controls (Prev | Play/Pause | Next)
-- ============================================================
local controlsFrame = Instance.new("Frame")
controlsFrame.Size = UDim2.new(0, 140, 0, 34)
controlsFrame.Position = UDim2.new(0.5, -70, 0, 72)
controlsFrame.BackgroundTransparency = 1
controlsFrame.ZIndex = 51
controlsFrame.Parent = panel

local function makeControlButton(name: string, text: string, xOffset: number, width: number?): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, width or 34, 0, 34)
	btn.Position = UDim2.new(0, xOffset, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(30, 27, 55)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(220, 220, 240)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 52
	btn.Parent = controlsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	return btn
end

local prevBtn = makeControlButton("Prev", "⏮", 0)
local playPauseBtn = makeControlButton("PlayPause", "⏸", 42, 56)
local nextBtn = makeControlButton("Next", "⏭", 106)

-- ============================================================
-- Volume slider
-- ============================================================
local volumeFrame = Instance.new("Frame")
volumeFrame.Size = UDim2.new(1, -20, 0, 30)
volumeFrame.Position = UDim2.new(0, 10, 0, 115)
volumeFrame.BackgroundTransparency = 1
volumeFrame.ZIndex = 51
volumeFrame.Parent = panel

local volLabel = Instance.new("TextLabel")
volLabel.Size = UDim2.new(0, 20, 1, 0)
volLabel.Position = UDim2.new(0, 0, 0, 0)
volLabel.BackgroundTransparency = 1
volLabel.Text = "🔊"
volLabel.TextScaled = true
volLabel.ZIndex = 52
volLabel.Parent = volumeFrame

local sliderBg = Instance.new("Frame")
sliderBg.Name = "SliderBg"
sliderBg.Size = UDim2.new(1, -55, 0, 6)
sliderBg.Position = UDim2.new(0, 28, 0.5, -3)
sliderBg.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
sliderBg.BorderSizePixel = 0
sliderBg.ZIndex = 52
sliderBg.Parent = volumeFrame

local sliderBgCorner = Instance.new("UICorner")
sliderBgCorner.CornerRadius = UDim.new(1, 0)
sliderBgCorner.Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(DEFAULT_VOLUME, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
sliderFill.BorderSizePixel = 0
sliderFill.ZIndex = 53
sliderFill.Parent = sliderBg

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

local sliderKnob = Instance.new("Frame")
sliderKnob.Name = "Knob"
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.Position = UDim2.new(DEFAULT_VOLUME, -7, 0.5, -7)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.ZIndex = 54
sliderKnob.Parent = sliderBg

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = sliderKnob

local volPercent = Instance.new("TextLabel")
volPercent.Name = "VolPercent"
volPercent.Size = UDim2.new(0, 30, 1, 0)
volPercent.Position = UDim2.new(1, -25, 0, 0)
volPercent.BackgroundTransparency = 1
volPercent.Text = tostring(math.floor(DEFAULT_VOLUME * 100)) .. "%"
volPercent.TextColor3 = Color3.fromRGB(140, 140, 170)
volPercent.TextScaled = true
volPercent.Font = Enum.Font.Gotham
volPercent.ZIndex = 52
volPercent.Parent = volumeFrame

-- Volume slider interaction
local function updateVolume(input: InputObject)
	local sliderAbsPos = sliderBg.AbsolutePosition.X
	local sliderAbsSize = sliderBg.AbsoluteSize.X
	local relativeX = math.clamp((input.Position.X - sliderAbsPos) / sliderAbsSize, 0, 1)

	music.Volume = relativeX
	sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
	sliderKnob.Position = UDim2.new(relativeX, -7, 0.5, -7)
	volPercent.Text = tostring(math.floor(relativeX * 100)) .. "%"
end

sliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		slideDragging = true
		updateVolume(input)
	end
end)

sliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		slideDragging = true
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if slideDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateVolume(input)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		slideDragging = false
	end
end)

-- ============================================================
-- Button handlers
-- ============================================================

-- Minimize / restore
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = true
	panel.Visible = false
	miniButton.Visible = true
end)

miniButton.MouseButton1Click:Connect(function()
	isMinimized = false
	panel.Visible = true
	miniButton.Visible = false
end)

-- Close (hide everything, music keeps playing)
closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
	miniButton.Visible = true
	isMinimized = true
end)

-- Play / Pause
playPauseBtn.MouseButton1Click:Connect(function()
	if isPaused then
		music:Resume()
		isPaused = false
		playPauseBtn.Text = "⏸"
	else
		music:Pause()
		isPaused = true
		playPauseBtn.Text = "▶"
	end
end)

-- Skip next
nextBtn.MouseButton1Click:Connect(function()
	currentIndex += 1
	if currentIndex > #currentOrder then
		currentIndex = 1
	end
	playTrack(currentIndex)
end)

-- Skip prev (restart current, or go back if near start)
prevBtn.MouseButton1Click:Connect(function()
	if music.TimePosition > 3 then
		music.TimePosition = 0
	else
		currentIndex -= 1
		if currentIndex < 1 then
			currentIndex = #currentOrder
		end
		playTrack(currentIndex)
	end
end)

-- ============================================================
-- Update song name and progress bar
-- ============================================================
local function updateSongDisplay(trackIndex: number)
	local track = PLAYLIST[currentOrder[trackIndex]]
	songLabel.Text = "♪ " .. track.name .. "  (" .. trackIndex .. "/" .. #PLAYLIST .. ")"
end

-- Progress bar updater
task.spawn(function()
	while true do
		if music.IsPlaying and music.TimeLength > 0 then
			local pct = music.TimePosition / music.TimeLength
			progressFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
		end
		task.wait(0.1)
	end
end)

-- ============================================================
-- Fetch song names from MarketplaceService
-- ============================================================
task.spawn(function()
	for i, track in PLAYLIST do
		local assetId = tonumber(track.id:match("%d+"))
		if assetId then
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfo(assetId)
			end)
			if success and info and info.Name then
				track.name = info.Name
			end
		end
	end
end)

-- ============================================================
-- Playback
-- ============================================================
currentOrder = shuffle(#PLAYLIST)
currentIndex = 1

function playTrack(index: number)
	local track = PLAYLIST[currentOrder[index]]
	music:Stop()
	music.SoundId = track.id
	music:Play()
	isPaused = false
	playPauseBtn.Text = "⏸"
	updateSongDisplay(index)
end

-- Auto-advance when a song ends naturally
music.Ended:Connect(function()
	-- Small delay to avoid race with skip buttons
	task.wait(0.1)
	-- Only auto-advance if the song actually finished (not manually skipped)
	if not music.IsPlaying then
		currentIndex += 1
		if currentIndex > #currentOrder then
			currentIndex = 1
		end
		playTrack(currentIndex)
	end
end)

-- Start first track
playTrack(currentIndex)
