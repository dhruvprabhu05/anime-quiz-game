-- Listens to a server -> client RemoteEvent for as long as the component is mounted.
-- The handler can change between renders; the latest one is always called.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local function useRemoteEvent(name: string, handler: (...any) -> ())
	local handlerRef = React.useRef(handler)
	handlerRef.current = handler

	React.useEffect(function()
		local connection = Remotes.event(name).OnClientEvent:Connect(function(...)
			handlerRef.current(...)
		end)
		return function()
			connection:Disconnect()
		end
	end, { name })
end

return useRemoteEvent
