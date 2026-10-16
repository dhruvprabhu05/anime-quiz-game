-- Returns the scale that fits Theme.DESIGN_SIZE inside a ScreenGui, plus the ref to attach
-- to that ScreenGui. Updates when the window or device orientation changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local DESIGN_SIZE = Theme.DESIGN_SIZE

local function useFitScale(): (number, { current: ScreenGui? })
	local guiRef = React.useRef(nil)
	local scale, setScale = React.useState(1)

	React.useEffect(function()
		local gui = guiRef.current
		if not gui then
			return nil
		end
		local function update()
			local size = gui.AbsoluteSize
			if size.X > 0 and size.Y > 0 then
				setScale(math.min(size.X / DESIGN_SIZE.X, size.Y / DESIGN_SIZE.Y))
			end
		end
		update()
		local connection = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		return function()
			connection:Disconnect()
		end
	end, {})

	return scale, guiRef
end

return useFitScale
