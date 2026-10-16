-- Dims the screen, flies a meme image in from a random side with its sound, holds it,
-- drops it out, then calls onDone. Never waits on the sound, so a sound that fails to
-- load can't stall the quiz.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)
local Interludes = require(script.Parent.Interludes)
local AudioSettings = require(script.Parent.Parent.Parent.Audio.AudioSettings)

local e = React.createElement

local HOLD_SECONDS = 2.5
local MAX_SOUND_SECONDS = 10 -- sounds are cleaned up after this even if they never end
local IMAGE_SIZE = UDim2.fromScale(0.5, 0.55)
local CENTER = UDim2.fromScale(0.5, 0.5)
local EXIT_POSITION = UDim2.fromScale(0.5, 1.6)
local EXIT_ROTATION = -10
local DIM_IN = TweenInfo.new(0.15)
local ENTER = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EXIT = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- Where the image starts before flying to the center
local ENTRANCES = table.freeze({
	{ position = UDim2.fromScale(-0.5, 0.5), rotation = -15 }, -- from the left
	{ position = UDim2.fromScale(1.5, 0.5), rotation = 15 }, -- from the right
	{ position = UDim2.fromScale(0.5, -0.6), rotation = 0 }, -- from the top
	{ position = UDim2.fromScale(0.5, 1.6), rotation = 0 }, -- from the bottom
})

export type Props = {
	interludeIndex: number,
	onDone: () -> (),
}

local function playSound(soundId: string)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = AudioSettings.get("sfx")
	sound.Parent = SoundService
	sound:Play() -- starts once loaded; never blocks
	Debris:AddItem(sound, MAX_SOUND_SECONDS)
end

local function InterludeOverlay(props: Props)
	local interlude = Interludes.list[props.interludeIndex]
	local entrance = React.useMemo(function()
		return ENTRANCES[math.random(1, #ENTRANCES)]
	end, {})
	local imageRef = React.useRef(nil)
	local dimRef = React.useRef(nil)
	local onDoneRef = React.useRef(props.onDone)
	onDoneRef.current = props.onDone

	React.useEffect(function()
		local image, dim = imageRef.current, dimRef.current
		TweenService:Create(dim, DIM_IN, { BackgroundTransparency = Theme.Transparency.overlay }):Play()
		TweenService:Create(image, ENTER, { Position = CENTER, Rotation = 0 }):Play()
		playSound(interlude.soundId)

		local exitThread = task.delay(HOLD_SECONDS, function()
			TweenService:Create(dim, EXIT, { BackgroundTransparency = 1 }):Play()
			local exit = TweenService:Create(image, EXIT, { Position = EXIT_POSITION, Rotation = EXIT_ROTATION })
			exit:Play()
			exit.Completed:Wait()
			onDoneRef.current()
		end)
		return function()
			task.cancel(exitThread)
		end
	end, {})

	return e("Frame", {
		ref = dimRef,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.overlay,
		BackgroundTransparency = 1,
		Active = true, -- blocks taps on the quiz underneath
	}, {
		Image = e("ImageLabel", {
			ref = imageRef,
			Image = interlude.imageId,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = entrance.position,
			Rotation = entrance.rotation,
			Size = IMAGE_SIZE,
			BackgroundTransparency = 1,
		}),
	})
end

return InterludeOverlay
