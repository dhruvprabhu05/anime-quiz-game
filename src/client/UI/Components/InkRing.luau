-- A thick ink circle, after the ensō brush circle. Children are centered inside it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

local ROUND = UDim.new(1, 0)
local OUTER_THICKNESS = 18
local INNER_THICKNESS = 3
local INNER_GAP = 14 -- space between the thick ring and the faint inner ring
local INNER_TRANSPARENCY = 0.65

export type Props = {
	diameter: number,
	layoutOrder: number?,
	children: any,
}

local function InkRing(props: Props)
	return e("Frame", {
		Size = UDim2.fromOffset(props.diameter, props.diameter),
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
	}, {
		Corner = e("UICorner", { CornerRadius = ROUND }),
		Stroke = e("UIStroke", { Color = Theme.Colors.ink, Thickness = OUTER_THICKNESS }),
		InnerRing = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2 * INNER_GAP, 1, -2 * INNER_GAP),
			BackgroundTransparency = 1,
		}, {
			Corner = e("UICorner", { CornerRadius = ROUND }),
			Stroke = e("UIStroke", {
				Color = Theme.Colors.ink,
				Thickness = INNER_THICKNESS,
				Transparency = INNER_TRANSPARENCY,
			}),
		}),
		Content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, props.children),
	})
end

return InkRing
