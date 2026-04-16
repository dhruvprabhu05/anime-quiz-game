local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local QuestionBank = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestionBank"))

local QuizUI = {}

local frame: Frame? = nil
local answerConnections: { RBXScriptConnection } = {}

-- Neon color per answer button: stroke + text color
-- Order: cyan, magenta, purple, gold
local ANSWER_STYLES = {
	{ base = Color3.fromRGB(220, 50, 70),  gradEnd = Color3.fromRGB(180, 30, 50),  neon = Color3.fromRGB(0, 240, 255)   }, -- cyan
	{ base = Color3.fromRGB(40, 120, 220),  gradEnd = Color3.fromRGB(30, 80, 180),  neon = Color3.fromRGB(255, 0, 200)   }, -- magenta
	{ base = Color3.fromRGB(40, 180, 100),  gradEnd = Color3.fromRGB(25, 140, 75),  neon = Color3.fromRGB(160, 60, 255)  }, -- purple
	{ base = Color3.fromRGB(230, 160, 30),  gradEnd = Color3.fromRGB(200, 120, 20), neon = Color3.fromRGB(255, 200, 30)  }, -- gold
}

function QuizUI.build(screenGui: ScreenGui)
	local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
	local C = UIEffects.COLORS

	local existing = screenGui:FindFirstChild("QuizFrame")
	if existing then
		existing:Destroy()
	end

	-- Root frame: near-black with subtle purple gradient
	local newFrame = Instance.new("Frame")
	newFrame.Name = "QuizFrame"
	newFrame.Size = UDim2.new(1, 0, 1, 0)
	newFrame.BackgroundColor3 = C.bg
	newFrame.BorderSizePixel = 0
	newFrame.Visible = false
	newFrame.Parent = screenGui

	UIEffects.addGradient(newFrame, C.bg, Color3.fromRGB(18, 5, 45), 160)
	UIEffects.addDigitalParticles(newFrame, 8)

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0.5, 0, 0, 6)
	progressBg.Position = UDim2.new(0.25, 0, 0.07, 0)
	progressBg.BackgroundColor3 = Color3.fromRGB(25, 20, 50)
	progressBg.BorderSizePixel = 0
	progressBg.ZIndex = 3
	progressBg.Parent = newFrame

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(1, 0)
	progressCorner.Parent = progressBg

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = C.neonCyan
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 4
	progressFill.Parent = progressBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	-- Neon cyan glow on progress fill
	UIEffects.addGlow(progressFill, C.neonCyan, 1)

	-- Question counter: monospace neon cyan "[ 03 / 24 ]"
	local counter = Instance.new("TextLabel")
	counter.Name = "Counter"
	counter.Size = UDim2.new(0.2, 0, 0.04, 0)
	counter.Position = UDim2.new(0.4, 0, 0.1, 0)
	counter.BackgroundTransparency = 1
	counter.Text = "[ 01 / 24 ]"
	counter.TextColor3 = C.neonCyan
	counter.TextScaled = true
	counter.Font = Enum.Font.RobotoMono
	counter.ZIndex = 3
	counter.Parent = newFrame

	-- Question card: dark glass with pulsing neon purple border
	local questionCard = Instance.new("Frame")
	questionCard.Name = "QuestionCard"
	questionCard.Size = UDim2.new(0.7, 0, 0.2, 0)
	questionCard.Position = UDim2.new(0.15, 0, 0.16, 0)
	questionCard.BorderSizePixel = 0
	questionCard.ZIndex = 3
	questionCard.Parent = newFrame

	UIEffects.applyDarkGlass(questionCard)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = questionCard

	UIEffects.addNeonPulse(questionCard, C.neonPurple, 2)

	-- Question text: bright white, clean
	local questionLabel = Instance.new("TextLabel")
	questionLabel.Name = "QuestionLabel"
	questionLabel.Size = UDim2.new(0.85, 0, 0.7, 0)
	questionLabel.Position = UDim2.new(0.075, 0, 0.15, 0)
	questionLabel.BackgroundTransparency = 1
	questionLabel.Text = ""
	questionLabel.TextColor3 = C.textPrimary
	questionLabel.TextScaled = true
	questionLabel.TextWrapped = true
	questionLabel.Font = Enum.Font.GothamBold
	questionLabel.ZIndex = 4
	questionLabel.Parent = questionCard

	-- Answer buttons (2x2 grid): dark glass, neon colored strokes
	for i = 1, 4 do
		local row = math.ceil(i / 2)
		local col = ((i - 1) % 2) + 1
		local style = ANSWER_STYLES[i]

		local button = Instance.new("TextButton")
		button.Name = "Answer" .. i
		button.Size = UDim2.new(0.38, 0, 0.14, 0)
		button.Position = UDim2.new(if col == 1 then 0.08 else 0.54, 0, if row == 1 then 0.42 else 0.6, 0)
		button.Text = ""
		button.TextColor3 = style.neon
		button.TextScaled = false
		button.TextWrapped = true
		button.TextSize = 16
		button.Font = Enum.Font.GothamBold
		button.TextYAlignment = Enum.TextYAlignment.Center
		button.BorderSizePixel = 0
		button.ZIndex = 3
		button.Parent = newFrame

		UIEffects.applyDarkGlass(button)

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0.05, 0)
		padding.PaddingRight = UDim.new(0.05, 0)
		padding.PaddingTop = UDim.new(0.08, 0)
		padding.PaddingBottom = UDim.new(0.08, 0)
		padding.Parent = button

		UIEffects.addNeonButton(button, style.neon)
	end

	-- Waiting label: neon cyan, monospace
	local waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Size = UDim2.new(0.5, 0, 0.08, 0)
	waitingLabel.Position = UDim2.new(0.25, 0, 0.46, 0)
	waitingLabel.BackgroundTransparency = 1
	waitingLabel.Text = "Calculating your archetype..."
	waitingLabel.TextColor3 = C.neonCyan
	waitingLabel.TextScaled = true
	waitingLabel.Font = Enum.Font.RobotoMono
	waitingLabel.Visible = false
	waitingLabel.ZIndex = 3
	waitingLabel.Parent = newFrame

	frame = newFrame
