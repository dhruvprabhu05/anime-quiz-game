-- A square ink-outlined button holding one symbol (settings gear, back arrow, close).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement
local Colors, Size = Theme.Colors, Theme.Size

local GLYPH_SIZE = 28

export type Props = {
	glyph: string,
	onActivated: () -> (),
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
}

local function IconButton(props: Props)
	local hovered, setHovered = React.useState(false)

	return e("TextButton", {
		Text = props.glyph,
		FontFace = Theme.Fonts.bodyHeavy,
		TextSize = GLYPH_SIZE,
		TextColor3 = Colors.ink,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(Size.iconButton, Size.iconButton),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
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
	})
end

return IconButton
