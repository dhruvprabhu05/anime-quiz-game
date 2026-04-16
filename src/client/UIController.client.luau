local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuizGameUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Require UI modules
local QuizUI = require(script.Parent:WaitForChild("QuizUI"))
local TimerUI = require(script.Parent:WaitForChild("TimerUI"))
local ResultsUI = require(script.Parent:WaitForChild("ResultsUI"))
local CollectionUI = require(script.Parent:WaitForChild("CollectionUI"))
local LeaderboardUI = require(script.Parent:WaitForChild("LeaderboardUI"))
local InterludePlayer = require(script.Parent:WaitForChild("InterludePlayer"))

-- State
local currentScreen: string = "none"

-- Screen management: hide all, then show one
local function hideAllScreens()
	for _, child in screenGui:GetChildren() do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end
end

local function showScreen(name: string)
	hideAllScreens()
	currentScreen = name

	if name == "welcome" then
		local frame = screenGui:FindFirstChild("WelcomeFrame")
		if frame then
			frame.Visible = true
		end
	elseif name == "quiz" then
		local frame = screenGui:FindFirstChild("QuizFrame")
		if frame then
			frame.Visible = true
		end
	elseif name == "timer" then
		local frame = screenGui:FindFirstChild("TimerFrame")
		if frame then
			frame.Visible = true
		end
	elseif name == "results" then
		local frame = screenGui:FindFirstChild("ResultsFrame")
		if frame then
			frame.Visible = true
		end
	elseif name == "collection" then
		local frame = screenGui:FindFirstChild("CollectionFrame")
		if frame then
			frame.Visible = true
		end
	end
end

-- Build Welcome Screen
local function buildWelcomeScreen()
	local frame = Instance.new("Frame")
	frame.Name = "WelcomeFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.15, 0)
	title.Position = UDim2.new(0.1, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text = "Which Anime Character Are You?"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0.6, 0, 0.06, 0)
	subtitle.Position = UDim2.new(0.2, 0, 0.32, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Answer 24 questions to discover your anime personality archetype!"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 220)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = frame

	local startButton = Instance.new("TextButton")
	startButton.Name = "StartButton"
	startButton.Size = UDim2.new(0.3, 0, 0.08, 0)
	startButton.Position = UDim2.new(0.35, 0, 0.5, 0)
	startButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	startButton.Text = "Start Quiz"
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.TextScaled = true
	startButton.Font = Enum.Font.GothamBold
	startButton.Parent = frame

	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 12)
	corner1.Parent = startButton

	local collectionButton = Instance.new("TextButton")
	collectionButton.Name = "CollectionButton"
	collectionButton.Size = UDim2.new(0.3, 0, 0.08, 0)
	collectionButton.Position = UDim2.new(0.35, 0, 0.62, 0)
	collectionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
	collectionButton.Text = "My Collection"
	collectionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectionButton.TextScaled = true
	collectionButton.Font = Enum.Font.GothamBold
	collectionButton.Parent = frame

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 12)
	corner2.Parent = collectionButton

	startButton.MouseButton1Click:Connect(function()
		onStartQuiz()
	end)

	collectionButton.MouseButton1Click:Connect(function()
		showCollectionScreen(true) -- true = came from welcome, show back button
	end)
end

-- Flow handlers
local currentQuizOrder: { number } = {}
local currentQuizIndex: number = 1
local pendingResult: string = ""

function onStartQuiz()
	local startQuizRemote = Remotes.get("StartQuiz") :: RemoteFunction
	local order = startQuizRemote:InvokeServer()
	currentQuizOrder = order
	currentQuizIndex = 1
	QuizUI.build(screenGui)
	showScreen("quiz")
	showNextQuestion()
end

function showNextQuestion()
	if currentQuizIndex > #currentQuizOrder then
		return -- All answered, waiting for server result
	end

	-- Random interlude check (1 in 5 chance, not on first question)
	if currentQuizIndex > 1 and math.random(1, 5) == 1 then
		InterludePlayer.play(screenGui, function()
			QuizUI.showQuestion(currentQuizOrder[currentQuizIndex], currentQuizIndex, #currentQuizOrder, onAnswerSelected)
		end)
	else
		QuizUI.showQuestion(currentQuizOrder[currentQuizIndex], currentQuizIndex, #currentQuizOrder, onAnswerSelected)
	end
end

function onAnswerSelected(answerIndex: number)
	local submitRemote = Remotes.get("SubmitAnswer") :: RemoteEvent
	submitRemote:FireServer(answerIndex)
	currentQuizIndex += 1

	if currentQuizIndex > #currentQuizOrder then
		-- Wait for server to send result
		QuizUI.showWaiting()
	else
		showNextQuestion()
	end
end

function showCollectionScreen(fromWelcome: boolean)
	local loadRemote = Remotes.get("LoadPlayerData") :: RemoteFunction
	local data = loadRemote:InvokeServer()
	CollectionUI.build(screenGui, data.unlockedArchetypes, function()
		if fromWelcome then
			showScreen("welcome")
		else
			showScreen("results")
		end
	end)
	showScreen("collection")
end

-- Listen for quiz result from server
local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
quizResultRemote.OnClientEvent:Connect(function(archetypeId: string)
	pendingResult = archetypeId

	-- Check GamePass — if owned, skip timer
	local checkGamePassRemote = Remotes.get("CheckGamePass") :: RemoteFunction
	local ownsGamePass = checkGamePassRemote:InvokeServer()

	if ownsGamePass then
		showResults(archetypeId)
	else
		TimerUI.build(screenGui, function()
			-- Timer finished or fully skipped
			showResults(archetypeId)
		end)
		showScreen("timer")
	end
end)

function showResults(archetypeId: string)
	ResultsUI.build(screenGui, archetypeId, function()
		-- Retake
		onStartQuiz()
	end, function()
		-- View collection
		showCollectionScreen(false)
	end)
	showScreen("results")
end

-- Listen for timer skip granted
local timerSkipRemote = Remotes.get("TimerSkipGranted") :: RemoteEvent
timerSkipRemote.OnClientEvent:Connect(function(secondsRemoved: number)
	TimerUI.onSkipGranted(secondsRemoved)
end)

-- Initialize leaderboard (always visible as toggleable panel)
LeaderboardUI.build(screenGui)

-- Listen for leaderboard updates
local leaderboardUpdateRemote = Remotes.get("LeaderboardUpdate") :: RemoteEvent
leaderboardUpdateRemote.OnClientEvent:Connect(function(data)
	LeaderboardUI.update(data)
end)

-- Request initial leaderboard data
local requestLeaderboardRemote = Remotes.get("RequestLeaderboard") :: RemoteEvent
requestLeaderboardRemote:FireServer()

-- Build and show welcome screen
buildWelcomeScreen()
showScreen("welcome")
