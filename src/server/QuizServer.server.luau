local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local QuestionBank = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestionBank"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

local INSTANT_UNLOCK_GAMEPASS_ID = 1797259226

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
local activeSessions: { [Player]: { questionOrder: { number }, answers: { number }, expectedIndex: number, startTime: number, lastAnswerTime: number } } = {}

-- Minimum average seconds per answer to prevent spam.
-- Must stay below the client's answer lock in QuizUI (MIN_READ_SECONDS = 0.4),
-- otherwise honest answers get dropped and the quiz never finishes.
local MIN_ANSWER_INTERVAL = 0.3

-- A session with no accepted answer for this long is treated as abandoned
local STALE_SESSION_SECONDS = 120

-- Server-side quiz cooldown tracking
local quizCompletionTimes: { [number]: number } = {}
local QUIZ_COOLDOWN = 15 * 60 -- 15 minutes

local function getQuizCooldownRemaining(player: Player): number
	local completionTime = quizCompletionTimes[player.UserId]
	if not completionTime then
		return 0
	end
	local remaining = QUIZ_COOLDOWN - (tick() - completionTime)
	return if remaining > 0 then remaining else 0
end

-- Handle StartQuiz: create a new session with shuffled question order
local startQuizRemote = Remotes.get("StartQuiz") :: RemoteFunction
startQuizRemote.OnServerInvoke = function(player: Player)
	-- Prevent starting a new quiz while one is active (unless it has stalled)
	local existingSession = activeSessions[player]
	if existingSession and tick() - existingSession.lastAnswerTime < STALE_SESSION_SECONDS then
		return nil
	end

	-- Enforce server-side cooldown (prevents client-side timer bypass)
	-- GamePass owners bypass cooldown entirely
	if getQuizCooldownRemaining(player) > 0 then
		local ownsPass = false
		local success, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, INSTANT_UNLOCK_GAMEPASS_ID)
		end)
		if success then
			ownsPass = result
		end
		if not ownsPass then
			return nil
		end
	end

	local order = QuestionBank.getShuffledIndices()
	activeSessions[player] = {
		questionOrder = order,
		answers = {},
		expectedIndex = 1,
		startTime = tick(),
		lastAnswerTime = tick(),
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

	-- Rate limit: reject answers submitted too fast
	local now = tick()
	-- Measured from quiz start, not the previous answer, so network jitter that
	-- bunches two answers together can't cause one to be dropped.
	if now - session.startTime < (#session.answers + 1) * MIN_ANSWER_INTERVAL then
		return
	end
	session.lastAnswerTime = now

	table.insert(session.answers, answerIndex)
	session.expectedIndex += 1

	-- If all questions answered, calculate result
	if #session.answers == QuestionBank.getTotalQuestions() then
		local result = calculateResult(session)
		activeSessions[player] = nil

		-- Save result to DataStore
		DataStoreManager.setArchetype(player, result)
		DataStoreManager.save(player)

		-- Record quiz completion time for cooldown enforcement
		quizCompletionTimes[player.UserId] = tick()

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

-- Client can check remaining cooldown
local checkCooldownRemote = Remotes.get("CheckQuizCooldown") :: RemoteFunction
checkCooldownRemote.OnServerInvoke = function(player: Player)
	return getQuizCooldownRemaining(player)
end

-- Listen for timer skip purchases from MonetizationHandler
local timerSkipBindable = Instance.new("BindableEvent")
timerSkipBindable.Name = "QuizTimerSkipEvent"
timerSkipBindable.Parent = ServerScriptService

timerSkipBindable.Event:Connect(function(player: Player)
	-- Subtract 5 minutes from cooldown (shift completion time back by 300s)
	local completionTime = quizCompletionTimes[player.UserId]
	if completionTime then
		quizCompletionTimes[player.UserId] = completionTime - 300
	end
end)

-- Clean up when a player leaves
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	activeSessions[player] = nil
	quizCompletionTimes[player.UserId] = nil
	DataStoreManager.save(player)
	DataStoreManager.clearCache(player)
end)
