local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local AuraDefinitions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraDefinitions"))

local AURA_TAG = "AuraEffect"
local GROUND_PART_NAME = "AuraGroundPart"

-- Cache: userId -> archetypeId
local playerAuras: { [number]: string } = {}

-- Cache: userId -> RBXScriptConnection for CharacterAdded listeners
local respawnConnections: { [number]: RBXScriptConnection } = {}

local function removeAura(character: Model)
	if not character then
		return
	end

	for _, descendant in character:GetDescendants() do
		if descendant:GetAttribute(AURA_TAG) then
			descendant:Destroy()
		end
	end

	local groundPart = character:FindFirstChild(GROUND_PART_NAME)
	if groundPart then
		groundPart:Destroy()
	end
end

local function applyAura(character: Model, archetypeId: string)
	local config = AuraDefinitions.get(archetypeId)
	if not config then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	removeAura(character)

	-- Torso ParticleEmitter
	local torsoEmitter = Instance.new("ParticleEmitter")
	torsoEmitter.Name = "AuraTorso"
	torsoEmitter.Color = config.torsoColor
	torsoEmitter.Speed = config.torsoSpeed
	torsoEmitter.Rate = config.torsoRate
	torsoEmitter.Lifetime = config.torsoLifetime
	torsoEmitter.Size = config.torsoSize
	torsoEmitter.SpreadAngle = config.torsoSpread
	torsoEmitter.RotSpeed = NumberRange.new(-45, 45)
	torsoEmitter.Rotation = NumberRange.new(0, 360)
	torsoEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	torsoEmitter.LightEmission = 0.8
	torsoEmitter.LightInfluence = 0.2
	torsoEmitter:SetAttribute(AURA_TAG, true)
	torsoEmitter.Parent = rootPart

	-- PointLight
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "AuraLight"
	pointLight.Color = config.lightColor
	pointLight.Brightness = config.lightBrightness
	pointLight.Range = 10
	pointLight.Shadows = false
	pointLight:SetAttribute(AURA_TAG, true)
	pointLight.Parent = rootPart

	-- Ground ring
	local groundPart = Instance.new("Part")
	groundPart.Name = GROUND_PART_NAME
	groundPart.Size = Vector3.new(0.5, 0.5, 0.5)
	groundPart.Transparency = 1
	groundPart.CanCollide = false
	groundPart.CanQuery = false
	groundPart.CanTouch = false
	groundPart.Massless = true
	groundPart.Anchored = false
	groundPart:SetAttribute(AURA_TAG, true)
	groundPart.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = groundPart
	weld.Parent = groundPart
	groundPart.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)

	local groundEmitter = Instance.new("ParticleEmitter")
	groundEmitter.Name = "AuraGround"
	groundEmitter.Color = config.groundColor
	groundEmitter.Speed = NumberRange.new(1, 2.5)
	groundEmitter.Rate = config.groundRate
	groundEmitter.Lifetime = NumberRange.new(0.6, 1.0)
	groundEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	groundEmitter.SpreadAngle = Vector2.new(180, 180)
	groundEmitter.Rotation = NumberRange.new(0, 360)
	groundEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	groundEmitter.LightEmission = 0.6
	groundEmitter.LightInfluence = 0.2
	groundEmitter:SetAttribute(AURA_TAG, true)
	groundEmitter.Parent = groundPart
end

local function applyAuraToPlayer(userId: number)
	local archetypeId = playerAuras[userId]
	if not archetypeId or archetypeId == "" then
		return
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		task.spawn(function()
			local rp = character:WaitForChild("HumanoidRootPart", 5)
			if rp and playerAuras[userId] == archetypeId then
				applyAura(character, archetypeId)
			end
		end)
		return
	end

	applyAura(character, archetypeId)
end

local function setupRespawnListener(player: Player)
	if respawnConnections[player.UserId] then
		respawnConnections[player.UserId]:Disconnect()
	end

	respawnConnections[player.UserId] = player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		if playerAuras[player.UserId] then
			applyAura(character, playerAuras[player.UserId])
		end
	end)
end

-- Listen for leaderboard updates
local leaderboardRemote = Remotes.get("LeaderboardUpdate") :: RemoteEvent
leaderboardRemote.OnClientEvent:Connect(function(data: { { userId: number, name: string, archetypeId: string, archetypeName: string } })
	for _, entry in data do
		local oldArchetype = playerAuras[entry.userId]
		local newArchetype = entry.archetypeId

		if oldArchetype ~= newArchetype then
			playerAuras[entry.userId] = newArchetype

			local player = Players:GetPlayerByUserId(entry.userId)
			if player and player.Character then
				removeAura(player.Character)
			end

			if newArchetype ~= "" then
				applyAuraToPlayer(entry.userId)
			end
		end
	end

	for userId, _ in playerAuras do
		local player = Players:GetPlayerByUserId(userId)
		if player and not respawnConnections[userId] then
			setupRespawnListener(player)
		end
	end
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player: Player)
	playerAuras[player.UserId] = nil
	if respawnConnections[player.UserId] then
		respawnConnections[player.UserId]:Disconnect()
		respawnConnections[player.UserId] = nil
	end
end)

-- Setup respawn listeners for existing players
for _, player in Players:GetPlayers() do
	setupRespawnListener(player)
end

Players.PlayerAdded:Connect(function(player: Player)
	setupRespawnListener(player)
end)
