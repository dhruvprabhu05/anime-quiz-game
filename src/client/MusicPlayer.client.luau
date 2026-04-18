local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYLIST = {
	"rbxassetid://139980792764947",
	"rbxassetid://98059622986262",
	"rbxassetid://104784657242827",
	"rbxassetid://123472922752577",
	"rbxassetid://87744289969843",
}

local DEFAULT_VOLUME = 0.3

-- Sound instance
local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.Volume = DEFAULT_VOLUME
music.Parent = SoundService

-- Shuffle helper
local function shuffle(list)
	local shuffled = table.clone(list)
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

-- Store volume setting so SettingsUI can control it
local volumeValue = Instance.new("NumberValue")
volumeValue.Name = "MusicVolume"
volumeValue.Value = DEFAULT_VOLUME
volumeValue.Parent = ReplicatedStorage

volumeValue:GetPropertyChangedSignal("Value"):Connect(function()
	music.Volume = volumeValue.Value
end)

-- Playback
local currentOrder = shuffle(PLAYLIST)
local currentIndex = 1

local function playTrack(index: number)
	music.SoundId = currentOrder[index]
	-- Wait for sound to load before playing
	if not music.IsLoaded then
		music.Loaded:Wait()
	end
	music:Play()
end

music.Ended:Connect(function()
	task.wait(0.2)
	if not music.IsPlaying then
		currentIndex += 1
		if currentIndex > #currentOrder then
			currentIndex = 1
			currentOrder = shuffle(PLAYLIST)
		end
		playTrack(currentIndex)
	end
end)

-- Small delay to let everything initialize
task.wait(1)
playTrack(currentIndex)
