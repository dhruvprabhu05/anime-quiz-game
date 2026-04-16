# Spin Wheel Aura System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace archetype-based auras with a gacha spin wheel — players earn/buy spins, win auras of varying rarities, manage inventory, and craft missing auras with shards.

**Architecture:** Server-authoritative spin rolls with client-side wheel animation. Shared rarity module defines drop tables. New SpinHandler server script manages rolls, shards, and crafting. InventoryUI replaces AuraSelectUI. DataStoreManager gets new fields for aura inventory, shards, and free spins. MonetizationHandler processes spin purchases.

**Tech Stack:** Roblox Luau, Rojo, ParticleEmitter, TweenService, DataStoreService, MarketplaceService

---

### Task 1: Create AuraRarities shared module

**Files:**
- Create: `src/shared/AuraRarities.luau`

This is the data backbone — rarity definitions, drop rates, shard values, craft costs, and aura-to-rarity mapping. All other files depend on this.

- [ ] **Step 1: Create the AuraRarities module**

Create `src/shared/AuraRarities.luau`:

```lua
local AuraRarities = {}

export type RarityInfo = {
	name: string,
	color: Color3,
	dropRate: number,
	shardValue: number,
	craftCost: number,
	auras: { string },
}

local rarities: { RarityInfo } = {
	{
		name = "Common",
		color = Color3.fromRGB(200, 200, 200),
		dropRate = 0.40,
		shardValue = 1,
		craftCost = 5,
		auras = { "gentle_protector", "loyal_companion", "cheerful_optimist" },
	},
	{
		name = "Uncommon",
		color = Color3.fromRGB(80, 220, 100),
		dropRate = 0.25,
		shardValue = 3,
		craftCost = 10,
		auras = { "cool_strategist", "wise_mentor", "silent_powerhouse" },
	},
	{
		name = "Rare",
		color = Color3.fromRGB(60, 130, 255),
		dropRate = 0.18,
		shardValue = 5,
		craftCost = 20,
		auras = { "hot_headed_hero", "rebel_with_a_cause" },
	},
	{
		name = "Epic",
		color = Color3.fromRGB(180, 60, 255),
		dropRate = 0.12,
		shardValue = 10,
		craftCost = 40,
		auras = { "lone_wolf" },
	},
	{
		name = "Legendary",
		color = Color3.fromRGB(255, 200, 50),
		dropRate = 0.045,
		shardValue = 25,
		craftCost = 100,
		auras = { "chaotic_wildcard" },
	},
	{
		name = "Secret",
		color = Color3.fromRGB(255, 255, 255),
		dropRate = 0.005,
		shardValue = 50,
		craftCost = 200,
		auras = { "anime_transformation" },
	},
}

-- Lookup: auraId -> RarityInfo
local auraToRarity: { [string]: RarityInfo } = {}
for _, rarity in rarities do
	for _, auraId in rarity.auras do
		auraToRarity[auraId] = rarity
	end
end

AuraRarities.list = rarities

function AuraRarities.getRarityForAura(auraId: string): RarityInfo?
	return auraToRarity[auraId]
end

function AuraRarities.getAllAuraIds(): { string }
	local ids = {}
	for _, rarity in rarities do
		for _, auraId in rarity.auras do
			table.insert(ids, auraId)
		end
	end
	return ids
end

-- Weighted random roll. Returns { auraId: string, rarity: RarityInfo }
function AuraRarities.roll(): { auraId: string, rarity: RarityInfo }
	local roll = math.random()
	local cumulative = 0

	for _, rarity in rarities do
		cumulative += rarity.dropRate
		if roll <= cumulative then
			local auraId = rarity.auras[math.random(1, #rarity.auras)]
			return { auraId = auraId, rarity = rarity }
		end
	end

	-- Fallback (should never happen)
	local last = rarities[#rarities]
	return { auraId = last.auras[1], rarity = last }
end

return AuraRarities
```

- [ ] **Step 2: Commit**

```bash
git add src/shared/AuraRarities.luau
git commit -m "feat: add AuraRarities module with drop table, shard values, and weighted roll"
```

