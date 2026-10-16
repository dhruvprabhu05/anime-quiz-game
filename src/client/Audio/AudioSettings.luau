--!strict
-- Music and sound-effect volumes, shared by the settings panel and anything that plays sound.

export type Channel = "music" | "sfx"

local DEFAULT_VOLUMES = table.freeze({
	music = 0.3,
	sfx = 0.8,
})

local volumes: { [Channel]: number } = { music = DEFAULT_VOLUMES.music, sfx = DEFAULT_VOLUMES.sfx }
local changedEvent = Instance.new("BindableEvent")

local AudioSettings = {}

-- Fires (channel: Channel, volume: number) whenever a volume changes
AudioSettings.changed = changedEvent.Event

function AudioSettings.get(channel: Channel): number
	return volumes[channel]
end

function AudioSettings.set(channel: Channel, volume: number)
	volumes[channel] = math.clamp(volume, 0, 1)
	changedEvent:Fire(channel, volumes[channel])
end

function AudioSettings.resetToDefaults()
	AudioSettings.set("music", DEFAULT_VOLUMES.music)
	AudioSettings.set("sfx", DEFAULT_VOLUMES.sfx)
end

return AudioSettings
