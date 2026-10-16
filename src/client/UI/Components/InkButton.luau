-- The main button style.
--   primary:   vermilion fill, paper text, solid ink drop shadow (one per screen)
--   secondary: ink outline on paper
-- Uses Activated, so it works with mouse, touch and gamepad, and shrinks slightly while pressed.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)
local Label = require(script.Parent.Label)
local Chip = require(script.Parent.Chip)
local Input = require(script.Parent.Parent.Util.Input)

local e = React.createElement
local Colors, Size = Theme.Colors, Theme.Size

local HOVER_DARKEN = 0.12
local PRIMARY_HOVER_COLOR = Colors.vermilion:Lerp(Colors.ink, HOVER_DARKEN)
local CONTENT_PADDING = UDim.new(0, 22)
local SUBTEXT_GAP = UDim.new(0, 2)
local CENTER = UDim2.fromScale(0.5, 0.5)
local CENTER_ANCHOR = Vector2.new(0.5, 0.5)
local LEFT_CENTER_ANCHOR = Vector2.new(0, 0.5)
local RIGHT_CENTER = UDim2.fromScale(1, 0.5)
local RIGHT_CENTER_ANCHOR = Vector2.new(1, 0.5)

export type Variant = "primary" | "secondary"

export type Props = {
	text: string,
	onActivated: () -> (),
	variant: Variant?, -- default "primary"
	size: UDim2,
	subtext: string?, -- small second line under the text
	badge: string?, -- chip on the right, e.g. a price
	textSize: number?,
	selectOnMount: boolean?, -- gamepad: select this button when it appears
	layoutOrder: number?,
	position: UDim2?,
	anchorPoint: Vector2?,
}

local function InkButton(props: Props)
	local isPrimary = props.variant ~= "secondary"
	local hovered, setHovered = React.useState(false)
	local pressed, setPressed = React.useState(false)
	local faceRef = React.useRef(nil)

	React.useEffect(function()
		if props.selectOnMount and UserInputService.GamepadEnabled then
			GuiService.SelectedObject = faceRef.current
		end
	end, {})

	local textColor = if isPrimary then Colors.paper else Colors.ink
	local hasExtras = props.subtext ~= nil or props.badge ~= nil

	local title = e(Label, {
		text = props.text,
		font = if isPrimary then Theme.Fonts.display else Theme.Fonts.displayBold,
		textSize = props.textSize or (if isPrimary then Theme.TextSize.button else Theme.TextSize.buttonSmall),
		color = textColor,
		wrapped = false,
		size = UDim2.fromScale(0, 0),
		automaticSize = Enum.AutomaticSize.XY,
		alignX = Enum.TextXAlignment.Left,
		layoutOrder = 1,
	})

	local content
	if hasExtras then
		content = {
			Text = e("Frame", {
				AnchorPoint = LEFT_CENTER_ANCHOR,
				Position = UDim2.fromScale(0, 0.5),
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = SUBTEXT_GAP }),
				Title = title,
				Subtext = if props.subtext
					then e(Label, {
						text = props.subtext,
						font = Theme.Fonts.bodyBold,
						textSize = Theme.TextSize.small,
						color = textColor,
						wrapped = false,
						size = UDim2.fromScale(0, 0),
						automaticSize = Enum.AutomaticSize.XY,
						alignX = Enum.TextXAlignment.Left,
						layoutOrder = 2,
					})
					else nil,
			}),
			Badge = if props.badge
				then e(Chip, {
					text = props.badge,
					color = textColor,
					font = Theme.Fonts.bodyHeavy,
					anchorPoint = RIGHT_CENTER_ANCHOR,
					position = RIGHT_CENTER,
				})
				else nil,
		}
	else
		content = {
			Text = e("Frame", {
				AnchorPoint = CENTER_ANCHOR,
				Position = CENTER,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
			}, { Title = title }),
		}
	end

	content.Corner = e("UICorner", { CornerRadius = Size.radius })
	content.Scale = e("UIScale", { Scale = if pressed then Theme.Motion.PRESS_SCALE else 1 })
	content.Padding = e("UIPadding", { PaddingLeft = CONTENT_PADDING, PaddingRight = CONTENT_PADDING })
	content.Stroke = if isPrimary
		then nil
		else e("UIStroke", {
			Color = Colors.ink,
			Thickness = Size.border,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})

	return e("Frame", {
		Size = props.size,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
	}, {
		Shadow = if isPrimary
			then e("Frame", {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(0, Size.shadowOffset),
				BackgroundColor3 = Colors.ink,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, { Corner = e("UICorner", { CornerRadius = Size.radius }) })
			else nil,
		Face = e("TextButton", {
			ref = faceRef,
			Text = "",
			AutoButtonColor = false,
			AnchorPoint = CENTER_ANCHOR,
			Position = CENTER,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = if isPrimary
				then (if hovered then PRIMARY_HOVER_COLOR else Colors.vermilion)
				else Colors.paperLight,
			BackgroundTransparency = if isPrimary or hovered then 0 else 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			[React.Event.Activated] = function()
				props.onActivated()
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
		}, content),
	})
end

return InkButton