---

### Task 2: Update DataStoreManager with new fields

**Files:**
- Modify: `src/server/DataStoreManager.luau`

Add `unlockedAuras`, `shards`, `freeSpinsAvailable` fields. Add helper functions for the spin system. Migrate existing data.

- [ ] **Step 1: Update the PlayerData type and defaults**

In `src/server/DataStoreManager.luau`, replace the type and defaults:

```lua
export type PlayerData = {
	currentArchetype: string,
	unlockedArchetypes: { string },
	selectedAura: string,
	unlockedAuras: { string },
	shards: number,
	freeSpinsAvailable: number,
}

local DEFAULT_DATA: PlayerData = {
	currentArchetype = "",
	unlockedArchetypes = {},
	selectedAura = "",
	unlockedAuras = {},
	shards = 0,
	freeSpinsAvailable = 0,
}
```

- [ ] **Step 2: Update the load function migration**

In the `load` function, add migration for new fields after the existing ones:

```lua
data.unlockedAuras = data.unlockedAuras or {}
data.shards = data.shards or 0
data.freeSpinsAvailable = data.freeSpinsAvailable or 0
```

Also update the new player default to include all fields:

```lua
local newData = {
	currentArchetype = DEFAULT_DATA.currentArchetype,
	unlockedArchetypes = {},
	selectedAura = "",
	unlockedAuras = {},
	shards = 0,
	freeSpinsAvailable = 0,
}
```

- [ ] **Step 3: Update setArchetype to award a free spin instead of auto-setting aura**

Replace the `setArchetype` function:

```lua
function DataStoreManager.setArchetype(player: Player, archetypeId: string)
	local data = cache[player.UserId]
	if not data then
		return
	end

	data.currentArchetype = archetypeId

	-- Award a free spin for completing the quiz
	data.freeSpinsAvailable = (data.freeSpinsAvailable or 0) + 1

	-- Add to unlocked archetype collection (for the collection screen)
	local found = false
	for _, id in data.unlockedArchetypes do
		if id == archetypeId then
			found = true
			break
		end
	end
	if not found then
		table.insert(data.unlockedArchetypes, archetypeId)
	end
end
```

- [ ] **Step 4: Replace setSelectedAura to validate against unlockedAuras**

```lua
function DataStoreManager.setSelectedAura(player: Player, auraId: string): boolean
	local data = cache[player.UserId]
	if not data then
		return false
	end

	for _, id in data.unlockedAuras do
		if id == auraId then
			data.selectedAura = auraId
			return true
		end
	end
	return false
end
```

- [ ] **Step 5: Add spin and shard helper functions**

Add these before `clearCache`:

```lua
function DataStoreManager.addAura(player: Player, auraId: string)
	local data = cache[player.UserId]
	if not data then
		return
	end
	if not data.unlockedAuras then
		data.unlockedAuras = {}
	end
	table.insert(data.unlockedAuras, auraId)
end

function DataStoreManager.hasAura(player: Player, auraId: string): boolean
	local data = cache[player.UserId]
	if not data or not data.unlockedAuras then
		return false
	end
	for _, id in data.unlockedAuras do
		if id == auraId then
			return true
		end
	end
	return false
end

function DataStoreManager.addShards(player: Player, amount: number)
	local data = cache[player.UserId]
	if not data then
		return
	end
	data.shards = (data.shards or 0) + amount
end

function DataStoreManager.getShards(player: Player): number
	local data = cache[player.UserId]
	if not data then
		return 0
	end
	return data.shards or 0
end

function DataStoreManager.spendShards(player: Player, amount: number): boolean
	local data = cache[player.UserId]
	if not data then
		return false
	end
	if (data.shards or 0) < amount then
		return false
	end
	data.shards = data.shards - amount
	return true
end

function DataStoreManager.consumeFreeSpin(player: Player): boolean
	local data = cache[player.UserId]
	if not data then
		return false
	end
	if (data.freeSpinsAvailable or 0) <= 0 then
		return false
	end
	data.freeSpinsAvailable = data.freeSpinsAvailable - 1
	return true
end

function DataStoreManager.addFreeSpins(player: Player, count: number)
	local data = cache[player.UserId]
	if not data then
		return
	end
	data.freeSpinsAvailable = (data.freeSpinsAvailable or 0) + count
end
```

