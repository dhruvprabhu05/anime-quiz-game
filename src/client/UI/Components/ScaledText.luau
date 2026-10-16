-- Text that can be larger than Roblox's 100 px TextSize limit: the label is drawn at a
-- size Roblox allows, then enlarged with a UIScale. Used for big kanji (seals, watermarks).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

local CENTER = UDim2.fromScale(0.5, 0.5)
local CENTER_ANCHOR = Vector2.new(0.5, 0.5)

export type Props = {
	text: string,
	textSize: number, -- any size, in pixels
	font: Font?,
	color: Color3?,
	transparency: number?,
	size: UDim2?, -- box the text is centered in; default fills the parent
	position: UDim2?,
	anchorPoint: Vector2?,
}

local function ScaledText(props: Props)
	local scale = math.max(1, props.textSize / Theme.MAX_TEXT_SIZE)
	return e("Frame", {
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
	}, {
		Label = e("TextLabel", {
			Text = props.text,
			FontFace = props.font or Theme.Fonts.kanji,
			TextSize = props.textSize / scale,
			TextColor3 = props.color or Theme.Colors.ink,
			TextTransparency = props.transparency or 0,
			AnchorPoint = CENTER_ANCHOR,
			Position = CENTER,
			Size = UDim2.fromScale(1 / scale, 1 / scale), -- grows back to full size with the UIScale
			BackgroundTransparency = 1,
		}, {
			Scale = e("UIScale", { Scale = scale }),
		}),
	})
end

return ScaledText
