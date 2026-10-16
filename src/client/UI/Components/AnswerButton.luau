-- One quiz answer: a paper card with an ink kanji numeral (一 二 三 四) and the answer text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)
local Label = require(script.Parent.Label)
local Input = require(script.Parent.Parent.Util.Input)

local e = React.createElement
local Colors, Size = Theme.Colors, Theme.Size

local MARKER_SIZE = 48
local MARKER_TEXT_SIZE = 26
local CONTENT_GAP = 18
local PADDING_X = UDim.new(0, 22)

export type Props = {
	marker: string, -- kanji numeral
	text: string,
	enabled: boolean, -- false while the question is appearing or after answering
	onActivated: () -> (),
	layoutOrder: number?,
}

local function AnswerButton(props: Props)
	local hovered, setHovered = React.useState(false)
	local pressed, setPressed = React.useState(false)

	return e("Frame", {
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
	}, {
		Shadow = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(0, Size.shadowOffset),
			BackgroundColor3 = Colors.ink,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, { Corner = e("UICorner", { CornerRadius = Size.radius }) }),
		Face = e("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Active = props.enabled,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = if hovered and props.enabled then Colors.paper else Colors.paperLight,
			BorderSizePixel = 0,
			ZIndex = 2,
			[React.Event.Activated] = function()
				if props.enabled then
					props.onActivated()
				end
			end,
			[React.Event.MouseEnter] = function()
				setHovered(true)
			end,
			[React.Event.MouseLeave] = function()
				setHovered(false)
				setPressed(false)
			end,
			[React.Event.InputBegan] = function(_, input: InputObject)
				if Input.isPress(input) then
					setPressed(true)
				end
			end,
			[React.Event.InputEnded] = function(_, input: InputObject)
				if Input.isPress(input) then
					setPressed(false)
				end
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = Size.radius }),
			Stroke = e("UIStroke", {
				Color = Colors.ink,
				Thickness = Size.border,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Scale = e("UIScale", { Scale = if pressed and props.enabled then Theme.Motion.PRESS_SCALE else 1 }),
			Padding = e("UIPadding", { PaddingLeft = PADDING_X, PaddingRight = PADDING_X }),
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, CONTENT_GAP),
			}),
			Marker = e("TextLabel", {
				Text = props.marker,
				FontFace = Theme.Fonts.kanji,
				TextSize = MARKER_TEXT_SIZE,
				TextColor3 = Colors.paper,
				Size = UDim2.fromOffset(MARKER_SIZE, MARKER_SIZE),
				BackgroundColor3 = Colors.ink,
				BorderSizePixel = 0,
				LayoutOrder = 1,
			}, { Corner = e("UICorner", { CornerRadius = Size.radiusSmall }) }),
			Text = e(Label, {
				text = props.text,
				font = Theme.Fonts.bodyBold,
				alignX = Enum.TextXAlignment.Left,
				lineHeight = 1.1,
				size = UDim2.new(1, -(MARKER_SIZE + CONTENT_GAP), 0, 0),
				layoutOrder = 2,
			}),
		}),
	})
end

return AnswerButton
