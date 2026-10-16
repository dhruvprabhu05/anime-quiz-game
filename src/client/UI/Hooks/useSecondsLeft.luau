-- Counts down to `deadline` (an os.clock() time) and calls onDone once when it is reached.
-- Re-renders only when the whole-second value changes, not every frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local function secondsUntil(deadline: number): number
	return math.max(0, math.ceil(deadline - os.clock()))
end

local function useSecondsLeft(deadline: number, onDone: () -> ()): number
	local secondsLeft, setSecondsLeft = React.useState(secondsUntil(deadline))
	local onDoneRef = React.useRef(onDone)
	onDoneRef.current = onDone

	React.useEffect(function()
		local finished = false
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local remaining = secondsUntil(deadline)
			setSecondsLeft(remaining)
			if remaining == 0 and not finished then
				finished = true
				connection:Disconnect()
				onDoneRef.current()
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { deadline })

	return secondsLeft
end

return useSecondsLeft
