-- A small outlined tag: price badges, "Kindred spirits" names, status notes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

local PADDING_X = UDim.new(0, 12)
local PADDING_Y = UDim.new(0, 5)

export type Props = {
	text: string,
	color: Color3?, -- text and border color
	background: Color3?, -- default: transparent
	textSize: number?,
	font: Font?,
	layoutOrder: number?,
	position: UDim2?,
	anchorPoint: Vector2?,
}

local function Chip(props: Props)
	local color = props.color or Theme.Colors.ink
	return e("TextLabel", {
		Text = props.text,
		FontFace = props.font or Theme.Fonts.bodyBold,
		TextSize = props.textSize or Theme.TextSize.label,
		TextColor3 = color,
		BackgroundColor3 = props.background or Theme.Colors.paperLight,
		BackgroundTransparency = if props.background then 0 else 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromScale(0, 0),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = e("UICorner", { CornerRadius = Theme.Size.radiusSmall }),
		Stroke = e("UIStroke", {
			Color = color,
			Thickness = Theme.Size.border,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Padding = e("UIPadding", {
			PaddingLeft = PADDING_X,
			PaddingRight = PADDING_X,
			PaddingTop = PADDING_Y,
			PaddingBottom = PADDING_Y,
		}),
	})
end

return Chip
