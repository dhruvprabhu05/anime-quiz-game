# Cosmetic Auras Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add archetype-themed particle auras (torso + ground ring + point light) that automatically appear on every player's character after completing the quiz.

**Architecture:** Client-rendered auras driven by server-broadcast archetype data. A shared `AuraDefinitions` module maps each archetype ID to particle configs. A client-side `AuraController` listens for `LeaderboardUpdate` events, compares against cached state, and attaches/removes `ParticleEmitter` + `PointLight` instances on characters. `LeaderboardManager` is updated to include `userId` in broadcast data so the client can reliably find characters.

**Tech Stack:** Roblox Luau, ParticleEmitter, PointLight, Rojo filesystem sync

---

### Task 1: Add userId to LeaderboardManager broadcast data

**Files:**
- Modify: `src/server/LeaderboardManager.server.luau:11-23`

The `AuraController` needs `userId` to find player characters reliably. Currently `getLeaderboardData()` only sends `name`, `archetypeId`, `archetypeName`. Add `userId`.

- [ ] **Step 1: Update getLeaderboardData to include userId**

In `src/server/LeaderboardManager.server.luau`, replace the `getLeaderboardData` function:

```lua
local function getLeaderboardData(): { { userId: number, name: string, archetypeId: string, archetypeName: string } }
	local entries = {}
	for userId, entry in serverArchetypes do
		if entry.archetypeId ~= "" then
			local archetype = Archetypes.getById(entry.archetypeId)
			table.insert(entries, {
				userId = userId,
				name = entry.name,
				archetypeId = entry.archetypeId,
				archetypeName = if archetype then archetype.name else "Unknown",
			})
		end
	end
	return entries
end
```

- [ ] **Step 2: Test in Studio**

Run: Play in Roblox Studio, open Output window.
Expected: No errors. Leaderboard UI still works (it ignores the extra `userId` field).

- [ ] **Step 3: Commit**

```bash
git add src/server/LeaderboardManager.server.luau
git commit -m "feat: include userId in leaderboard broadcast data for aura system"
```

---

### Task 2: Create AuraDefinitions shared module

**Files:**
- Create: `src/shared/AuraDefinitions.luau`

Maps each of the 10 archetype IDs to particle emitter configs (torso color, speed, rate, lifetime, size, spread, ground color, ground rate, light color, light brightness).

- [ ] **Step 1: Create the AuraDefinitions module**

Create `src/shared/AuraDefinitions.luau`:

```lua
local AuraDefinitions = {}

export type AuraConfig = {
	torsoColor: ColorSequence,
	torsoSpeed: NumberRange,
	torsoRate: number,
	torsoLifetime: NumberRange,
	torsoSize: NumberSequence,
	torsoSpread: Vector2,
	groundColor: ColorSequence,
	groundRate: number,
	lightColor: Color3,
	lightBrightness: number,
}

local definitions: { [string]: AuraConfig } = {
	hot_headed_hero = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 30)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30, 10)),
		}),
		torsoSpeed = NumberRange.new(3, 6),
		torsoRate = 18,
		torsoLifetime = NumberRange.new(0.4, 0.9),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(25, 25),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 10)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(255, 100, 30),
		lightBrightness = 0.6,
	},

	cool_strategist = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 220, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 170, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 120, 220)),
		}),
		torsoSpeed = NumberRange.new(1, 3),
		torsoRate = 15,
		torsoLifetime = NumberRange.new(0.8, 1.4),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(40, 40),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 150, 230)),
		}),
		groundRate = 8,
		lightColor = Color3.fromRGB(100, 170, 255),
		lightBrightness = 0.4,
	},

	lone_wolf = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 180)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 50, 140)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 80)),
		}),
		torsoSpeed = NumberRange.new(0.5, 2),
		torsoRate = 12,
		torsoLifetime = NumberRange.new(1.0, 1.5),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(50, 50),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 60, 160)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 30, 100)),
		}),
		groundRate = 8,
		lightColor = Color3.fromRGB(100, 60, 160),
		lightBrightness = 0.3,
	},

	gentle_protector = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 255, 160)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 220, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 80)),
		}),
		torsoSpeed = NumberRange.new(1, 3),
		torsoRate = 14,
		torsoLifetime = NumberRange.new(0.8, 1.3),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(35, 35),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 230, 140)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 180, 100)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(80, 220, 120),
		lightBrightness = 0.4,
	},

	chaotic_wildcard = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(220, 80, 255)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(180, 50, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 20, 200)),
		}),
		torsoSpeed = NumberRange.new(4, 8),
		torsoRate = 20,
		torsoLifetime = NumberRange.new(0.3, 0.7),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.3, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(60, 60),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 220)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 40, 255)),
		}),
		groundRate = 12,
		lightColor = Color3.fromRGB(200, 80, 255),
		lightBrightness = 0.5,
	},

	silent_powerhouse = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 225, 240)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 190, 210)),
		}),
		torsoSpeed = NumberRange.new(1.5, 4),
		torsoRate = 16,
		torsoLifetime = NumberRange.new(0.5, 1.0),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.4, 0.7),
			NumberSequenceKeypoint.new(0.8, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(30, 30),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 240, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 210, 230)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(230, 235, 255),
		lightBrightness = 0.5,
	},

	loyal_companion = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 80)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 100, 30)),
		}),
		torsoSpeed = NumberRange.new(1.5, 3.5),
		torsoRate = 14,
		torsoLifetime = NumberRange.new(0.6, 1.2),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(30, 30),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 120, 40)),
		}),
		groundRate = 8,
		lightColor = Color3.fromRGB(255, 150, 60),
		lightBrightness = 0.4,
	},

	wise_mentor = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 160, 40)),
		}),
		torsoSpeed = NumberRange.new(1, 2.5),
		torsoRate = 12,
		torsoLifetime = NumberRange.new(0.8, 1.5),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(45, 45),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 180, 60)),
		}),
		groundRate = 8,
		lightColor = Color3.fromRGB(255, 210, 80),
		lightBrightness = 0.5,
	},

	rebel_with_a_cause = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 30, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 15, 15)),
		}),
		torsoSpeed = NumberRange.new(3, 6),
		torsoRate = 18,
		torsoLifetime = NumberRange.new(0.4, 0.8),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(20, 20),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 40, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 20, 15)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(200, 40, 30),
		lightBrightness = 0.5,
	},

	cheerful_optimist = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 30)),
		}),
		torsoSpeed = NumberRange.new(2, 5),
		torsoRate = 16,
		torsoLifetime = NumberRange.new(0.5, 1.0),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.3, 0.7),
			NumberSequenceKeypoint.new(0.7, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(40, 40),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 40)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(255, 230, 60),
		lightBrightness = 0.5,
	},
}

function AuraDefinitions.get(archetypeId: string): AuraConfig?
	return definitions[archetypeId]
end

return AuraDefinitions
```

