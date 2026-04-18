local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local playerStore = DataStoreService:GetDataStore("PlayerArchetypeData_v1")

export type PlayerData = {
	currentArchetype: string,       -- archetype id from latest quiz result
	unlockedArchetypes: { string }, -- list of archetype ids
	selectedAura: string,           -- archetype id for displayed aura (can differ from currentArchetype)
	unlockedAuras: { string },      -- auras won from the spin wheel
	shards: number,                 -- currency for crafting auras
	freeSpinsAvailable: number,     -- spins earned from quizzes
}

local DEFAULT_DATA: PlayerData = {
	currentArchetype = "",
	unlockedArchetypes = {},
	selectedAura = "",
	unlockedAuras = {},
	shards = 0,
	freeSpinsAvailable = 0,
}

local DataStoreManager = {}

-- In-memory cache of loaded player data
local cache: { [number]: PlayerData } = {}

function DataStoreManager.load(player: Player): PlayerData
	local userId = player.UserId
	local success, data = pcall(function()
		return playerStore:GetAsync("player_" .. userId)
	end)

	if success and data then
		-- Ensure all fields exist (migration safety)
		data.currentArchetype = data.currentArchetype or ""
		data.unlockedArchetypes = data.unlockedArchetypes or {}
		data.selectedAura = data.selectedAura or ""
		data.unlockedAuras = data.unlockedAuras or {}
		data.shards = data.shards or 0
		data.freeSpinsAvailable = data.freeSpinsAvailable or 0
		cache[userId] = data
		return data
	end

	-- New player or load failure — use defaults
	local newData = {
		currentArchetype = DEFAULT_DATA.currentArchetype,
		unlockedArchetypes = {},
		selectedAura = "",
		unlockedAuras = {},
		shards = 0,
		freeSpinsAvailable = 0,
	}
	cache[userId] = newData
	return newData
end

function DataStoreManager.save(player: Player): boolean
	local userId = player.UserId
	local data = cache[userId]
	if not data then
		return false
	end

	local success, err = pcall(function()
		playerStore:SetAsync("player_" .. userId, data)
	end)

	if not success then
		warn("[DataStoreManager] Failed to save for " .. player.Name .. ": " .. tostring(err))
	end
	return success
end

function DataStoreManager.getCached(player: Player): PlayerData?
	return cache[player.UserId]
end

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

function DataStoreManager.clearCache(player: Player)
	cache[player.UserId] = nil
end

return DataStoreManager
