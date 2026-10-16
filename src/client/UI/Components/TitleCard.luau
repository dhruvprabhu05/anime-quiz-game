-- One title in the collection grid: its seal, name and example characters,
-- or a dashed "???" card while it is still locked.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)
local Label = require(script.Parent.Label)
local Seal = require(script.Parent.Seal)

local e = React.createElement
local Colors, Size, TextSize = Theme.Colors, Theme.Size, Theme.TextSize

local SEAL_SIZE = 76
local SEAL_TILT = -4
local CONTENT_GAP = UDim.new(0, 12)
local PADDING = UDim.new(0, 16)
local PADDING_TOP = UDim.new(0, 22)
local EXAMPLE_SEPARATOR = " · "
local LOCKED_NAME = "???"
local LOCKED_HINT = "Take the quiz to reveal this title"

export type Props = {
	archetype: { kanji: string, name: string, examples: { string } },
	unlocked: boolean,
	layoutOrder: number?,
}

local function TitleCard(props: Props)
	local unlocked = props.unlocked
	local archetype = props.archetype
	local textColor = if unlocked then Colors.ink else Colors.textLocked
	local subColor = if unlocked then Colors.textMuted else Colors.textLocked

	return e("Frame", {
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = if unlocked then Colors.paperLight else Colors.paperDim,
		BorderSizePixel = 0,
	}, {
		Corner = e("UICorner", { CornerRadius = Size.radius }),
		Stroke = e("UIStroke", {
			Color = if unlocked then Colors.ink else Colors.lockedBorder,
			Thickness = Size.border,
		}),
		Padding = e("UIPadding", {
			PaddingLeft = PADDING,
			PaddingRight = PADDING,
			PaddingTop = PADDING_TOP,
			PaddingBottom = PADDING,
		}),
		Layout = e("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = CONTENT_GAP,
		}),
		Seal = e(Seal, {
			kanji = archetype.kanji,
			size = SEAL_SIZE,
			rotation = SEAL_TILT,
			locked = not unlocked,
			layoutOrder = 1,
		}),
		Name = e(Label, {
			text = if unlocked then archetype.name else LOCKED_NAME,
			font = Theme.Fonts.display,
			textSize = TextSize.cardTitle,
			color = textColor,
			layoutOrder = 2,
		}),
		Detail = e(Label, {
			text = if unlocked then table.concat(archetype.examples, EXAMPLE_SEPARATOR) else LOCKED_HINT,
			font = Theme.Fonts.bodyBold,
			textSize = TextSize.small,
			color = subColor,
			layoutOrder = 3,
		}),
	})
end

return TitleCard
