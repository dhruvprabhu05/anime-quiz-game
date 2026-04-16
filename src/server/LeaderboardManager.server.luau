local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Tracks current archetype for every player in the server
local serverArchetypes: { [number]: { name: string, archetypeId: string } } = {}

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

local function broadcastLeaderboard()
	local data = getLeaderboardData()
	local leaderboardRemote = Remotes.get("LeaderboardUpdate") :: RemoteEvent
	leaderboardRemote:FireAllClients(data)
end

local function setOverheadTag(player: Player, archetypeId: string)
	local archetype = Archetypes.getById(archetypeId)
	if not archetype then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	-- Remove existing tag if present
	local existingGui = head:FindFirstChild("ArchetypeTag")
	if existingGui then
		existingGui:Destroy()
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ArchetypeTag"
	billboardGui.Size = UDim2.new(4, 0, 0.8, 0)
	billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = head

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "[" .. archetype.name .. "]"
	textLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = billboardGui
end

-- Helper to get the displayed aura for a player (selectedAura if set, otherwise currentArchetype)
local function getDisplayedAura(player: Player): string
	local data = DataStoreManager.getCached(player)
	if not data then
		return ""
	end
	if data.selectedAura ~= "" then
		return data.selectedAura
	end
	return data.currentArchetype
end

-- When a player joins, load their archetype and register them
Players.PlayerAdded:Connect(function(player: Player)
	-- Wait for DataStore to load (handled by QuizServer)
	task.wait(1)
	local archetypeId = getDisplayedAura(player)

	serverArchetypes[player.UserId] = {
		name = player.Name,
		archetypeId = archetypeId,
	}

	-- Set overhead tag when character spawns
	if archetypeId ~= "" then
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			-- Re-read in case aura changed
			local currentAura = getDisplayedAura(player)
			setOverheadTag(player, currentAura)
		end)
		if player.Character then
			setOverheadTag(player, archetypeId)
		end
	end

	broadcastLeaderboard()
end)

-- Listen for quiz results via BindableEvent from QuizServer
local resultBindable = Instance.new("BindableEvent")
resultBindable.Name = "PlayerResultEvent"
resultBindable.Parent = game:GetService("ServerScriptService")

resultBindable.Event:Connect(function(player: Player, archetypeId: string)
	local displayAura = getDisplayedAura(player)

	serverArchetypes[player.UserId] = {
		name = player.Name,
		archetypeId = displayAura,
	}

	setOverheadTag(player, displayAura)

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		local currentAura = getDisplayedAura(player)
		setOverheadTag(player, currentAura)
	end)

	broadcastLeaderboard()
end)

-- Handle aura selection from client
local selectAuraRemote = Remotes.get("SelectAura") :: RemoteFunction
selectAuraRemote.OnServerInvoke = function(player: Player, archetypeId: string)
	if type(archetypeId) ~= "string" then
		return false
	end

	local success = DataStoreManager.setSelectedAura(player, archetypeId)
	if not success then
		return false
	end

	-- Update server state
	serverArchetypes[player.UserId] = {
		name = player.Name,
		archetypeId = archetypeId,
	}

	-- Update overhead tag
	setOverheadTag(player, archetypeId)

	-- Save and broadcast
	DataStoreManager.save(player)
	broadcastLeaderboard()
	return true
end

-- Handle client requesting current leaderboard
local requestLeaderboardRemote = Remotes.get("RequestLeaderboard") :: RemoteEvent
requestLeaderboardRemote.OnServerEvent:Connect(function(player: Player)
	local data = getLeaderboardData()
	local leaderboardRemote = Remotes.get("LeaderboardUpdate") :: RemoteEvent
	leaderboardRemote:FireClient(player, data)
end)

-- Clean up on leave
Players.PlayerRemoving:Connect(function(player: Player)
	serverArchetypes[player.UserId] = nil
	broadcastLeaderboard()
end)
