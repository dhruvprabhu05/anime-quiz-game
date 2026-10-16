-- Empty vertical gap inside a UIListLayout, for spacing that differs between items.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))

local function Spacer(props: { height: number, layoutOrder: number })
	return React.createElement("Frame", {
		Size = UDim2.fromOffset(0, props.height),
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
	})
end

return Spacer