end

function QuizUI.showQuestion(questionIndex: number, currentNum: number, totalQuestions: number, onAnswer: (number) -> ())
	if not frame then
		return
	end

	local question = QuestionBank.getQuestion(questionIndex)

	-- Animate progress bar fill
	local progressFill = frame:FindFirstChild("ProgressBg"):FindFirstChild("ProgressFill") :: Frame
	TweenService:Create(progressFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new((currentNum - 1) / totalQuestions, 0, 1, 0),
	}):Play()

	-- Update counter in "[ 03 / 24 ]" monospace format
	local counter = frame:FindFirstChild("Counter") :: TextLabel
	local numStr = string.format("%02d", currentNum)
	local totStr = string.format("%02d", totalQuestions)
	counter.Text = "[ " .. numStr .. " / " .. totStr .. " ]"

	-- Update question text with fade
	local questionCard = frame:FindFirstChild("QuestionCard")
	local questionLabel = questionCard:FindFirstChild("QuestionLabel") :: TextLabel
	questionLabel.TextTransparency = 1
	questionLabel.Text = question.text
	TweenService:Create(questionLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()

	-- Disconnect previous answer handlers
	for _, conn in answerConnections do
		conn:Disconnect()
	end
	table.clear(answerConnections)

	-- Update answer buttons with staggered fade-in
	for i = 1, 4 do
		local button = frame:FindFirstChild("Answer" .. i) :: TextButton
		button.Visible = true
		button.Text = question.answers[i].text
		button.BackgroundTransparency = 1
		button.TextTransparency = 1

		-- Stagger the animations
		task.delay((i - 1) * 0.06, function()
			TweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
				TextTransparency = 0,
			}):Play()
		end)

		local conn = button.MouseButton1Click:Connect(function()
			if frame and frame:FindFirstChild("Answer1").Visible then
				-- Immediately hide all buttons to prevent race conditions
				for j = 1, 4 do
					local btn = frame:FindFirstChild("Answer" .. j) :: TextButton
					btn.Visible = false
					btn.BackgroundTransparency = 0
					btn.TextTransparency = 0
				end
				onAnswer(i)
			end
		end)
		table.insert(answerConnections, conn)
	end

	-- Hide waiting label
	local waitingLabel = frame:FindFirstChild("WaitingLabel") :: TextLabel
	waitingLabel.Visible = false
end

function QuizUI.showWaiting()
	if not frame then
		return
	end

	for i = 1, 4 do
		local button = frame:FindFirstChild("Answer" .. i) :: TextButton
		button.Visible = false
	end

	local questionCard = frame:FindFirstChild("QuestionCard")
	local questionLabel = questionCard:FindFirstChild("QuestionLabel") :: TextLabel
	questionLabel.Text = ""

	local waitingLabel = frame:FindFirstChild("WaitingLabel") :: TextLabel
	waitingLabel.Visible = true
end

return QuizUI
