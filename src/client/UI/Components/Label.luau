-- Text with the theme's defaults: body font, ink color, wraps, grows to fit its text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

export type Props = {
	text: string,
	font: Font?,
	textSize: number?,
	color: Color3?,
	alignX: Enum.TextXAlignment?,
	alignY: Enum.TextYAlignment?,
	wrapped: boolean?,
	lineHeight: number?,
	size: UDim2?, -- default: full width, height grows with the text
	automaticSize: Enum.AutomaticSize?,
	position: UDim2?,
	anchorPoint: Vector2?,
	rotation: number?,
	layoutOrder: number?,
	zIndex: number?,
}

local function Label(props: Props)
	return React.createElement("TextLabel", {
		Text = props.text,
		FontFace = props.font or Theme.Fonts.body,
		TextSize = props.textSize or Theme.TextSize.body,
		TextColor3 = props.color or Theme.Colors.ink,
		TextXAlignment = props.alignX or Enum.TextXAlignment.Center,
		TextYAlignment = props.alignY or Enum.TextYAlignment.Center,
		TextWrapped = if props.wrapped == nil then true else props.wrapped,
		LineHeight = props.lineHeight or 1,
		Size = props.size or UDim2.fromScale(1, 0),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.Y,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Rotation = props.rotation or 0,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BackgroundTransparency = 1,
	})
end

return Label
