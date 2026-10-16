--!strict
-- The meme image + sound pairs that can pop up between quiz questions.

export type Interlude = { imageId: string, soundId: string }

local LIST: { Interlude } = table.freeze({
	table.freeze({ imageId = "rbxassetid://8073107221", soundId = "rbxassetid://140055886382926" }),
	table.freeze({ imageId = "rbxassetid://10180536577", soundId = "rbxassetid://139929135560595" }),
	table.freeze({ imageId = "rbxassetid://10180628683", soundId = "rbxassetid://80869811224748" }),
	table.freeze({ imageId = "rbxassetid://12053823591", soundId = "rbxassetid://97396403875140" }),
})

local Interludes = {}

Interludes.list = LIST

-- Picks a random interlude not yet shown this quiz, marks it shown, and returns its index.
-- Returns nil once every interlude has been shown.
function Interludes.pickUnshown(shown: { [number]: boolean }): number?
	local available = {}
	for index in LIST do
		if not shown[index] then
			table.insert(available, index)
		end
	end
	if #available == 0 then
		return nil
	end
	local index = available[math.random(1, #available)]
	shown[index] = true
	return index
end

return table.freeze(Interludes)
