-- A thin rounded bar filled from the left.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

local ROUND = UDim.new(1, 0)

export type Props = {
	progress: number, -- 0 to 1
	size: UDim2,
	color: Color3?, -- fill color, default ink
	layoutOrder: number?,
}

local function ProgressBar(props: Props)
	local round = e("UICorner", { CornerRadius = ROUND })
	return e("Frame", {
		Size = props.size,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = Theme.Colors.track,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		Corner = round,
		Fill = e("Frame", {
			Size = UDim2.fromScale(math.clamp(props.progress, 0, 1), 1),
			BackgroundColor3 = props.color or Theme.Colors.ink,
			BorderSizePixel = 0,
		}, { Corner = round }),
	})
end

return ProgressBar