- [ ] **Step 6: Commit**

```bash
git add src/server/DataStoreManager.luau
git commit -m "feat: add spin/shard/aura inventory fields and helpers to DataStoreManager"
```

---

### Task 3: Update Remotes with new spin/inventory remotes

**Files:**
- Modify: `src/shared/Remotes.luau`

- [ ] **Step 1: Add new remotes**

Add to `remoteFunctions` array:

```lua
"RequestSpin",
"CraftAura",
"LoadInventory",
```

Add to `remoteEvents` array:

```lua
"SpinPurchaseComplete",
```

- [ ] **Step 2: Commit**

```bash
git add src/shared/Remotes.luau
git commit -m "feat: add spin, craft, and inventory remotes"
```

---

### Task 4: Create SpinHandler server script

**Files:**
- Create: `src/server/SpinHandler.server.luau`

Handles RequestSpin, CraftAura, LoadInventory, and spin purchase processing. Server-authoritative rolls.

- [ ] **Step 1: Create SpinHandler**

Create `src/server/SpinHandler.server.luau`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local AuraRarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraRarities"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Perform a spin roll for a player
local function doSpin(player: Player): { auraId: string, rarityName: string, rarityColor: { number }, isNew: boolean, shardsAwarded: number }
	local result = AuraRarities.roll()
	local auraId = result.auraId
	local rarity = result.rarity

	local isNew = not DataStoreManager.hasAura(player, auraId)
	local shardsAwarded = 0

	if isNew then
		DataStoreManager.addAura(player, auraId)
	else
		shardsAwarded = rarity.shardValue
		DataStoreManager.addShards(player, shardsAwarded)
	end

	DataStoreManager.save(player)

	return {
		auraId = auraId,
		rarityName = rarity.name,
		rarityColor = { rarity.color.R * 255, rarity.color.G * 255, rarity.color.B * 255 },
		isNew = isNew,
		shardsAwarded = shardsAwarded,
	}
end

-- RequestSpin: consume a free spin and roll
local requestSpinRemote = Remotes.get("RequestSpin") :: RemoteFunction
requestSpinRemote.OnServerInvoke = function(player: Player)
	local consumed = DataStoreManager.consumeFreeSpin(player)
	if not consumed then
		return nil -- no free spins available
	end
	return doSpin(player)
end

-- CraftAura: spend shards to unlock a specific aura
local craftAuraRemote = Remotes.get("CraftAura") :: RemoteFunction
craftAuraRemote.OnServerInvoke = function(player: Player, auraId: string)
	if type(auraId) ~= "string" then
		return { success = false, reason = "invalid" }
	end

	-- Check aura exists
	local rarity = AuraRarities.getRarityForAura(auraId)
	if not rarity then
		return { success = false, reason = "invalid" }
	end

	-- Check not already owned
	if DataStoreManager.hasAura(player, auraId) then
		return { success = false, reason = "already_owned" }
	end

	-- Check and spend shards
	if not DataStoreManager.spendShards(player, rarity.craftCost) then
		return { success = false, reason = "not_enough_shards" }
	end

	DataStoreManager.addAura(player, auraId)
	DataStoreManager.save(player)

	return { success = true }
end

-- LoadInventory: return all inventory data to client
local loadInventoryRemote = Remotes.get("LoadInventory") :: RemoteFunction
loadInventoryRemote.OnServerInvoke = function(player: Player)
	local data = DataStoreManager.getCached(player)
	if not data then
		data = DataStoreManager.load(player)
	end

	return {
		unlockedAuras = data.unlockedAuras or {},
		selectedAura = data.selectedAura or "",
		shards = data.shards or 0,
		freeSpinsAvailable = data.freeSpinsAvailable or 0,
	}
end

-- Track pending spin purchases per player (for purchase callback)
local pendingSpinPurchases: { [number]: number } = {} -- userId -> spins to award

