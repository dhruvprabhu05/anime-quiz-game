--!strict
-- Classifies input so buttons treat mouse and touch the same way.

local Input = {}

-- A click or tap starting/ending
function Input.isPress(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- The mouse moving or a finger dragging
function Input.isMove(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

return table.freeze(Input)
