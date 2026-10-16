-- The wait before the result: countdown inside an ink ring, plus the two ways to skip it.
-- Prices are read live from Roblox so the buttons always match what the player pays.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Format = require(UI.Util.Format)
local useSecondsLeft = require(UI.Hooks.useSecondsLeft)
local useProductPrice = require(UI.Hooks.useProductPrice)
local Components = UI.Components
local Label = require(Components.Label)
local InkButton = require(Components.InkButton)
local InkRing = require(Components.InkRing)
local Spacer = require(Components.Spacer)

local e = React.createElement
local Colors, TextSize, Fonts = Theme.Colors, Theme.TextSize, Theme.Fonts

local SKIP_PRODUCT_ID = Config.Products.SKIP_TIMER_PRODUCT_ID
local PASS_ID = Config.Products.INSTANT_UNLOCK_PASS_ID
local COLUMN_TOP = 56
local RING_DIAMETER = 300
local CLOCK_TEXT_SIZE = 76
local BUTTON_HEIGHT = 72
local SKIP_BUTTON_WIDTH = 330
local UNLOCK_BUTTON_WIDTH = 400
local BUTTON_GAP = UDim.new(0, 18)
local FOOTNOTE = `Results unlock after {Format.minutes(Config.Quiz.COOLDOWN_SECONDS)}, or skip the wait.`

export type Props = {
	deadline: number, -- os.clock() time when the result unlocks
	onReveal: () -> (),
}

local function TimerScreen(props: Props)
	local secondsLeft = useSecondsLeft(props.deadline, props.onReveal)
	local skipPrice = useProductPrice(SKIP_PRODUCT_ID, Enum.InfoType.Product)
	local passPrice = useProductPrice(PASS_ID, Enum.InfoType.GamePass)

	-- Buying Instant Unlock reveals the result right away
	local onRevealRef = React.useRef(props.onReveal)
	onRevealRef.current = props.onReveal
	React.useEffect(function()
		local connection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(
			function(player, passId, wasPurchased)
				if player == Players.LocalPlayer and passId == PASS_ID and wasPurchased then
					onRevealRef.current()
				end
			end
		)
		return function()
			connection:Disconnect()
		end
	end, {})

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, COLUMN_TOP),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Title = e(Label, {
			text = "Your title is ready",
			font = Fonts.display,
			textSize = TextSize.title,
			layoutOrder = 1,
		}),
		GapTitle = e(Spacer, { height = 10, layoutOrder = 2 }),
		Subtitle = e(Label, {
			text = "Revealed in",
			font = Fonts.bodyBold,
			textSize = TextSize.body,
			color = Colors.textMuted,
			layoutOrder = 3,
		}),
		GapSubtitle = e(Spacer, { height = 18, layoutOrder = 4 }),
		Ring = e(InkRing, { diameter = RING_DIAMETER, layoutOrder = 5 }, {
			Clock = e(Label, {
				text = Format.clock(secondsLeft),
				font = Fonts.display,
				textSize = CLOCK_TEXT_SIZE,
				size = UDim2.fromScale(1, 1),
				automaticSize = Enum.AutomaticSize.None,
			}),
		}),
		GapRing = e(Spacer, { height = 36, layoutOrder = 6 }),
		Buttons = e("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 7,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = BUTTON_GAP,
			}),
			Skip = e(InkButton, {
				text = `Skip {Format.minutes(Config.Quiz.SKIP_SECONDS)}`,
				variant = "secondary",
				badge = Format.robux(skipPrice),
				size = UDim2.fromOffset(SKIP_BUTTON_WIDTH, BUTTON_HEIGHT),
				layoutOrder = 1,
				onActivated = function()
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, SKIP_PRODUCT_ID)
				end,
			}),
			InstantUnlock = e(InkButton, {
				text = "Instant Unlock",
				subtext = "Never wait again",
				badge = Format.robux(passPrice),
				size = UDim2.fromOffset(UNLOCK_BUTTON_WIDTH, BUTTON_HEIGHT),
				selectOnMount = true,
				layoutOrder = 2,
				onActivated = function()
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, PASS_ID)
				end,
			}),
		}),
		GapButtons = e(Spacer, { height = 28, layoutOrder = 8 }),
		Footnote = e(Label, {
			text = FOOTNOTE,
			font = Fonts.body,
			textSize = TextSize.caption,
			color = Colors.textMuted,
			layoutOrder = 9,
		}),
	})
end

return TimerScreen