-- Called by MonetizationHandler when a spin purchase is confirmed
-- We expose this as a module function via a BindableEvent
local spinPurchaseBindable = Instance.new("BindableEvent")
spinPurchaseBindable.Name = "SpinPurchaseEvent"
spinPurchaseBindable.Parent = game:GetService("ServerScriptService")

spinPurchaseBindable.Event:Connect(function(player: Player, spinCount: number)
	DataStoreManager.addFreeSpins(player, spinCount)
	DataStoreManager.save(player)

	-- Notify the client that spins were added
	local spinPurchaseRemote = Remotes.get("SpinPurchaseComplete") :: RemoteEvent
	spinPurchaseRemote:FireClient(player, spinCount)
end)
```

- [ ] **Step 2: Commit**

```bash
git add src/server/SpinHandler.server.luau
git commit -m "feat: add SpinHandler with weighted roll, crafting, and inventory loading"
```

---

### Task 5: Update MonetizationHandler for spin purchases

**Files:**
- Modify: `src/server/MonetizationHandler.server.luau`

Add spin product IDs (placeholders until user provides real IDs). Handle in ProcessReceipt. Remove ad-related code if any.

- [ ] **Step 1: Add spin product IDs and update ProcessReceipt**

Add after the existing product ID declarations:

```lua
local BUY_1_SPIN_PRODUCT_ID = 0  -- Developer Product: 1 spin for 10 Robux
local BUY_5_SPINS_PRODUCT_ID = 0 -- Developer Product: 5 spins for 40 Robux
```

Add to ProcessReceipt (inside the function, after the skip timer check):

```lua
if receiptInfo.ProductId == BUY_1_SPIN_PRODUCT_ID then
	local spinBindable = game:GetService("ServerScriptService"):WaitForChild("SpinPurchaseEvent")
	spinBindable:Fire(player, 1)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

if receiptInfo.ProductId == BUY_5_SPINS_PRODUCT_ID then
	local spinBindable = game:GetService("ServerScriptService"):WaitForChild("SpinPurchaseEvent")
	spinBindable:Fire(player, 5)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
```

Also expose the spin product IDs to the client (add to the idsFolder):

```lua
local buy1SpinValue = Instance.new("IntValue")
buy1SpinValue.Name = "Buy1SpinProductId"
buy1SpinValue.Value = BUY_1_SPIN_PRODUCT_ID
buy1SpinValue.Parent = idsFolder

