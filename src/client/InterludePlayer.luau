-- Plays random funny image + sound interludes between quiz questions.
-- Memes fly onto the screen with animated effects, hold, then fly out.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InterludePlayer = {}

local INTERLUDES = {
	{ imageId = "rbxassetid://8073107221", soundId = "rbxassetid://140055886382926" }, -- Slot 1
	{ imageId = "rbxassetid://10180536577", soundId = "rbxassetid://139929135560595" }, -- Slot 2
	{ imageId = "rbxassetid://10180628683", soundId = "rbxassetid://80869811224748" }, -- Slot 3
	{ imageId = "rbxassetid://12053823591", soundId = "rbxassetid://97396403875140" }, -- Slot 4
}

local DISPLAY_DURATION = 2.5

-- Track which interludes have been shown this quiz session
local shownThisSession: { [number]: boolean } = {}

function InterludePlayer.resetSession()
	table.clear(shownThisSession)
end

-- Entrance animations — each function moves the image to its start position,
-- then tweens it to center. Returns the tween so we can wait on it.
local function enterFromLeft(image: ImageLabel)
	image.Position = UDim2.new(-0.5, 0, 0.2, 0)
	image.Rotation = -15
	local tween = TweenService:Create(image, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.25, 0, 0.2, 0),
		Rotation = 3,
	})
	tween:Play()
	return tween
end

local function enterFromRight(image: ImageLabel)
	image.Position = UDim2.new(1.5, 0, 0.2, 0)
	image.Rotation = 15
	local tween = TweenService:Create(image, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.25, 0, 0.2, 0),
		Rotation = -3,
	})
	tween:Play()
	return tween
end

local function enterFromTop(image: ImageLabel)
	image.Position = UDim2.new(0.25, 0, -0.6, 0)
	image.Rotation = 0
	local tween = TweenService:Create(image, TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.25, 0, 0.2, 0),
	})
	tween:Play()
	return tween
end

local function enterFromBottom(image: ImageLabel)
	image.Position = UDim2.new(0.25, 0, 1.5, 0)
	image.Rotation = 0
	local tween = TweenService:Create(image, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.25, 0, 0.2, 0),
	})
	tween:Play()
	return tween
end

local function enterZoomSpin(image: ImageLabel)
	image.Position = UDim2.new(0.25, 0, 0.2, 0)
	image.Size = UDim2.new(0.01, 0, 0.01, 0)
	image.Rotation = 180
	image.AnchorPoint = Vector2.new(0, 0)
	local tween = TweenService:Create(image, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.5, 0, 0.55, 0),
		Rotation = 0,
	})
	tween:Play()
	return tween
end

local ENTRANCE_ANIMATIONS = { enterFromLeft, enterFromRight, enterFromTop, enterFromBottom, enterZoomSpin }

-- Exit animation — fly out and fade
local function exitAnimation(image: ImageLabel, overlay: Frame): Tween
	local exitStyle = math.random(1, 3)
	local tween
	if exitStyle == 1 then
		-- Fly off to the right with spin
		tween = TweenService:Create(image, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(1.5, 0, 0.1, 0),
			Rotation = 20,
		})
	elseif exitStyle == 2 then
		-- Shrink and fade
		tween = TweenService:Create(image, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0.01, 0, 0.01, 0),
			ImageTransparency = 1,
		})
	else
		-- Drop down
		tween = TweenService:Create(image, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.25, 0, 1.5, 0),
			Rotation = -10,
		})
	end

	-- Also fade the overlay
	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 1,
	}):Play()

	tween:Play()
	return tween
end

function InterludePlayer.play(screenGui: ScreenGui, onComplete: () -> ())
	-- Build list of unshown interludes
	local available: { number } = {}
	for i = 1, #INTERLUDES do
		if not shownThisSession[i] then
			table.insert(available, i)
		end
	end

	-- If all have been shown, skip the interlude
	if #available == 0 then
		onComplete()
		return
	end

	local chosenIndex = available[math.random(1, #available)]
	shownThisSession[chosenIndex] = true
	local interlude = INTERLUDES[chosenIndex]

	-- Dark overlay — fades in
	local overlay = Instance.new("Frame")
	overlay.Name = "InterludeOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 20
	overlay.Parent = screenGui

	TweenService:Create(overlay, TweenInfo.new(0.15), {
		BackgroundTransparency = 0,
	}):Play()

	-- Image
	local image = Instance.new("ImageLabel")
	image.Name = "MemeImage"
	image.Size = UDim2.new(0.5, 0, 0.55, 0)
	image.BackgroundTransparency = 1
	image.Image = interlude.imageId
	image.ScaleType = Enum.ScaleType.Fit
	image.ZIndex = 21
	image.Parent = overlay


	-- Pick a random entrance animation
	local animFunc = ENTRANCE_ANIMATIONS[math.random(1, #ENTRANCE_ANIMATIONS)]
	local entranceTween = animFunc(image)

	-- Play sound (preload then play, respect SFX volume)
	local sfxFlag = ReplicatedStorage:FindFirstChild("SFXVolume")
	local sfxVolume = if sfxFlag then sfxFlag.Value else 0.8

	local sound = Instance.new("Sound")
	sound.SoundId = interlude.soundId
	sound.Volume = sfxVolume
	sound.Parent = SoundService

	-- Wait for the sound to load, then play
	if not sound.IsLoaded then
		sound.Loaded:Wait()
	end
	sound:Play()

	-- Clean up sound when it finishes (not when overlay closes)
	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	-- Subtle shake while displayed
	task.spawn(function()
		entranceTween.Completed:Wait()
		local shakeStart = tick()
		while image and image.Parent and (tick() - shakeStart) < DISPLAY_DURATION do
			local offsetX = math.random(-2, 2)
			local offsetY = math.random(-1, 1)
			local basePos = image.Position
			TweenService:Create(image, TweenInfo.new(0.08), {
				Position = UDim2.new(basePos.X.Scale, offsetX, basePos.Y.Scale, offsetY),
			}):Play()
			task.wait(0.1)
		end
	end)

	-- Hold, then exit
	task.delay(DISPLAY_DURATION, function()
		local exit = exitAnimation(image, overlay)
		exit.Completed:Wait()
		overlay:Destroy()
		onComplete()
	end)
end

return InterludePlayer
