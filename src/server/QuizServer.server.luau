local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local QuestionBank = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestionBank"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

-- Initialize remotes (only one server script should call this)
Remotes.init()

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
end)
