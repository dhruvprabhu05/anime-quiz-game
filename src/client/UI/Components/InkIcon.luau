-- Small icons drawn from rounded ink strokes, like brush marks. They are built from Frames,
-- not font symbols, so they look the same on every device (symbols such as "✕" or "⚙"
-- are missing from the game's fonts and show up as empty boxes).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Theme = require(script.Parent.Parent.Theme)

local e = React.createElement

local ROUND = UDim.new(1, 0)
local DIAGONAL = math.sqrt(0.5) -- cos and sin of 45°

-- Proportions of the icon size
local STROKE = 0.14 -- main stroke thickness
local CLOSE_LENGTH = 0.95
local CLOSE_SECOND_STROKE = 0.8 -- the second stroke of the X is a little thinner, like a brush
local BACK_APEX_X = 0.3
local BACK_ARM_LENGTH = 0.6
local GEAR_RING_DIAMETER = 0.56
local GEAR_RING_STROKE = 0.12
local GEAR_TOOTH_LENGTH = 0.2
local GEAR_TOOTH_WIDTH = 0.16
local GEAR_TOOTH_RADIUS = 0.34
local GEAR_TEETH = 8

export type Kind = "close" | "back" | "settings"

export type Props = {
	kind: Kind,
	size: number, -- width and height in pixels
	color: Color3?,
}

local function stroke(center: Vector2, length: number, thickness: number, rotation: number, color: Color3)
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(center.X, center.Y),
		Size = UDim2.fromOffset(length, thickness),
		Rotation = rotation,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, { Corner = e("UICorner", { CornerRadius = ROUND }) })
end

local function closeStrokes(size: number, color: Color3)
	local center = Vector2.new(size / 2, size / 2)
	local thickness = size * STROKE
	return {
		Down = stroke(center, size * CLOSE_LENGTH, thickness, 45, color),
		Up = stroke(center, size * CLOSE_LENGTH, thickness * CLOSE_SECOND_STROKE, -45, color),
	}
end

local function backStrokes(size: number, color: Color3)
	local apex = Vector2.new(size * BACK_APEX_X, size / 2)
	local arm = size * BACK_ARM_LENGTH
	local offset = Vector2.new(arm / 2 * DIAGONAL, arm / 2 * DIAGONAL)
	local thickness = size * STROKE
	return {
		Upper = stroke(apex + Vector2.new(offset.X, -offset.Y), arm, thickness, -45, color),
		Lower = stroke(apex + offset, arm, thickness, 45, color),
	}
end

local function gearStrokes(size: number, color: Color3)
	local center = Vector2.new(size / 2, size / 2)
	local ringSize = size * GEAR_RING_DIAMETER
	local parts = {
		Ring = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(center.X, center.Y),
			Size = UDim2.fromOffset(ringSize, ringSize),
			BackgroundTransparency = 1,
		}, {
			Corner = e("UICorner", { CornerRadius = ROUND }),
			Stroke = e("UIStroke", { Color = color, Thickness = size * GEAR_RING_STROKE }),
		}),
	}
	for tooth = 1, GEAR_TEETH do
		local angle = (tooth - 1) * 360 / GEAR_TEETH
		local radians = math.rad(angle)
		local position = center + Vector2.new(math.cos(radians), math.sin(radians)) * size * GEAR_TOOTH_RADIUS
		parts["Tooth" .. tooth] = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(position.X, position.Y),
			Size = UDim2.fromOffset(size * GEAR_TOOTH_LENGTH, size * GEAR_TOOTH_WIDTH),
			Rotation = angle,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		})
	end
	return parts
end

local DRAWERS = table.freeze({
	close = closeStrokes,
	back = backStrokes,
	settings = gearStrokes,
})

local function InkIcon(props: Props)
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(props.size, props.size),
		BackgroundTransparency = 1,
	}, DRAWERS[props.kind](props.size, props.color or Theme.Colors.ink))
end

return InkIcon
