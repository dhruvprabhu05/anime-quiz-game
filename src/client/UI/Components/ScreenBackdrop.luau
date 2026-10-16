-- Full-screen washi paper behind every screen, with a giant faint kanji watermark that
-- changes per screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)
local ScaledText = require(script.Parent.ScaledText)

local e = React.createElement

local WATERMARK_SIZE = 560 -- design pixels, scaled with the rest of the UI
local WATERMARK_POSITION = UDim2.fromScale(1, 0.55)
local WATERMARK_ANCHOR = Vector2.new(0.92, 0.5) -- bleeds slightly off the right edge

export type Props = {
	watermark: string?, -- one kanji, or nil for none
	scale: number, -- the fit-to-screen scale of the UI
}

local function ScreenBackdrop(props: Props)
	local watermarkSize = WATERMARK_SIZE * props.scale
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.paper,
		BorderSizePixel = 0,
	}, {
		Watermark = if props.watermark
			then e(ScaledText, {
				text = props.watermark,
				textSize = watermarkSize,
				transparency = Theme.Transparency.watermark,
				size = UDim2.fromOffset(watermarkSize, watermarkSize),
				position = WATERMARK_POSITION,
				anchorPoint = WATERMARK_ANCHOR,
			})
			else nil,
	})
end

return ScreenBackdrop
