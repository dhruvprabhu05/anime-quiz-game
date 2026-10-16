--!strict
-- Loops the background playlist in a shuffled order, following the music volume setting.

local SoundService = game:GetService("SoundService")

local AudioSettings = require(script.Parent:WaitForChild("AudioSettings"))

local PLAYLIST = table.freeze({
	"rbxassetid://139980792764947",
	"rbxassetid://98059622986262",
	"rbxassetid://104784657242827",
	"rbxassetid://123472922752577",
	"rbxassetid://87744289969843",
})

local MusicPlayer = {}

local function shuffled(list: { string }): { string }
	local result = table.clone(list)
	for i = #result, 2, -1 do
		local j = math.random(1, i)
		result[i], result[j] = result[j], result[i]
	end
	return result
end

function MusicPlayer.start()
	local music = Instance.new("Sound")
	music.Name = "BackgroundMusic"
	music.Volume = AudioSettings.get("music")
	music.Parent = SoundService

	local order = shuffled(PLAYLIST)
	local trackIndex = 1

	local function playCurrent()
		music.SoundId = order[trackIndex]
		music:Play() -- plays as soon as the track has loaded
	end

	music.Ended:Connect(function()
		trackIndex += 1
		if trackIndex > #order then
			order = shuffled(PLAYLIST)
			trackIndex = 1
		end
		playCurrent()
	end)

	AudioSettings.changed:Connect(function(channel, volume)
		if channel == "music" then
			music.Volume = volume
		end
	end)

	playCurrent()
end

return MusicPlayer
