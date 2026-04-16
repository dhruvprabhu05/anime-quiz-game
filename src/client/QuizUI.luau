local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestionBank = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestionBank"))

local QuizUI = {}

local frame: Frame? = nil

function QuizUI.build(screenGui: ScreenGui)
	-- Remove old frame if rebuilding
	local existing = screenGui:FindFirstChild("QuizFrame")
	if existing then
		existing:Destroy()
	end

	local newFrame = Instance.new("Frame")
	newFrame.Name = "QuizFrame"
	newFrame.Size = UDim2.new(1, 0, 1, 0)
	newFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	newFrame.BorderSizePixel = 0
	newFrame.Visible = false
	newFrame.Parent = screenGui

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0.6, 0, 0.02, 0)
	progressBg.Position = UDim2.new(0.2, 0, 0.08, 0)
	progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = newFrame

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(1, 0)
	progressCorner.Parent = progressBg

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	-- Question counter
	local counter = Instance.new("TextLabel")
	counter.Name = "Counter"
	counter.Size = UDim2.new(0.2, 0, 0.04, 0)
	counter.Position = UDim2.new(0.4, 0, 0.12, 0)
	counter.BackgroundTransparency = 1
	counter.Text = "1/24"
	counter.TextColor3 = Color3.fromRGB(150, 150, 170)
	counter.TextScaled = true
	counter.Font = Enum.Font.Gotham
	counter.Parent = newFrame

	-- Question text
	local questionLabel = Instance.new("TextLabel")
	questionLabel.Name = "QuestionLabel"
	questionLabel.Size = UDim2.new(0.7, 0, 0.15, 0)
	questionLabel.Position = UDim2.new(0.15, 0, 0.2, 0)
	questionLabel.BackgroundTransparency = 1
	questionLabel.Text = ""
	questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	questionLabel.TextScaled = true
	questionLabel.TextWrapped = true
	questionLabel.Font = Enum.Font.GothamBold
	questionLabel.Parent = newFrame

	-- Answer buttons (4)
	local answerColors = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(80, 160, 255),
		Color3.fromRGB(80, 200, 120),
		Color3.fromRGB(255, 180, 50),
	}

	for i = 1, 4 do
		local row = math.ceil(i / 2) -- 1 or 2
		local col = ((i - 1) % 2) + 1 -- 1 or 2

		local button = Instance.new("TextButton")
		button.Name = "Answer" .. i
		button.Size = UDim2.new(0.35, 0, 0.12, 0)
		button.Position = UDim2.new(if col == 1 then 0.1 else 0.55, 0, if row == 1 then 0.45 else 0.62, 0)
		button.BackgroundColor3 = answerColors[i]
		button.Text = ""
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.Parent = newFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button

		-- Padding so text doesn't touch edges
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0.05, 0)
		padding.PaddingRight = UDim.new(0.05, 0)
		padding.PaddingTop = UDim.new(0.1, 0)
		padding.PaddingBottom = UDim.new(0.1, 0)
		padding.Parent = button
	end

	-- Waiting label (hidden by default)
	local waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
	waitingLabel.Position = UDim2.new(0.2, 0, 0.45, 0)
	waitingLabel.BackgroundTransparency = 1
	waitingLabel.Text = "Calculating your archetype..."
	waitingLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	waitingLabel.TextScaled = true
	waitingLabel.Font = Enum.Font.GothamBold
	waitingLabel.Visible = false
	waitingLabel.Parent = newFrame

	frame = newFrame
end

function QuizUI.showQuestion(questionIndex: number, currentNum: number, totalQuestions: number, onAnswer: (number) -> ())
	if not frame then
		return
	end

	local question = QuestionBank.getQuestion(questionIndex)

	-- Update progress bar
	local progressFill = frame:FindFirstChild("ProgressBg"):FindFirstChild("ProgressFill") :: Frame
	progressFill.Size = UDim2.new((currentNum - 1) / totalQuestions, 0, 1, 0)

	-- Update counter
	local counter = frame:FindFirstChild("Counter") :: TextLabel
	counter.Text = currentNum .. "/" .. totalQuestions

	-- Update question text
	local questionLabel = frame:FindFirstChild("QuestionLabel") :: TextLabel
	questionLabel.Text = question.text

	-- Update answer buttons
	for i = 1, 4 do
		local button = frame:FindFirstChild("Answer" .. i) :: TextButton
		button.Visible = true
		button.Text = question.answers[i].text

		button.MouseButton1Click:Connect(function()
			if frame and frame:FindFirstChild("Answer1").Visible then
				-- Hide buttons to prevent double-click
				for j = 1, 4 do
					local btn = frame:FindFirstChild("Answer" .. j) :: TextButton
					btn.Visible = false
				end
				onAnswer(i)
			end
		end)
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

	local questionLabel = frame:FindFirstChild("QuestionLabel") :: TextLabel
	questionLabel.Text = ""

	local waitingLabel = frame:FindFirstChild("WaitingLabel") :: TextLabel
	waitingLabel.Visible = true
end

return QuizUI
