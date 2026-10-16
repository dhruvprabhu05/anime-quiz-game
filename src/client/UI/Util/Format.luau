--!strict
-- Text formatting shared by several screens.

local SECONDS_PER_MINUTE = 60

local Format = {}

-- 905 -> "15:05". Rounds up, so the clock never shows 00:00 while time remains.
function Format.clock(seconds: number): string
	local whole = math.max(0, math.ceil(seconds))
	return string.format("%02d:%02d", whole // SECONDS_PER_MINUTE, whole % SECONDS_PER_MINUTE)
end

-- 900 -> "15 minutes"
function Format.minutes(seconds: number): string
	local minutes = math.ceil(seconds / SECONDS_PER_MINUTE)
	return if minutes == 1 then "1 minute" else `{minutes} minutes`
end

-- 49 -> "49 R$"; nil (price still loading) -> "… R$"
function Format.robux(price: number?): string
	return `{if price then tostring(price) else "…"} R$`
end

return table.freeze(Format)
