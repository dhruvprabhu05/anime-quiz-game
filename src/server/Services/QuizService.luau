--!strict
-- Runs quiz sessions: hands out question orders, collects answers, and scores the result
-- server-side (so exploiters can't pick their title). Players can start a new quiz as soon
-- as they have finished the last one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Archetypes = require(Shared:WaitForChild("Data"):WaitForChild("Archetypes"))
local QuestionBank = require(Shared:WaitForChild("Data"):WaitForChild("QuestionBank"))

local Services = script.Parent
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GamePassService = require(Services:WaitForChild("GamePassService"))

local QUIZ = Config.Quiz

type Session = {
	questionOrder: { number },
	answers: { number },
	startedAt: number,
	lastAnswerAt: number,
}

local sessions: { [Player]: Session } = {}

local QuizService = {}

-- Highest total wins; ties go to the archetype listed first in Data/Archetypes
local function scoreSession(session: Session): string
	local totals: { [string]: number } = {}
	for i, questionIndex in session.questionOrder do
		local question = QuestionBank.getQuestion(questionIndex)
		local answer = question.answers[session.answers[i]]
		for archetypeId, weight in answer.weights do
			totals[archetypeId] = (totals[archetypeId] or 0) + weight
		end
	end

	local bestId, bestScore = Archetypes.list[1].id, -math.huge
	for _, archetype in Archetypes.list do
		local score = totals[archetype.id] or 0
		if score > bestScore then
			bestId, bestScore = archetype.id, score
		end
	end
	return bestId
end

local function finishQuiz(player: Player, session: Session)
	sessions[player] = nil

	local archetypeId = scoreSession(session)
	PlayerDataService.recordResult(player, archetypeId)

	local waitSeconds = if GamePassService.ownsInstantUnlock(player) then 0 else QUIZ.RESULT_WAIT_SECONDS
	Remotes.event(Remotes.Events.QuizResult):FireClient(player, archetypeId, waitSeconds)

	PlayerDataService.save(player)
end

local function startQuiz(player: Player): Remotes.StartQuizResult
	-- One quiz at a time, unless the previous one was abandoned
	local existing = sessions[player]
	if existing and os.clock() - existing.lastAnswerAt < QUIZ.STALE_SESSION_SECONDS then
		return { ok = false }
	end

	local now = os.clock()
	local questionOrder = QuestionBank.getShuffledIndices()
	sessions[player] = { questionOrder = questionOrder, answers = {}, startedAt = now, lastAnswerAt = now }
	return { ok = true, questionOrder = questionOrder }
end

local function isValidAnswerIndex(value: unknown): boolean
	return type(value) == "number" and value % 1 == 0 and value >= 1 and value <= QUIZ.ANSWERS_PER_QUESTION
end

local function submitAnswer(player: Player, answerIndex: unknown)
	local session = sessions[player]
	if not session or not isValidAnswerIndex(answerIndex) then
		return
	end
	local answered = #session.answers
	if answered >= #session.questionOrder then
		return
	end

	-- Rate limit by average pace since the start, so network jitter that bunches two
	-- answers together can't drop one (which would leave the quiz unfinishable)
	local now = os.clock()
	if now - session.startedAt < (answered + 1) * QUIZ.MIN_SECONDS_PER_ANSWER then
		return
	end

	session.lastAnswerAt = now
	table.insert(session.answers, answerIndex :: number)
	if #session.answers == #session.questionOrder then
		finishQuiz(player, session)
	end
end

-- Called when a "Skip 5 Minutes" purchase is granted: tells the player's timer to jump ahead
function QuizService.applyTimerSkip(player: Player)
	Remotes.event(Remotes.Events.TimerSkipGranted):FireClient(player, QUIZ.SKIP_SECONDS)
end

function QuizService.init()
	Remotes.func(Remotes.Functions.StartQuiz).OnServerInvoke = startQuiz
	Remotes.event(Remotes.Events.SubmitAnswer).OnServerEvent:Connect(submitAnswer)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return QuizService
