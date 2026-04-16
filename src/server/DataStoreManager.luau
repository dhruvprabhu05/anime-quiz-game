local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local playerStore = DataStoreService:GetDataStore("PlayerArchetypeData_v1")

export type PlayerData = {
	currentArchetype: string,       -- archetype id or "" if none
	unlockedArchetypes: { string }, -- list of archetype ids
}

local DEFAULT_DATA: PlayerData = {
	currentArchetype = "",
	unlockedArchetypes = {},
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
		cache[userId] = data
		return data
	end

	-- New player or load failure — use defaults
	local newData = {
		currentArchetype = DEFAULT_DATA.currentArchetype,
		unlockedArchetypes = {},
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

	-- Add to unlocked set if not already there
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

function DataStoreManager.clearCache(player: Player)
	cache[player.UserId] = nil
end

return DataStoreManager
