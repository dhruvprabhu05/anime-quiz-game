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
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Require UI modules
local QuizUI = require(script.Parent:WaitForChild("QuizUI"))
local TimerUI = require(script.Parent:WaitForChild("TimerUI"))
local ResultsUI = require(script.Parent:WaitForChild("ResultsUI"))
local CollectionUI = require(script.Parent:WaitForChild("CollectionUI"))
local InterludePlayer = require(script.Parent:WaitForChild("InterludePlayer"))
local SettingsUI = require(script.Parent:WaitForChild("SettingsUI"))

-- State
local currentScreen: string = "none"

-- UI styling
local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
local C = UIEffects.COLORS

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
local function makeMenuButton(parent: Frame, text: string, yPos: number, neonColor: Color3): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.3, 0, 0.06, 0)
	btn.Position = UDim2.new(0.35, 0, yPos, 0)
	btn.BackgroundColor3 = Color3.fromRGB(18, 14, 38)
	btn.BackgroundTransparency = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 5
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = neonColor
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = btn

	UIEffects.addNeonButton(btn, neonColor)
	return btn
end

local function buildWelcomeScreen()
	local frame = Instance.new("Frame")
	frame.Name = "WelcomeFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = C.bg
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	UIEffects.addGradient(frame, Color3.fromRGB(5, 2, 18), Color3.fromRGB(8, 5, 25), 170)
	UIEffects.addDigitalParticles(frame, 20)

	-- Main title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.7, 0, 0.09, 0)
	title.Position = UDim2.new(0.15, 0, 0.13, 0)
	title.BackgroundTransparency = 1
	title.Text = "WHICH ANIME CHARACTER"
	title.TextColor3 = C.textPrimary
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.ZIndex = 5
	title.Parent = frame

	local titleAccent = Instance.new("TextLabel")
	titleAccent.Name = "TitleAccent"
	titleAccent.Size = UDim2.new(0.4, 0, 0.1, 0)
	titleAccent.Position = UDim2.new(0.3, 0, 0.22, 0)
	titleAccent.BackgroundTransparency = 1
	titleAccent.Text = "ARE YOU?"
	titleAccent.TextColor3 = C.neonCyan
	titleAccent.TextScaled = true
	titleAccent.Font = Enum.Font.GothamBlack
	titleAccent.ZIndex = 5
	titleAccent.Parent = frame
	UIEffects.addGlitchText(titleAccent)

	UIEffects.addDivider(frame, 0.34, C.neonCyan)

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.5, 0, 0.04, 0)
	subtitle.Position = UDim2.new(0.25, 0, 0.37, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "// 24 QUESTIONS — 10 ARCHETYPES — FIND YOURS"
	subtitle.TextColor3 = C.textSecondary
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Code
	subtitle.ZIndex = 5
	subtitle.Parent = frame

	-- Center panel (dark glass container for buttons)
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0.38, 0, 0.24, 0)
	panel.Position = UDim2.new(0.31, 0, 0.46, 0)
	panel.BackgroundColor3 = C.bgPanel
	panel.BackgroundTransparency = 0.4
	panel.BorderSizePixel = 0
	panel.ZIndex = 4
	panel.Parent = frame

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	UIEffects.addNeonPulse(panel, C.neonPurple, 1)

	-- Buttons inside panel (positions relative to full frame)
	local startButton = makeMenuButton(frame, "[ START QUIZ ]", 0.50, C.neonCyan)
	startButton.Font = Enum.Font.GothamBlack
	UIEffects.addPulse(startButton)

	local collectionButton = makeMenuButton(frame, "[ COLLECTION ]", 0.60, C.neonBlue)

	-- Bottom system text
	local sysText = Instance.new("TextLabel")
	sysText.Size = UDim2.new(0.4, 0, 0.025, 0)
	sysText.Position = UDim2.new(0.3, 0, 0.88, 0)
	sysText.BackgroundTransparency = 1
	sysText.Text = "SYS > 10 archetypes available // v1.0"
	sysText.TextColor3 = C.textMuted
	sysText.TextScaled = true
	sysText.Font = Enum.Font.Code
	sysText.ZIndex = 5
	sysText.Parent = frame

	-- Corner decorative brackets
	local function addCornerBracket(xPos: number, yPos: number, rot: number)
		local bracket = Instance.new("TextLabel")
		bracket.Size = UDim2.new(0, 20, 0, 20)
		bracket.Position = UDim2.new(xPos, 0, yPos, 0)
		bracket.BackgroundTransparency = 1
		bracket.Text = "┌"
		bracket.TextColor3 = C.neonCyan
		bracket.TextScaled = true
		bracket.Font = Enum.Font.Code
		bracket.Rotation = rot
		bracket.TextTransparency = 0.5
		bracket.ZIndex = 3
		bracket.Parent = frame
	end

	addCornerBracket(0.03, 0.03, 0)
	addCornerBracket(0.95, 0.03, 90)
	addCornerBracket(0.03, 0.95, 270)
	addCornerBracket(0.95, 0.95, 180)

	startButton.MouseButton1Click:Connect(function()
		onStartQuiz()
	end)

	collectionButton.MouseButton1Click:Connect(function()
		showCollectionScreen(true)
	end)
end

-- Flow handlers
local currentQuizOrder: { number } = {}
local currentQuizIndex: number = 1

function onStartQuiz()
	local startQuizRemote = Remotes.get("StartQuiz") :: RemoteFunction
	local order = startQuizRemote:InvokeServer()

	if not order then
		-- Server rejected: cooldown active or session already running
		return
	end

	currentQuizOrder = order
	currentQuizIndex = 1
	InterludePlayer.resetSession()
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

-- Settings button (top right, always visible)
local settingsBtn = Instance.new("TextButton")
settingsBtn.Name = "SettingsButton"
settingsBtn.Size = UDim2.new(0, 40, 0, 40)
settingsBtn.Position = UDim2.new(1, -50, 0, 8)
settingsBtn.BackgroundColor3 = Color3.fromRGB(0, 30, 40)
settingsBtn.BackgroundTransparency = 0
settingsBtn.Text = "⚙"
settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsBtn.TextScaled = true
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.ZIndex = 25
settingsBtn.Parent = screenGui

local settingsBtnCorner = Instance.new("UICorner")
settingsBtnCorner.CornerRadius = UDim.new(0, 8)
settingsBtnCorner.Parent = settingsBtn

local settingsBtnStroke = Instance.new("UIStroke")
settingsBtnStroke.Color = C.neonPurple
settingsBtnStroke.Thickness = 1.5
settingsBtnStroke.Transparency = 0.3
settingsBtnStroke.Parent = settingsBtn

settingsBtn.MouseButton1Click:Connect(function()
	local existing = screenGui:FindFirstChild("SettingsFrame")
	if existing then
		existing:Destroy()
	else
		SettingsUI.build(screenGui, function()
			local settingsFrame = screenGui:FindFirstChild("SettingsFrame")
			if settingsFrame then
				settingsFrame:Destroy()
			end
		end)
	end
end)

-- Build and show welcome screen
buildWelcomeScreen()
showScreen("welcome")
