-- Full-screen washi paper behind every screen: ink "scroll rods" with a gold line at the
-- top and bottom, and a giant faint kanji watermark that changes per screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement
local Colors, Size = Theme.Colors, Theme.Size

local WATERMARK_HEIGHT = 0.85 -- of the screen height
local WATERMARK_POSITION = UDim2.fromScale(1.02, 0.55)
local WATERMARK_ANCHOR = Vector2.new(1, 0.5)

local function rod(atBottom: boolean)
	local anchorY = if atBottom then 1 else 0
	return e("Frame", {
		AnchorPoint = Vector2.new(0, anchorY),
		Position = UDim2.fromScale(0, anchorY),
		Size = UDim2.new(1, 0, 0, Size.scrollRod + Size.scrollRodTrim),
		BackgroundColor3 = Colors.gold,
		BorderSizePixel = 0,
	}, {
		Ink = e("Frame", {
			AnchorPoint = Vector2.new(0, anchorY),
			Position = UDim2.fromScale(0, anchorY),
			Size = UDim2.new(1, 0, 0, Size.scrollRod),
			BackgroundColor3 = Colors.ink,
			BorderSizePixel = 0,
		}),
	})
end

export type Props = {
	watermark: string?, -- one kanji, or nil for none
}

local function ScreenBackdrop(props: Props)
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Colors.paper,
		BorderSizePixel = 0,
	}, {
		TopRod = rod(false),
		BottomRod = rod(true),
		Watermark = if props.watermark
			then e("TextLabel", {
				Text = props.watermark,
				FontFace = Theme.Fonts.kanji,
				TextScaled = true,
				TextColor3 = Colors.ink,
				TextTransparency = Theme.Transparency.watermark,
				AnchorPoint = WATERMARK_ANCHOR,
				Position = WATERMARK_POSITION,
				Size = UDim2.fromScale(WATERMARK_HEIGHT, WATERMARK_HEIGHT),
				BackgroundTransparency = 1,
			}, {
				Square = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
			})
			else nil,
	})
end

return ScreenBackdrop