local buy5SpinsValue = Instance.new("IntValue")
buy5SpinsValue.Name = "Buy5SpinsProductId"
buy5SpinsValue.Value = BUY_5_SPINS_PRODUCT_ID
buy5SpinsValue.Parent = idsFolder
```

- [ ] **Step 2: Commit**

```bash
git add src/server/MonetizationHandler.server.luau
git commit -m "feat: add spin purchase product handling to MonetizationHandler"
```

---

### Task 6: Remove ad button from TimerUI

**Files:**
- Modify: `src/client/TimerUI.luau`

- [ ] **Step 1: Remove the ad button**

Find and delete the entire "Watch Ad" button block — the TextButton creation, UICorner, applyDarkGlass, addNeonButton, and the click handler. Shift the GamePass button up to fill the gap (change its Y position from 0.71 to 0.61).

- [ ] **Step 2: Commit**

```bash
git add src/client/TimerUI.luau
git commit -m "fix: remove ad skip button from timer screen"
```

---

### Task 7: Add anime_transformation to AuraDefinitions

**Files:**
- Modify: `src/shared/AuraDefinitions.luau`

- [ ] **Step 1: Add the anime_transformation config**

Add a new entry to the `definitions` table with extreme rainbow-cycling particles:

```lua
anime_transformation = {
	torsoColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(100, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	}),
	torsoSpeed = NumberRange.new(5, 10),
	torsoRate = 40,
	torsoLifetime = NumberRange.new(0.5, 1.2),
	torsoSize = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(0.3, 2.0),
		NumberSequenceKeypoint.new(0.7, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	}),
	torsoSpread = Vector2.new(60, 60),
	groundColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 100)),
	}),
	groundRate = 20,
	lightColor = Color3.fromRGB(255, 220, 255),
	lightBrightness = 1.0,
},
```

- [ ] **Step 2: Commit**

```bash
git add src/shared/AuraDefinitions.luau
git commit -m "feat: add anime_transformation aura config with rainbow cycling"
```

---

### Task 8: Update AuraController for anime_transformation special case

**Files:**
- Modify: `src/client/AuraController.client.luau`

The anime_transformation needs special handling: glowing eyes (BillboardGui on head), spiky hair effect (another BillboardGui), and the overhead tag shows "[???]" in rainbow cycling text. Also update validation to check against `unlockedAuras` from inventory data.

- [ ] **Step 1: Add anime_transformation special rendering**

After the existing `applyAura` function's ground glow section, add a check:

```lua
-- === SECRET: Anime Transformation extras ===
if archetypeId == "anime_transformation" then
	-- Glowing eyes overlay on head
	local head = character:FindFirstChild("Head")
	if head then
		local eyeGui = Instance.new("BillboardGui")
		eyeGui.Name = "AnimeEyes"
		eyeGui.Size = UDim2.new(1.5, 0, 0.6, 0)
		eyeGui.StudsOffset = Vector3.new(0, 0.2, -0.6)
		eyeGui.AlwaysOnTop = false
		eyeGui.ZIndex = 5
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

		-- Cycle eye colors
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
```

- [ ] **Step 2: Update the leaderboard listener to use LoadInventory data for aura validation**

In the `leaderboardRemote.OnClientEvent` handler, the aura system should still work the same — it applies whatever `selectedAura` the server broadcasts. No validation change needed client-side since the server already validates in `SelectAura`.

- [ ] **Step 3: Commit**

```bash
git add src/client/AuraController.client.luau
git commit -m "feat: add anime_transformation special effects (glowing eyes, color cycling)"
```

---

### Task 9: Create SpinWheelUI

**Files:**
- Create: `src/client/SpinWheelUI.luau`

The animated spin wheel screen. Shows wheel segments, spin button, buy buttons, result reveal.

- [ ] **Step 1: Create SpinWheelUI module**

Create `src/client/SpinWheelUI.luau`. This is a large file — the key sections are:

1. **build(screenGui, spinData, onBack, onInventory)** — creates the full screen
2. **Wheel rendering** — 11 colored segments in a circle using rotated frames
3. **Spin animation** — rotates the wheel for ~4s, easing to land on server result
4. **Result reveal** — rarity flash, name display, NEW! or shard count
5. **Buy buttons** — prompt MarketplaceService purchases

The wheel uses a rotating container frame. Each segment is a colored frame at a specific rotation angle. The spin animation tweens the container's Rotation property.

Key data the module receives:
- `spinData.freeSpinsAvailable` — from LoadInventory
- `spinData.buy1SpinProductId` — from MonetizationIds
- `spinData.buy5SpinsProductId` — from MonetizationIds

Key callbacks:
- Calls `Remotes.get("RequestSpin"):InvokeServer()` to get roll result
- Calls `MarketplaceService:PromptProductPurchase()` for buy buttons
- Listens for `SpinPurchaseComplete` event to update spin count

The full implementation should follow the dark neon JJK aesthetic using UIEffects.COLORS, addDigitalParticles, addNeonButton, addNeonPulse, applyDarkGlass, and addScanLine.

The wheel segments should be colored by rarity. The spin button should be neon cyan. Buy buttons should be neon gold. Result reveal should flash the rarity color full-screen briefly.

- [ ] **Step 2: Test in Studio**

Play in Studio, complete a quiz, click SPIN WHEEL on results screen. Verify:
- Wheel displays with colored segments
- SPIN button works when free spins > 0
- Wheel animates and lands on the server result
- Result shows correct rarity color, aura name, NEW!/shards

- [ ] **Step 3: Commit**

```bash
git add src/client/SpinWheelUI.luau
git commit -m "feat: add SpinWheelUI with animated wheel, buy buttons, and result reveal"
```

---

### Task 10: Create InventoryUI (replaces AuraSelectUI)

**Files:**
- Create: `src/client/InventoryUI.luau`
- Delete: `src/client/AuraSelectUI.luau`

Grid of all 11 auras with rarity badges, equip/craft buttons, shard balance display.

- [ ] **Step 1: Create InventoryUI module**

Create `src/client/InventoryUI.luau`:

Function signature: `InventoryUI.build(screenGui, inventoryData, onBack)`

Where `inventoryData` = `{ unlockedAuras: {string}, selectedAura: string, shards: number }`

The grid shows all 11 auras (from AuraRarities.getAllAuraIds()). Each card shows:
- Owned: aura name, rarity badge (colored by rarity), EQUIP/EQUIPPED button
- Not owned: "???", rarity color border, "CRAFT (X shards)" button if affordable, dimmed otherwise
- Shard balance at top: "SHARDS: X" in neon gold

Uses the dark neon JJK aesthetic. Cards use applyDarkGlass, neon borders per rarity color. Equipped card gets addNeonPulse.

EQUIP calls `Remotes.get("SelectAura"):InvokeServer(auraId)`.
CRAFT calls `Remotes.get("CraftAura"):InvokeServer(auraId)`, then rebuilds UI on success.

Archetype display names come from `Archetypes.getById(auraId)` for the 10 archetype auras. The anime_transformation uses "Anime Transformation" as its display name (hardcoded).

- [ ] **Step 2: Delete AuraSelectUI**

```bash
rm src/client/AuraSelectUI.luau
```

- [ ] **Step 3: Test in Studio**

Open inventory from welcome screen. Verify:
- All 11 auras shown
- Owned auras have EQUIP button
- Unowned auras show craft cost
- Shard balance displays correctly
- Equipping works, crafting works

- [ ] **Step 4: Commit**

```bash
git add src/client/InventoryUI.luau
git rm src/client/AuraSelectUI.luau
git commit -m "feat: add InventoryUI with equip/craft, replace AuraSelectUI"
```

---

### Task 11: Update UIController to wire up new screens

**Files:**
- Modify: `src/client/UIController.client.luau`

Replace AuraSelectUI with InventoryUI and SpinWheelUI. Rename CHANGE AURA to INVENTORY. Add SPIN WHEEL to flow.

- [ ] **Step 1: Update requires**

Replace:
```lua
local AuraSelectUI = require(script.Parent:WaitForChild("AuraSelectUI"))
```
With:
```lua
local SpinWheelUI = require(script.Parent:WaitForChild("SpinWheelUI"))
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI"))
```

- [ ] **Step 2: Add spinwheel and inventory to showScreen**

Add cases in the showScreen function:
```lua
elseif name == "spinwheel" then
	local frame = screenGui:FindFirstChild("SpinWheelFrame")
	if frame then
		frame.Visible = true
	end
