-- A paper card with an ink border and vermilion corner brackets, like a framed scroll.
-- Children are placed inside its padding.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement
local Colors, Size = Theme.Colors, Theme.Size

local BRACKET_LENGTH = 22
local BRACKET_THICKNESS = 3
local BRACKET_INSET = 10
local CONTENT_PADDING = UDim.new(0, 44)

-- Corner positions: { x scale, y scale, x direction into the card, y direction into the card }
local CORNERS = table.freeze({
	TopLeft = { 0, 0, 1, 1 },
	TopRight = { 1, 0, -1, 1 },
	BottomLeft = { 0, 1, 1, -1 },
	BottomRight = { 1, 1, -1, -1 },
})

local function bracketBar(xScale: number, yScale: number, xDir: number, yDir: number, horizontal: boolean)
	local width = if horizontal then BRACKET_LENGTH else BRACKET_THICKNESS
	local height = if horizontal then BRACKET_THICKNESS else BRACKET_LENGTH
	return e("Frame", {
		AnchorPoint = Vector2.new(xScale, yScale),
		Position = UDim2.new(xScale, xDir * BRACKET_INSET, yScale, yDir * BRACKET_INSET),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Colors.vermilion,
		BorderSizePixel = 0,
	})
end

export type Props = {
	size: UDim2,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	children: any,
}

local function OrnateCard(props: Props)
	local children = {
		Corner = e("UICorner", { CornerRadius = Size.radius }),
		Stroke = e("UIStroke", {
			Color = Colors.ink,
			Thickness = Size.border,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = CONTENT_PADDING,
				PaddingRight = CONTENT_PADDING,
				PaddingTop = CONTENT_PADDING,
				PaddingBottom = CONTENT_PADDING,
			}),
			Children = React.createElement(React.Fragment, nil, props.children),
		}),
	}
	for name, corner in CORNERS do
		local xScale, yScale, xDir, yDir = table.unpack(corner)
		children[name .. "Horizontal"] = bracketBar(xScale, yScale, xDir, yDir, true)
		children[name .. "Vertical"] = bracketBar(xScale, yScale, xDir, yDir, false)
	end

	return e("Frame", {
		Size = props.size,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = Colors.paperLight,
		BorderSizePixel = 0,
	}, children)
end

return OrnateCard
