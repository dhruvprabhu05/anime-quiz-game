-- A red hanko-style seal stamp holding one kanji. Locked seals show "?" in a faint outline.
-- All proportions scale with `size`, so the same component draws the 34 px progress
-- seals and the 270 px result stamp.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)
local ScaledText = require(script.Parent.ScaledText)

local e = React.createElement
local Colors = Theme.Colors

local CORNER_RATIO = 0.07
local INSET_RATIO = 0.06 -- gap between the edge and the inner paper line
local INNER_LINE_RATIO = 0.025
local MIN_INNER_LINE = 1.5
local KANJI_RATIO = 0.62
local LOCKED_MARK_RATIO = 0.45
local LOCKED_MARK = "?"
local SMALL_SEAL = 48 -- seals smaller than this skip the inner line
local CENTER = UDim2.fromScale(0.5, 0.5)
local CENTER_ANCHOR = Vector2.new(0.5, 0.5)

export type Props = {
	kanji: string,
	size: number, -- width and height in pixels
	rotation: number?, -- degrees; a slight tilt looks hand-stamped
	locked: boolean?,
	layoutOrder: number?,
	position: UDim2?,
	anchorPoint: Vector2?,
}

local function Seal(props: Props)
	local size = props.size
	local corner = e("UICorner", { CornerRadius = UDim.new(0, math.round(size * CORNER_RATIO)) })

	local stamp
	if props.locked then
		stamp = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Corner = corner,
			Stroke = e("UIStroke", { Color = Colors.lockedBorder, Thickness = Theme.Size.border }),
			Mark = e(ScaledText, {
				text = LOCKED_MARK,
				textSize = size * LOCKED_MARK_RATIO,
				font = Theme.Fonts.display,
				color = Colors.textLocked,
			}),
		})
	else
		local inset = math.round(size * INSET_RATIO)
		stamp = e("Frame", {
			-- Tilted inside an untilted holder: layouts ignore Rotation on the items they arrange
			AnchorPoint = CENTER_ANCHOR,
			Position = CENTER,
			Size = UDim2.fromScale(1, 1),
			Rotation = props.rotation or 0,
			BackgroundColor3 = Colors.vermilion,
			BorderSizePixel = 0,
		}, {
			Corner = corner,
			InnerLine = if size >= SMALL_SEAL
				then e("Frame", {
					Size = UDim2.new(1, -2 * inset, 1, -2 * inset),
					Position = UDim2.fromOffset(inset, inset),
					BackgroundTransparency = 1,
				}, {
					Corner = corner,
					Stroke = e("UIStroke", {
						Color = Colors.paper,
						Thickness = math.max(MIN_INNER_LINE, size * INNER_LINE_RATIO),
					}),
				})
				else nil,
			Kanji = e(ScaledText, {
				text = props.kanji,
				textSize = size * KANJI_RATIO,
				color = Colors.paper,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.fromOffset(size, size),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
	}, { Stamp = stamp })
end

return Seal