elseif name == "inventory" then
	local frame = screenGui:FindFirstChild("InventoryFrame")
	if frame then
		frame.Visible = true
	end
```

Remove the `auraselect` case.

- [ ] **Step 3: Replace showAuraSelect with showInventory and showSpinWheel**

Replace the `showAuraSelect` function with:

```lua
function showInventory()
	local loadRemote = Remotes.get("LoadInventory") :: RemoteFunction
	local data = loadRemote:InvokeServer()
	InventoryUI.build(screenGui, data, function()
		showScreen("welcome")
	end)
	showScreen("inventory")
end

function showSpinWheel()
	local loadRemote = Remotes.get("LoadInventory") :: RemoteFunction
	local data = loadRemote:InvokeServer()

	local idsFolder = ReplicatedStorage:WaitForChild("MonetizationIds")
	local spinData = {
		freeSpinsAvailable = data.freeSpinsAvailable,
		buy1SpinProductId = idsFolder:WaitForChild("Buy1SpinProductId").Value,
		buy5SpinsProductId = idsFolder:WaitForChild("Buy5SpinsProductId").Value,
	}

	SpinWheelUI.build(screenGui, spinData, function()
		showScreen("welcome")
	end, function()
		showInventory()
	end)
	showScreen("spinwheel")
end
```

- [ ] **Step 4: Update welcome screen button — rename CHANGE AURA to INVENTORY, add SPIN WHEEL**

In `buildWelcomeScreen`, rename the aura button text to `"[ INVENTORY ]"` and change its click handler to call `showInventory()`.

Add a new SPIN WHEEL button between START QUIZ and INVENTORY:

```lua
local spinButton = makeMenuButton(frame, "[ SPIN WHEEL ]", 0.56, C.neonGold)
```

Shift the other buttons down: INVENTORY to 0.64, COLLECTION to 0.72, EXPLORE HUB to 0.80.

Wire up: `spinButton.MouseButton1Click:Connect(function() showSpinWheel() end)`

- [ ] **Step 5: Update CLOSEABLE_SCREENS**

Replace `auraselect` with `spinwheel` and `inventory`:

```lua
local CLOSEABLE_SCREENS = { welcome = true, results = true, collection = true, spinwheel = true, inventory = true }
```

Wait — we removed the close button. Remove CLOSEABLE_SCREENS entirely if it's still referenced, or just leave it if nothing reads it.

- [ ] **Step 6: Commit**

```bash
git add src/client/UIController.client.luau
git commit -m "feat: wire up SpinWheelUI and InventoryUI, replace AuraSelectUI references"
```

---

### Task 12: Update ResultsUI — add SPIN WHEEL button

**Files:**
- Modify: `src/client/ResultsUI.luau`

Add a `onSpinWheel` callback parameter and a SPIN WHEEL button.

- [ ] **Step 1: Update function signature**

Change:
```lua
function ResultsUI.build(screenGui, archetypeId, onRetake, onCollection, onHub)
```
To:
```lua
function ResultsUI.build(screenGui, archetypeId, onRetake, onCollection, onHub, onSpinWheel)
```

- [ ] **Step 2: Add SPIN WHEEL button**

Add a 4th button alongside the existing 3. Rearrange positions to fit 4 buttons:
- RETAKE QUIZ at x=0.03
- COLLECTION at x=0.27
- SPIN WHEEL at x=0.51 (neon gold, prominent)
- EXPLORE HUB at x=0.75

Each button width: 0.2

The SPIN WHEEL button uses neonGold color to draw attention.

Wire up: `spinButton.MouseButton1Click:Connect(function() if onSpinWheel then onSpinWheel() end end)`

- [ ] **Step 3: Update the call in UIController**

In `showResults`, pass the spin wheel callback:

```lua
function showResults(archetypeId: string)
	ResultsUI.build(screenGui, archetypeId, function()
		onStartQuiz()
	end, function()
		showCollectionScreen(false)
	end, function()
		enterHub()
	end, function()
		showSpinWheel()
	end)
	showScreen("results")
end
```

- [ ] **Step 4: Commit**

```bash
git add src/client/ResultsUI.luau src/client/UIController.client.luau
git commit -m "feat: add SPIN WHEEL button to results screen"
```

---

### Task 13: End-to-end testing

- [ ] **Step 1: Test full quiz → spin flow**

Play in Studio. Complete a quiz. After results, click SPIN WHEEL. Verify:
- Free spins counter shows 1
- Wheel spins and lands on a result
- Result shows rarity color and aura name
- If new: aura added to inventory
- If duplicate: shards awarded

- [ ] **Step 2: Test inventory**

Open INVENTORY from welcome screen. Verify:
- Newly won aura shows as owned with EQUIP button
- Other auras show as locked with craft cost
- Equipping an aura works (character aura changes)
- Shard balance shows correctly

- [ ] **Step 3: Test crafting**

If you have enough shards (may need multiple quiz completions), craft an aura. Verify it unlocks.

- [ ] **Step 4: Test spin purchases**

Click Buy 1 Spin (will show purchase prompt — won't work until real product IDs are set). Verify the prompt appears.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: spin wheel aura system complete — wheel, inventory, rarities, shards, crafting"
```
