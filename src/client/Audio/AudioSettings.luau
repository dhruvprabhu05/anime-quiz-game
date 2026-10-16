--!strict
-- The background music volume, shared by the settings panel and the music player.

local DEFAULT_MUSIC_VOLUME = 0.3

local musicVolume = DEFAULT_MUSIC_VOLUME
local changedEvent = Instance.new("BindableEvent")

local AudioSettings = {}

-- Fires (volume: number) whenever the music volume changes
AudioSettings.changed = changedEvent.Event

function AudioSettings.getMusicVolume(): number
	return musicVolume
end

function AudioSettings.setMusicVolume(volume: number)
	musicVolume = math.clamp(volume, 0, 1)
	changedEvent:Fire(musicVolume)
end

function AudioSettings.resetToDefaults()
	AudioSettings.setMusicVolume(DEFAULT_MUSIC_VOLUME)
end

return AudioSettings
