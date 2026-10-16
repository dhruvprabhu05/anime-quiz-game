-- A square ink-outlined button holding one drawn ink icon (settings, back, close).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)
local InkIcon = require(script.Parent.InkIcon)

local e = React.createElement
local Colors, Size = Theme.Colors, Theme.Size

local ICON_SIZE = 24

export type Props = {
	icon: InkIcon.Kind,
	onActivated: () -> (),
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	zIndex: number?,
}

local function IconButton(props: Props)
	local hovered, setHovered = React.useState(false)

	return e("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(Size.iconButton, Size.iconButton),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BackgroundColor3 = Colors.paperLight,
		BackgroundTransparency = if hovered then 0 else 1,
		[React.Event.Activated] = function()
			props.onActivated()
		end,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
	}, {
		Corner = e("UICorner", { CornerRadius = Size.radius }),
		Stroke = e("UIStroke", {
			Color = Colors.ink,
			Thickness = Size.border,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Icon = e(InkIcon, { kind = props.icon, size = ICON_SIZE }),
	})
end

return IconButton
