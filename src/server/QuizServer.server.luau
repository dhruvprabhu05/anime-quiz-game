local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local QuestionBank = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestionBank"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Initialize remotes (only one server script should call this)
Remotes.init()

-- Load player data on join
game:GetService("Players").PlayerAdded:Connect(function(player: Player)
	DataStoreManager.load(player)
end)

-- Load data for players already in the game (in case script loads late)
for _, player in game:GetService("Players"):GetPlayers() do
	task.spawn(function()
		DataStoreManager.load(player)
	end)
end

-- Handle LoadPlayerData request from client
local loadPlayerDataRemote = Remotes.get("LoadPlayerData") :: RemoteFunction
loadPlayerDataRemote.OnServerInvoke = function(player: Player)
	local data = DataStoreManager.getCached(player)
	if not data then
		data = DataStoreManager.load(player)
	end
	return data
end

-- Track each player's active quiz session
local activeSessions: { [Player]: { questionOrder: { number }, answers: { number }, expectedIndex: number } } = {}

-- Handle StartQuiz: create a new session with shuffled question order
local startQuizRemote = Remotes.get("StartQuiz") :: RemoteFunction
startQuizRemote.OnServerInvoke = function(player: Player)
	local order = QuestionBank.getShuffledIndices()
	activeSessions[player] = {
		questionOrder = order,
		answers = {},
		expectedIndex = 1,
	}
	return order
end

-- Handle SubmitAnswer: record the player's answer for the current question
local submitAnswerRemote = Remotes.get("SubmitAnswer") :: RemoteEvent
submitAnswerRemote.OnServerEvent:Connect(function(player: Player, answerIndex: number)
	local session = activeSessions[player]
	if not session then
		return
	end

	-- Validate answer index (1-4)
	if type(answerIndex) ~= "number" or answerIndex < 1 or answerIndex > 4 or answerIndex ~= math.floor(answerIndex) then
		return
	end

	-- Only accept the next expected answer (prevents duplicate/out-of-order submissions)
	if session.expectedIndex > QuestionBank.getTotalQuestions() then
		return
	end

	table.insert(session.answers, answerIndex)
	session.expectedIndex += 1

	-- If all questions answered, calculate result
	if #session.answers == QuestionBank.getTotalQuestions() then
		local result = calculateResult(session)
		activeSessions[player] = nil

		-- Save result to DataStore
		DataStoreManager.setArchetype(player, result)
		DataStoreManager.save(player)

		-- Notify leaderboard manager
		local resultBindable = ServerScriptService:WaitForChild("PlayerResultEvent")
		resultBindable:Fire(player, result)

		local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
		quizResultRemote:FireClient(player, result)
	end
end)

function calculateResult(session: { questionOrder: { number }, answers: { number } }): string
	-- Accumulate scores for each archetype
	local scores: { [string]: number } = {}
	for _, id in Archetypes.getIds() do
		scores[id] = 0
	end

	for i, questionIndex in session.questionOrder do
		local answerIndex = session.answers[i]
		if not answerIndex then
			break
		end

		local question = QuestionBank.getQuestion(questionIndex)
		local answer = question.answers[answerIndex]

		for archetypeId, weight in answer.weights do
			scores[archetypeId] = (scores[archetypeId] or 0) + weight
		end
	end

	-- Find the highest scoring archetype
	local bestId = ""
	local bestScore = -1
	for id, score in scores do
		if score > bestScore then
			bestScore = score
			bestId = id
		end
	end

	return bestId
end

-- Clean up when a player leaves
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	activeSessions[player] = nil
	DataStoreManager.save(player)
	DataStoreManager.clearCache(player)
end)
