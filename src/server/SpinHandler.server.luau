local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local AuraRarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraRarities"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

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
	local consumed = DataStoreManager.consumeFreeSpin(player)
	if not consumed then
		return nil
	end
	return doSpin(player)
end

-- CraftAura: spend shards to unlock a specific aura
local craftAuraRemote = Remotes.get("CraftAura") :: RemoteFunction
craftAuraRemote.OnServerInvoke = function(player: Player, auraId: string)
	if type(auraId) ~= "string" then
		return { success = false, reason = "invalid" }
	end

	local rarity = AuraRarities.getRarityForAura(auraId)
	if not rarity then
		return { success = false, reason = "invalid" }
	end

	if DataStoreManager.hasAura(player, auraId) then
		return { success = false, reason = "already_owned" }
	end

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
