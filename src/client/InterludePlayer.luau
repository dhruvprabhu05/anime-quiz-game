-- Plays random funny image + sound interludes between quiz questions.
--
-- IMPORTANT: You must upload images and sounds to Roblox and paste their asset IDs below.
-- Each entry needs:
--   imageId: "rbxassetid://XXXXXXXXXX" (upload an image as a Decal in Roblox Studio)
--   soundId: "rbxassetid://XXXXXXXXXX" (upload a sound via Creator Dashboard)

local SoundService = game:GetService("SoundService")

local InterludePlayer = {}

-- Replace "rbxassetid://0" with real asset IDs after uploading to Roblox
local INTERLUDES = {
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 1
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 2
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 3
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 4
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 5
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 6
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 7
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 8
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 9
	{ imageId = "rbxassetid://0", soundId = "rbxassetid://0" }, -- Slot 10
}

local DISPLAY_DURATION = 2.5 -- seconds

function InterludePlayer.play(screenGui: ScreenGui, onComplete: () -> ())
	local interlude = INTERLUDES[math.random(1, #INTERLUDES)]

	-- Create overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "InterludeOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.ZIndex = 20
	overlay.Parent = screenGui

	-- Image in center
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(0.4, 0, 0.5, 0)
	image.Position = UDim2.new(0.3, 0, 0.25, 0)
	image.BackgroundTransparency = 1
	image.Image = interlude.imageId
	image.ScaleType = Enum.ScaleType.Fit
	image.ZIndex = 21
	image.Parent = overlay

	-- Play sound
	local sound = Instance.new("Sound")
	sound.SoundId = interlude.soundId
	sound.Volume = 0.8
	sound.Parent = SoundService
	sound:Play()

	-- Auto-dismiss after duration
	task.delay(DISPLAY_DURATION, function()
		overlay:Destroy()
		sound:Destroy()
		onComplete()
	end)
end

return InterludePlayer
