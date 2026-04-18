local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local AuraRarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraRarities"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Per-player locks to prevent race conditions on concurrent requests
local spinLock: { [number]: boolean } = {}
local craftLock: { [number]: boolean } = {}

-- Rate limiting: minimum seconds between spin requests
local lastSpinTime: { [number]: number } = {}
local SPIN_COOLDOWN = 0.5

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
		rarityColor = { math.floor(rarity.color.R * 255), math.floor(rarity.color.G * 255), math.floor(rarity.color.B * 255) },
		isNew = isNew,
		shardsAwarded = shardsAwarded,
	}
end

-- RequestSpin: consume a free spin and roll
local requestSpinRemote = Remotes.get("RequestSpin") :: RemoteFunction
requestSpinRemote.OnServerInvoke = function(player: Player)
	-- Rate limit
	local now = tick()
	if (lastSpinTime[player.UserId] or 0) > now - SPIN_COOLDOWN then
		return nil
	end
	lastSpinTime[player.UserId] = now

	-- Lock to prevent race conditions
	if spinLock[player.UserId] then
		return nil
	end
	spinLock[player.UserId] = true

	local consumed = DataStoreManager.consumeFreeSpin(player)
	if not consumed then
		spinLock[player.UserId] = nil
		return nil
	end
	local result = doSpin(player)
	spinLock[player.UserId] = nil
	return result
end

-- RequestBulkSpin: consume 5 free spins and roll all at once
local requestBulkSpinRemote = Remotes.get("RequestBulkSpin") :: RemoteFunction
requestBulkSpinRemote.OnServerInvoke = function(player: Player)
	-- Rate limit
	local now = tick()
	if (lastSpinTime[player.UserId] or 0) > now - SPIN_COOLDOWN then
		return nil
	end
	lastSpinTime[player.UserId] = now

	-- Lock to prevent race conditions
	if spinLock[player.UserId] then
		return nil
	end
	spinLock[player.UserId] = true

	-- Check player has at least 5 spins
	local data = DataStoreManager.getCached(player)
	if not data or (data.freeSpinsAvailable or 0) < 5 then
		spinLock[player.UserId] = nil
		return nil
	end

	-- Consume 5 spins and roll 5 times
	local results = {}
	for i = 1, 5 do
		local consumed = DataStoreManager.consumeFreeSpin(player)
		if not consumed then
			break
		end
		table.insert(results, doSpin(player))
	end

	spinLock[player.UserId] = nil
	return results
end

-- CraftAura: spend shards to unlock a specific aura
local craftAuraRemote = Remotes.get("CraftAura") :: RemoteFunction
craftAuraRemote.OnServerInvoke = function(player: Player, auraId: string)
	if type(auraId) ~= "string" then
		return { success = false, reason = "invalid" }
	end

	-- Lock to prevent race conditions
	if craftLock[player.UserId] then
		return { success = false, reason = "busy" }
	end
	craftLock[player.UserId] = true

	local rarity = AuraRarities.getRarityForAura(auraId)
	if not rarity then
		craftLock[player.UserId] = nil
		return { success = false, reason = "invalid" }
	end

	if DataStoreManager.hasAura(player, auraId) then
		craftLock[player.UserId] = nil
		return { success = false, reason = "already_owned" }
	end

	if not DataStoreManager.spendShards(player, rarity.craftCost) then
		craftLock[player.UserId] = nil
		return { success = false, reason = "not_enough_shards" }
	end

	DataStoreManager.addAura(player, auraId)
	DataStoreManager.save(player)

	craftLock[player.UserId] = nil
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

-- BindableEvent for MonetizationHandler to notify spin purchases
local spinPurchaseBindable = Instance.new("BindableEvent")
spinPurchaseBindable.Name = "SpinPurchaseEvent"
spinPurchaseBindable.Parent = game:GetService("ServerScriptService")

spinPurchaseBindable.Event:Connect(function(player: Player, spinCount: number)
	DataStoreManager.addFreeSpins(player, spinCount)
	DataStoreManager.save(player)

	local spinPurchaseRemote = Remotes.get("SpinPurchaseComplete") :: RemoteEvent
	spinPurchaseRemote:FireClient(player, spinCount)
end)

-- Clean up locks on leave
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	spinLock[player.UserId] = nil
	craftLock[player.UserId] = nil
	lastSpinTime[player.UserId] = nil
end)
