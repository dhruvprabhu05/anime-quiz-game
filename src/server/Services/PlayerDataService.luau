--!strict
-- Loads, caches and saves each player's collection of titles.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

type PlayerData = Remotes.PlayerData

local store = DataStoreService:GetDataStore(Config.DataStore.NAME)

local cache: { [Player]: PlayerData } = {}
-- Players whose saved data could not be read. Their data is never saved this session,
-- so a temporary DataStore outage can't overwrite a real collection with an empty one.
local loadFailed: { [Player]: boolean } = {}

local PlayerDataService = {}

local function storeKey(player: Player): string
	return Config.DataStore.KEY_PREFIX .. player.UserId
end

function PlayerDataService.load(player: Player): PlayerData
	local ok, saved = pcall(function()
		return store:GetAsync(storeKey(player))
	end)
	if not ok then
		warn(`[PlayerDataService] Could not load data for {player.Name}: {saved}`)
		loadFailed[player] = true
	end

	-- Fields from older versions of the game are kept as they are
	local data: PlayerData = if ok and type(saved) == "table"
		then saved
		else { currentArchetype = "", unlockedArchetypes = {} }
	data.currentArchetype = data.currentArchetype or ""
	data.unlockedArchetypes = data.unlockedArchetypes or {}

	cache[player] = data
	return data
end

function PlayerDataService.get(player: Player): PlayerData
	return cache[player] or PlayerDataService.load(player)
end

function PlayerDataService.save(player: Player)
	local data = cache[player]
	if not data or loadFailed[player] then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(storeKey(player), data)
	end)
	if not ok then
		warn(`[PlayerDataService] Could not save data for {player.Name}: {err}`)
	end
end

-- Records a quiz result: sets it as the current title and adds it to the collection
function PlayerDataService.recordResult(player: Player, archetypeId: string)
	local data = PlayerDataService.get(player)
	data.currentArchetype = archetypeId
	if not table.find(data.unlockedArchetypes, archetypeId) then
		table.insert(data.unlockedArchetypes, archetypeId)
	end
end

local function onPlayerRemoving(player: Player)
	PlayerDataService.save(player)
	cache[player] = nil
	loadFailed[player] = nil
end

function PlayerDataService.init()
	Players.PlayerAdded:Connect(PlayerDataService.load)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerDataService.load, player)
	end

	Remotes.func(Remotes.Functions.LoadPlayerData).OnServerInvoke = PlayerDataService.get

	-- Save everyone if the server shuts down before PlayerRemoving runs
	game:BindToClose(function()
		for player in cache do
			task.spawn(PlayerDataService.save, player)
		end
	end)
end

return PlayerDataService