- [ ] **Step 2: Verify module loads without errors**

Run: Play in Roblox Studio, check Output window.
Expected: No errors mentioning AuraDefinitions.

- [ ] **Step 3: Commit**

```bash
git add src/shared/AuraDefinitions.luau
git commit -m "feat: add AuraDefinitions module with particle configs for all 10 archetypes"
```

---

### Task 3: Create AuraController client script

**Files:**
- Create: `src/client/AuraController.client.luau`

Listens for `LeaderboardUpdate` events, tracks archetype per player, attaches/removes particle emitters and lights on characters, handles respawns.

- [ ] **Step 1: Create the AuraController script**

Create `src/client/AuraController.client.luau`:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local AuraDefinitions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraDefinitions"))

local AURA_TAG = "AuraEffect"
local GROUND_PART_NAME = "AuraGroundPart"

-- Cache: userId -> archetypeId
local playerAuras: { [number]: string } = {}

-- Cache: userId -> { RBXScriptConnection } for CharacterAdded listeners
local respawnConnections: { [number]: RBXScriptConnection } = {}

local function removeAura(character: Model)
	if not character then
		return
	end

	-- Remove all tagged aura instances
	for _, descendant in character:GetDescendants() do
		if descendant:GetAttribute(AURA_TAG) then
			descendant:Destroy()
		end
	end

	-- Remove ground part
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

	-- Remove any existing aura first
	removeAura(character)

	-- === Torso ParticleEmitter ===
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

	-- === PointLight ===
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "AuraLight"
	pointLight.Color = config.lightColor
	pointLight.Brightness = config.lightBrightness
	pointLight.Range = 10
	pointLight.Shadows = false
	pointLight:SetAttribute(AURA_TAG, true)
	pointLight.Parent = rootPart

	-- === Ground Ring ===
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

	-- Weld ground part to root, offset down to feet
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
		-- Character still loading, wait briefly
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
	-- Disconnect old listener if it exists
	if respawnConnections[player.UserId] then
		respawnConnections[player.UserId]:Disconnect()
	end

	respawnConnections[player.UserId] = player.CharacterAdded:Connect(function(character)
		-- Wait for character to fully load
		task.wait(0.5)
		if playerAuras[player.UserId] then
			applyAura(character, playerAuras[player.UserId])
		end
	end)
end

-- Listen for leaderboard updates (carries archetype data for all players)
local leaderboardRemote = Remotes.get("LeaderboardUpdate") :: RemoteEvent
leaderboardRemote.OnClientEvent:Connect(function(data: { { userId: number, name: string, archetypeId: string, archetypeName: string } })
	for _, entry in data do
		local oldArchetype = playerAuras[entry.userId]
		local newArchetype = entry.archetypeId

		if oldArchetype ~= newArchetype then
			playerAuras[entry.userId] = newArchetype

			-- Remove old aura if player has a character
			local player = Players:GetPlayerByUserId(entry.userId)
			if player and player.Character then
				removeAura(player.Character)
			end

			-- Apply new aura
			if newArchetype ~= "" then
				applyAuraToPlayer(entry.userId)
			end
		end
	end

	-- Setup respawn listeners for all players with auras
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

-- Setup respawn listener for all current players
for _, player in Players:GetPlayers() do
	setupRespawnListener(player)
end

-- Listen for new players joining
Players.PlayerAdded:Connect(function(player: Player)
	setupRespawnListener(player)
end)
```

- [ ] **Step 2: Test in Roblox Studio**

Run: Play in Roblox Studio. Complete the quiz. After getting a result, check:
1. Output window — no errors
2. Character should have visible particle effects (torso + ground)
3. PointLight should be visible (subtle glow around character)

- [ ] **Step 3: Test respawn**

Run: While playing, reset character (Esc → Reset Character).
Expected: After respawning, aura re-appears on the new character within ~1 second.

- [ ] **Step 4: Test retake**

Run: Go through the quiz again.
Expected: Old aura is removed, new archetype's aura appears.

- [ ] **Step 5: Commit**

```bash
git add src/client/AuraController.client.luau
git commit -m "feat: add AuraController with torso particles, ground ring, and point light per archetype"
```
