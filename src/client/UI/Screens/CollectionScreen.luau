-- All 10 titles in a grid: earned ones show their seal, locked ones stay hidden.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Archetypes"))

local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Components = UI.Components
local Label = require(Components.Label)
local IconButton = require(Components.IconButton)
local ProgressBar = require(Components.ProgressBar)
local TitleCard = require(Components.TitleCard)

local e = React.createElement
local Colors, TextSize, Fonts, Size = Theme.Colors, Theme.TextSize, Theme.Fonts, Theme.Size

local HEADER_TOP = 44
local HEADER_GAP = UDim.new(0, 22)
local PROGRESS_SIZE = UDim2.fromOffset(220, 8)
local GRID_TOP = 140
local GRID_COLUMNS = 5
local CARD_HEIGHT = 238
local CARD_GAP = 20

export type Props = {
	unlockedIds: { string },
	onBack: () -> (),
}

local function CollectionScreen(props: Props)
	local total = #Archetypes.list
	local unlockedCount = #props.unlockedIds
	local gridWidth = Theme.DESIGN_SIZE.X - 2 * Size.screenPadding
	local cardWidth = (gridWidth - (GRID_COLUMNS - 1) * CARD_GAP) / GRID_COLUMNS

	local cards = {
		Grid = e("UIGridLayout", {
			CellSize = UDim2.fromOffset(cardWidth, CARD_HEIGHT),
			CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for order, archetype in Archetypes.list do
		cards[archetype.id] = e(TitleCard, {
			archetype = archetype,
			unlocked = table.find(props.unlockedIds, archetype.id) ~= nil,
			layoutOrder = order,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		TitleRow = e("Frame", {
			Position = UDim2.fromOffset(Size.screenPadding, HEADER_TOP),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = HEADER_GAP,
			}),
			Back = e(IconButton, { icon = "back", onActivated = props.onBack, layoutOrder = 1 }),
			Title = e(Label, {
				text = "Your Collection",
				font = Fonts.display,
				textSize = TextSize.title,
				wrapped = false,
				size = UDim2.fromScale(0, 0),
				automaticSize = Enum.AutomaticSize.XY,
				layoutOrder = 2,
			}),
		}),
		Progress = e("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -Size.screenPadding, 0, HEADER_TOP + 6),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			Count = e(Label, {
				text = `{unlockedCount} / {total} titles`,
				font = Fonts.bodyHeavy,
				textSize = TextSize.labelLarge,
				wrapped = false,
				size = UDim2.fromScale(0, 0),
				automaticSize = Enum.AutomaticSize.XY,
				layoutOrder = 1,
			}),
			Bar = e(ProgressBar, {
				progress = unlockedCount / total,
				size = PROGRESS_SIZE,
				color = Colors.vermilion,
				layoutOrder = 2,
			}),
		}),
		Grid = e("Frame", {
			Position = UDim2.fromOffset(Size.screenPadding, GRID_TOP),
			Size = UDim2.fromOffset(gridWidth, 2 * CARD_HEIGHT + CARD_GAP),
			BackgroundTransparency = 1,
		}, cards),
	})
end

return CollectionScreen
