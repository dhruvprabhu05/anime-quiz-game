local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

	-- Built-in Roblox particle textures
	local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
	local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
	local FIRE_TEXTURE = "rbxasset://textures/particles/fire_main.dds"

	-- === LAYER 1: Inner core particles (bright, sharp, textured) ===
	local coreEmitter = Instance.new("ParticleEmitter")
	coreEmitter.Name = "AuraCore"
	coreEmitter.Texture = SPARK_TEXTURE
	coreEmitter.Color = config.torsoColor
	coreEmitter.Speed = NumberRange.new(config.torsoSpeed.Min * 1.5, config.torsoSpeed.Max * 1.5)
	coreEmitter.Rate = config.torsoRate * 2
	coreEmitter.Lifetime = NumberRange.new(config.torsoLifetime.Min * 1.3, config.torsoLifetime.Max * 1.3)
	coreEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.3, 1.5),
		NumberSequenceKeypoint.new(0.7, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	coreEmitter.SpreadAngle = config.torsoSpread
	coreEmitter.RotSpeed = NumberRange.new(-60, 60)
	coreEmitter.Rotation = NumberRange.new(0, 360)
	coreEmitter.Acceleration = Vector3.new(0, 1, 0)
	coreEmitter.Drag = 2
	coreEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.05),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	coreEmitter.LightEmission = 1
	coreEmitter.LightInfluence = 0
	coreEmitter.LockedToPart = true
	coreEmitter:SetAttribute(AURA_TAG, true)
	coreEmitter.Parent = rootPart

	-- === LAYER 2: Outer glow (soft, large, slow — gives the aura volume) ===
	local glowEmitter = Instance.new("ParticleEmitter")
	glowEmitter.Name = "AuraGlow"
	glowEmitter.Texture = SMOKE_TEXTURE
	glowEmitter.Color = config.torsoColor
	glowEmitter.Speed = NumberRange.new(config.torsoSpeed.Min * 0.4, config.torsoSpeed.Max * 0.5)
	glowEmitter.Rate = config.torsoRate
	glowEmitter.Lifetime = NumberRange.new(config.torsoLifetime.Min * 2, config.torsoLifetime.Max * 2.5)
	glowEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.0),
		NumberSequenceKeypoint.new(0.3, 5.0),
		NumberSequenceKeypoint.new(0.7, 4.0),
		NumberSequenceKeypoint.new(1, 0),
	})
	glowEmitter.SpreadAngle = Vector2.new(config.torsoSpread.X + 30, config.torsoSpread.Y + 30)
	glowEmitter.RotSpeed = NumberRange.new(-20, 20)
	glowEmitter.Rotation = NumberRange.new(0, 360)
	glowEmitter.Acceleration = Vector3.new(0, 0.5, 0)
	glowEmitter.Drag = 1
	glowEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowEmitter.LightEmission = 1
	glowEmitter.LightInfluence = 0
	glowEmitter.LockedToPart = true
	glowEmitter:SetAttribute(AURA_TAG, true)
	glowEmitter.Parent = rootPart

	-- === LAYER 3: Rising wisps (thin trails that float upward) ===
	local wispEmitter = Instance.new("ParticleEmitter")
	wispEmitter.Name = "AuraWisp"
	wispEmitter.Texture = FIRE_TEXTURE
	wispEmitter.Color = config.torsoColor
	wispEmitter.Speed = NumberRange.new(1, 3)
	wispEmitter.Rate = 12
	wispEmitter.Lifetime = NumberRange.new(1.2, 2.5)
	wispEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.2, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	wispEmitter.SpreadAngle = Vector2.new(20, 20)
	wispEmitter.RotSpeed = NumberRange.new(-30, 30)
	wispEmitter.Rotation = NumberRange.new(0, 360)
	wispEmitter.Acceleration = Vector3.new(0, 4, 0)
	wispEmitter.Drag = 1.5
	wispEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.4, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	wispEmitter.LightEmission = 1
	wispEmitter.LightInfluence = 0
	wispEmitter.LockedToPart = true
	wispEmitter:SetAttribute(AURA_TAG, true)
	wispEmitter.Parent = rootPart

	-- === PointLight (big and bright) ===
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "AuraLight"
	pointLight.Color = config.lightColor
	pointLight.Brightness = config.lightBrightness * 3
	pointLight.Range = 24
	pointLight.Shadows = false
	pointLight:SetAttribute(AURA_TAG, true)
	pointLight.Parent = rootPart

	-- === Ground ring (Attachment-based — no physics, no drift) ===
	local groundAttachment = Instance.new("Attachment")
	groundAttachment.Name = "AuraGroundAttachment"
	groundAttachment.Position = Vector3.new(0, -3, 0)
	groundAttachment:SetAttribute(AURA_TAG, true)
	groundAttachment.Parent = rootPart

	-- Ground ring: main spread
	local groundEmitter = Instance.new("ParticleEmitter")
	groundEmitter.Name = "AuraGround"
	groundEmitter.Texture = SPARK_TEXTURE
	groundEmitter.Color = config.groundColor
	groundEmitter.Speed = NumberRange.new(3, 6)
	groundEmitter.Rate = config.groundRate * 3
	groundEmitter.Lifetime = NumberRange.new(0.5, 1.0)
	groundEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.3, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	groundEmitter.SpreadAngle = Vector2.new(180, 0)
	groundEmitter.Rotation = NumberRange.new(0, 360)
	groundEmitter.RotSpeed = NumberRange.new(-90, 90)
	groundEmitter.Drag = 4
	groundEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	groundEmitter.LightEmission = 1
	groundEmitter.LightInfluence = 0
	groundEmitter.LockedToPart = true
	groundEmitter:SetAttribute(AURA_TAG, true)
	groundEmitter.Parent = groundAttachment

	-- Ground ring: soft glow underneath
	local groundGlow = Instance.new("ParticleEmitter")
	groundGlow.Name = "AuraGroundGlow"
	groundGlow.Texture = SMOKE_TEXTURE
	groundGlow.Color = config.groundColor
	groundGlow.Speed = NumberRange.new(1, 2.5)
	groundGlow.Rate = 10
	groundGlow.Lifetime = NumberRange.new(0.8, 1.5)
	groundGlow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3.0),
		NumberSequenceKeypoint.new(0.5, 6.0),
		NumberSequenceKeypoint.new(1, 0),
	})
	groundGlow.SpreadAngle = Vector2.new(180, 10)
	groundGlow.Rotation = NumberRange.new(0, 360)
	groundGlow.Drag = 3
	groundGlow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.4, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	groundGlow.LightEmission = 1
	groundGlow.LightInfluence = 0
	groundGlow.LockedToPart = true
	groundGlow:SetAttribute(AURA_TAG, true)
	groundGlow.Parent = groundAttachment

	-- === SECRET: Anime Transformation extras ===
	if archetypeId == "anime_transformation" then
		local head = character:FindFirstChild("Head")
		if head then
			local eyeGui = Instance.new("BillboardGui")
			eyeGui.Name = "AnimeEyes"
			eyeGui.Size = UDim2.new(1.5, 0, 0.6, 0)
			eyeGui.StudsOffset = Vector3.new(0, 0.2, -0.6)
			eyeGui.AlwaysOnTop = false
			eyeGui:SetAttribute(AURA_TAG, true)
			eyeGui.Parent = head

			local eyeLabel = Instance.new("TextLabel")
			eyeLabel.Size = UDim2.new(1, 0, 1, 0)
			eyeLabel.BackgroundTransparency = 1
			eyeLabel.Text = "✦  ✦"
			eyeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			eyeLabel.TextScaled = true
			eyeLabel.Font = Enum.Font.GothamBlack
			eyeLabel.Parent = eyeGui

			task.spawn(function()
				local colors = {
					Color3.fromRGB(255, 50, 50),
					Color3.fromRGB(50, 200, 255),
					Color3.fromRGB(255, 200, 50),
					Color3.fromRGB(200, 50, 255),
				}
				local idx = 1
				while eyeLabel and eyeLabel.Parent do
					idx = idx % #colors + 1
					TweenService:Create(eyeLabel, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
						TextColor3 = colors[idx],
					}):Play()
					task.wait(0.8)
				end
			end)
		end
	end
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
