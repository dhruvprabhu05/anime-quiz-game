-- Handles player spawning: instant teleport to spawn point, kill zone below map
local Players = game:GetService("Players")

local SPAWN_POSITION = Vector3.new(0, 5, 0)

local function onCharacterAdded(player: Player, character: Model)
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")

	-- Teleport instantly to spawn point (no falling from sky)
	rootPart.CFrame = CFrame.new(SPAWN_POSITION)
	rootPart.Velocity = Vector3.zero
	rootPart.AssemblyLinearVelocity = Vector3.zero

	-- Kill zone: if they fall below map, teleport back
	task.spawn(function()
		while character and character.Parent and humanoid.Health > 0 do
			if rootPart.Position.Y < -20 then
				rootPart.CFrame = CFrame.new(SPAWN_POSITION)
				rootPart.AssemblyLinearVelocity = Vector3.zero
			end
			task.wait(0.5)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)

for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end
