-- A labelled 0–100% slider (used for volume). Drag or tap anywhere on the track.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)
local Label = require(script.Parent.Label)
local Input = require(script.Parent.Parent.Util.Input)

local e = React.createElement
local Colors = Theme.Colors

local TRACK_HEIGHT = 10
local KNOB_SIZE = 24
local ROW_HEIGHT = 28
local GAP = UDim.new(0, 10)
local PERCENT_WIDTH = 60
local ROUND = UDim.new(1, 0)

export type Props = {
	label: string,
	value: number, -- 0 to 1
	onChange: (number) -> (),
	layoutOrder: number?,
}

local function Slider(props: Props)
	local trackRef = React.useRef(nil)
	local dragging = React.useRef(false)
	-- Always call the latest onChange, even from connections made on the first render
	local onChangeRef = React.useRef(props.onChange)
	onChangeRef.current = props.onChange

	local function setFromScreenX(x: number)
		local track = trackRef.current
		if track and track.AbsoluteSize.X > 0 then
			onChangeRef.current(math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
		end
	end

	React.useEffect(function()
		local moved = UserInputService.InputChanged:Connect(function(input)
			if dragging.current and Input.isMove(input) then
				setFromScreenX(input.Position.X)
			end
		end)
		local released = UserInputService.InputEnded:Connect(function(input)
			if Input.isPress(input) then
				dragging.current = false
			end
		end)
		return function()
			moved:Disconnect()
			released:Disconnect()
		end
	end, {})

	local value = math.clamp(props.value, 0, 1)

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = GAP }),
		Header = e("Frame", {
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Name = e(Label, {
				text = props.label,
				font = Theme.Fonts.bodyHeavy,
				alignX = Enum.TextXAlignment.Left,
				size = UDim2.new(1, -PERCENT_WIDTH, 1, 0),
				automaticSize = Enum.AutomaticSize.None,
			}),
			Percent = e(Label, {
				text = `{math.round(value * 100)}%`,
				font = Theme.Fonts.bodyBold,
				color = Colors.textMuted,
				alignX = Enum.TextXAlignment.Right,
				anchorPoint = Vector2.new(1, 0),
				position = UDim2.fromScale(1, 0),
				size = UDim2.new(0, PERCENT_WIDTH, 1, 0),
				automaticSize = Enum.AutomaticSize.None,
			}),
		}),
		Track = e("TextButton", {
			ref = trackRef,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, TRACK_HEIGHT),
			BackgroundColor3 = Colors.track,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			[React.Event.InputBegan] = function(_, input: InputObject)
				if Input.isPress(input) then
					dragging.current = true
					setFromScreenX(input.Position.X)
				end
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = ROUND }),
			Fill = e("Frame", {
				Size = UDim2.fromScale(value, 1),
				BackgroundColor3 = Colors.vermilion,
				BorderSizePixel = 0,
			}, { Corner = e("UICorner", { CornerRadius = ROUND }) }),
			Knob = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(value, 0.5),
				Size = UDim2.fromOffset(KNOB_SIZE, KNOB_SIZE),
				BackgroundColor3 = Colors.paperLight,
				BorderSizePixel = 0,
			}, {
				Corner = e("UICorner", { CornerRadius = ROUND }),
				Stroke = e("UIStroke", { Color = Colors.ink, Thickness = Theme.Size.border }),
			}),
		}),
	})
end

return Slider
