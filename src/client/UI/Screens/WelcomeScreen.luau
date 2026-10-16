-- Title screen: "Which Anime Character Are You?", Start Quiz / Collection, and a row of
-- the 10 title seals showing collection progress.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Data = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data")
local Archetypes = require(Data:WaitForChild("Archetypes"))
local QuestionBank = require(Data:WaitForChild("QuestionBank"))

local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Components = UI.Components
local Label = require(Components.Label)
local InkButton = require(Components.InkButton)
local Seal = require(Components.Seal)
local Spacer = require(Components.Spacer)

local e = React.createElement
local Colors, TextSize, Fonts = Theme.Colors, Theme.TextSize, Theme.Fonts

local BRAND_KANJI = "魂" -- "soul"
local COLUMN_TOP = 78
local COLUMN_WIDTH = 760
local BANNER_SIZE = Vector2.new(560, 120)
local BANNER_BAND_SIZE = UDim2.fromOffset(540, 96)
local BANNER_TILT = -1.5
local BANNER_TEXT_SIZE = 60
local BRAND_SEAL_SIZE = 84
local BRAND_SEAL_TILT = -6
local BUTTON_COLUMN_WIDTH = 380
local START_BUTTON_HEIGHT = 66
local COLLECTION_BUTTON_HEIGHT = 58
local BUTTON_GAP = UDim.new(0, 14)
local PROGRESS_BOTTOM = 52
local PROGRESS_SEAL_SIZE = 34
local PROGRESS_SEAL_GAP = UDim.new(0, 8)
local START_TEXT_SIZE = 26
local NOTICE_GAP = 14
local SUBTITLE = `{QuestionBank.getTotalQuestions()} questions · {#Archetypes.list} titles · find the one that is yours`

export type Props = {
	unlockedIds: { string },
	notice: string?, -- e.g. why the quiz couldn't start
	onStart: () -> (),
	onCollection: () -> (),
}

local function Banner()
	return e("Frame", {
		Size = UDim2.fromOffset(BANNER_SIZE.X, BANNER_SIZE.Y),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
	}, {
		Band = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = BANNER_BAND_SIZE,
			Rotation = BANNER_TILT,
			BackgroundColor3 = Colors.ink,
			BorderSizePixel = 0,
		}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
		Text = e(Label, {
			text = "Are You?",
			font = Fonts.display,
			textSize = BANNER_TEXT_SIZE,
			color = Colors.paper,
			size = UDim2.fromScale(1, 1),
			automaticSize = Enum.AutomaticSize.None,
		}),
		Seal = e(Seal, {
			kanji = BRAND_KANJI,
			size = BRAND_SEAL_SIZE,
			rotation = BRAND_SEAL_TILT,
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.new(1, 12, 0.5, 0),
		}),
	})
end

local function CollectionProgress(props: { unlockedIds: { string } })
	local seals = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = PROGRESS_SEAL_GAP,
		}),
	}
	for order, archetype in Archetypes.list do
		seals[archetype.id] = e(Seal, {
			kanji = archetype.kanji,
			size = PROGRESS_SEAL_SIZE,
			locked = not table.find(props.unlockedIds, archetype.id),
			layoutOrder = order,
		})
	end

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -PROGRESS_BOTTOM),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),
		Caption = e(Label, {
			text = `Titles collected · {#props.unlockedIds} / {#Archetypes.list}`,
			font = Fonts.bodyBold,
			textSize = TextSize.caption,
			color = Colors.textMuted,
			layoutOrder = 1,
		}),
		Seals = e("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, seals),
	})
end

local function WelcomeScreen(props: Props)
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Column = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, COLUMN_TOP),
			Size = UDim2.fromOffset(COLUMN_WIDTH, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Title = e(Label, {
				text = "Which Anime Character",
				font = Fonts.display,
				textSize = TextSize.hero,
				layoutOrder = 1,
			}),
			GapTitle = e(Spacer, { height = 6, layoutOrder = 2 }),
			Banner = e(Banner),
			GapBanner = e(Spacer, { height = 22, layoutOrder = 4 }),
			Subtitle = e(Label, {
				text = SUBTITLE,
				font = Fonts.bodyBold,
				textSize = TextSize.body,
				color = Colors.textMuted,
				layoutOrder = 5,
			}),
			GapSubtitle = e(Spacer, { height = 34, layoutOrder = 6 }),
			Buttons = e("Frame", {
				Size = UDim2.fromOffset(BUTTON_COLUMN_WIDTH, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 7,
			}, {
				Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = BUTTON_GAP }),
				Start = e(InkButton, {
					text = "Start Quiz",
					onActivated = props.onStart,
					size = UDim2.new(1, 0, 0, START_BUTTON_HEIGHT),
					textSize = START_TEXT_SIZE,
					selectOnMount = true,
					layoutOrder = 1,
				}),
				Collection = e(InkButton, {
					text = "Collection",
					variant = "secondary",
					onActivated = props.onCollection,
					size = UDim2.new(1, 0, 0, COLLECTION_BUTTON_HEIGHT),
					layoutOrder = 2,
				}),
			}),
			GapNotice = if props.notice then e(Spacer, { height = NOTICE_GAP, layoutOrder = 8 }) else nil,
			Notice = if props.notice
				then e(Label, {
					text = props.notice,
					font = Fonts.bodyHeavy,
					textSize = TextSize.label,
					color = Colors.vermilion,
					layoutOrder = 9,
				})
				else nil,
		}),
		Progress = e(CollectionProgress, { unlockedIds = props.unlockedIds }),
	})
end

return WelcomeScreen
