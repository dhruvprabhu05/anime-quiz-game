-- The reveal: a large seal stamp with the title's kanji, its name and description,
-- example characters, and what to do next.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Archetypes"))

local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Components = UI.Components
local Label = require(Components.Label)
local InkButton = require(Components.InkButton)
local Seal = require(Components.Seal)
local Chip = require(Components.Chip)
local Spacer = require(Components.Spacer)

local e = React.createElement
local Colors, TextSize, Fonts, Size = Theme.Colors, Theme.TextSize, Theme.Fonts, Theme.Size

local LEFT_COLUMN_X = 120
local LEFT_COLUMN_WIDTH = 360
local RIGHT_COLUMN_X = 560
local RIGHT_COLUMN_WIDTH = 600
local SEAL_SIZE = 270
local SEAL_TILT = -6
local NAME_TEXT_SIZE = 56
local UNDERLINE_SIZE = UDim2.fromOffset(360, 10)
local DESCRIPTION_WIDTH = 560
local PRIMARY_BUTTON_SIZE = UDim2.fromOffset(260, Size.buttonHeight)
local SECONDARY_BUTTON_SIZE = UDim2.fromOffset(220, Size.buttonHeight)
local ROW_GAP = UDim.new(0, 10)
local BUTTON_GAP = UDim.new(0, Size.gap)

export type Props = {
	archetypeId: string,
	isNew: boolean, -- first time the player got this title
	unlockedCount: number,
	onCollection: () -> (),
	onRetake: () -> (),
}

local function horizontalRow(layoutOrder: number, gap: UDim, children)
	children.Layout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = gap,
	})
	return e("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
	}, children)
end

local function ResultsScreen(props: Props)
	local archetype = Archetypes.getById(props.archetypeId)
	if not archetype then
		return nil
	end
	local progress = `{props.unlockedCount} / {#Archetypes.list}`

	local kindred = {
		Caption = e(Label, {
			text = "Kindred spirits",
			font = Fonts.bodyHeavy,
			textSize = TextSize.label,
			color = Colors.textMuted,
			wrapped = false,
			size = UDim2.fromScale(0, 0),
			automaticSize = Enum.AutomaticSize.XY,
			layoutOrder = 0,
		}),
	}
	for order, name in archetype.examples do
		kindred["Example" .. order] = e(Chip, { text = name, layoutOrder = order })
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Stamp = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, LEFT_COLUMN_X, 0.5, 0),
			Size = UDim2.fromOffset(LEFT_COLUMN_WIDTH, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, Size.gapLarge),
			}),
			Seal = e(Seal, {
				kanji = archetype.kanji,
				size = SEAL_SIZE,
				rotation = SEAL_TILT,
				layoutOrder = 1,
			}),
			Status = e(Chip, {
				text = if props.isNew
					then `New title unlocked · {progress}`
					else `Already in your collection · {progress}`,
				color = if props.isNew then Colors.vermilion else Colors.ink,
				background = Colors.paperLight,
				layoutOrder = 2,
			}),
		}),
		Details = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, RIGHT_COLUMN_X, 0.5, 0),
			Size = UDim2.fromOffset(RIGHT_COLUMN_WIDTH, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
			Caption = e(Label, {
				text = "Your title",
				font = Fonts.bodyHeavy,
				textSize = TextSize.label,
				color = Colors.textMuted,
				alignX = Enum.TextXAlignment.Left,
				layoutOrder = 1,
			}),
			GapCaption = e(Spacer, { height = 10, layoutOrder = 2 }),
			Name = e(Label, {
				text = archetype.name,
				font = Fonts.display,
				textSize = NAME_TEXT_SIZE,
				alignX = Enum.TextXAlignment.Left,
				layoutOrder = 3,
			}),
			GapName = e(Spacer, { height = 10, layoutOrder = 4 }),
			Underline = e("Frame", {
				Size = UNDERLINE_SIZE,
				BackgroundColor3 = Colors.vermilion,
				BorderSizePixel = 0,
				LayoutOrder = 5,
			}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
			GapUnderline = e(Spacer, { height = 22, layoutOrder = 6 }),
			Description = e(Label, {
				text = archetype.description,
				font = Fonts.body,
				color = Colors.inkSoft,
				lineHeight = 1.2,
				alignX = Enum.TextXAlignment.Left,
				size = UDim2.fromOffset(DESCRIPTION_WIDTH, 0),
				layoutOrder = 7,
			}),
			GapDescription = e(Spacer, { height = 20, layoutOrder = 8 }),
			Kindred = horizontalRow(9, ROW_GAP, kindred),
			GapKindred = e(Spacer, { height = 32, layoutOrder = 10 }),
			Buttons = horizontalRow(11, BUTTON_GAP, {
				Collection = e(InkButton, {
					text = "View collection",
					size = PRIMARY_BUTTON_SIZE,
					selectOnMount = true,
					onActivated = props.onCollection,
					layoutOrder = 1,
				}),
				Retake = e(InkButton, {
					text = "Retake quiz",
					variant = "secondary",
					size = SECONDARY_BUTTON_SIZE,
					onActivated = props.onRetake,
					layoutOrder = 2,
				}),
			}),
		}),
	})
end

return ResultsScreen
