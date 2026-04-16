local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local TimerUI = {}

local frame: Frame? = nil
local timerConnection: RBXScriptConnection? = nil
local remainingSeconds: number = 0
local onTimerComplete: (() -> ())? = nil

function TimerUI.build(screenGui: ScreenGui, onComplete: () -> ())
	onTimerComplete = onComplete
	remainingSeconds = 15 * 60 -- 15 minutes in seconds

	-- Remove old frame if rebuilding
	local existing = screenGui:FindFirstChild("TimerFrame")
	if existing then
		existing:Destroy()
	end

	local newFrame = Instance.new("Frame")
	newFrame.Name = "TimerFrame"
	newFrame.Size = UDim2.new(1, 0, 1, 0)
	newFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	newFrame.BorderSizePixel = 0
	newFrame.Visible = false
	newFrame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.6, 0, 0.08, 0)
	title.Position = UDim2.new(0.2, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text = "Your result is ready!"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = newFrame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(0.4, 0, 0.15, 0)
	timerLabel.Position = UDim2.new(0.3, 0, 0.28, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "15:00"
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.Code
	timerLabel.Parent = newFrame

	-- Skip with Robux button
	local idsFolder = ReplicatedStorage:WaitForChild("MonetizationIds")
	local skipProductId = idsFolder:WaitForChild("SkipProductId").Value
	local gamePassId = idsFolder:WaitForChild("GamePassId").Value

	local skipRobuxButton = Instance.new("TextButton")
	skipRobuxButton.Name = "SkipRobuxButton"
	skipRobuxButton.Size = UDim2.new(0.4, 0, 0.08, 0)
	skipRobuxButton.Position = UDim2.new(0.3, 0, 0.5, 0)
	skipRobuxButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
	skipRobuxButton.Text = "Skip 5 Minutes (5 Robux)"
	skipRobuxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipRobuxButton.TextScaled = true
	skipRobuxButton.Font = Enum.Font.GothamBold
	skipRobuxButton.Parent = newFrame

	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 12)
	corner1.Parent = skipRobuxButton

	-- Watch ad button
	local watchAdButton = Instance.new("TextButton")
	watchAdButton.Name = "WatchAdButton"
	watchAdButton.Size = UDim2.new(0.4, 0, 0.08, 0)
	watchAdButton.Position = UDim2.new(0.3, 0, 0.61, 0)
	watchAdButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
	watchAdButton.Text = "Watch Ad to Skip 5 Min (Free)"
	watchAdButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	watchAdButton.TextScaled = true
	watchAdButton.Font = Enum.Font.GothamBold
	watchAdButton.Parent = newFrame

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 12)
	corner2.Parent = watchAdButton

	-- Instant unlock GamePass button
	local gamePassButton = Instance.new("TextButton")
	gamePassButton.Name = "GamePassButton"
	gamePassButton.Size = UDim2.new(0.4, 0, 0.08, 0)
	gamePassButton.Position = UDim2.new(0.3, 0, 0.72, 0)
	gamePassButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
	gamePassButton.Text = "Instant Unlock - Never Wait Again (49 Robux)"
	gamePassButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	gamePassButton.TextScaled = true
	gamePassButton.Font = Enum.Font.GothamBold
	gamePassButton.Parent = newFrame

	local corner3 = Instance.new("UICorner")
	corner3.CornerRadius = UDim.new(0, 12)
	corner3.Parent = gamePassButton

	-- Button handlers
	skipRobuxButton.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(player, skipProductId)
	end)

	watchAdButton.MouseButton1Click:Connect(function()
		local success, err = pcall(function()
			local AdService = game:GetService("AdService")
			AdService:ShowRewardedAd()
		end)
		if not success then
			warn("[TimerUI] Ad not available: " .. tostring(err))
		end
	end)

	gamePassButton.MouseButton1Click:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, gamePassId)
	end)

	-- Listen for GamePass purchase completion
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasePlayer, purchasedGamePassId, wasPurchased)
		if purchasePlayer == player and purchasedGamePassId == gamePassId and wasPurchased then
			stopTimer()
			if onTimerComplete then
				onTimerComplete()
			end
		end
	end)

	frame = newFrame
	startTimer()
end

function startTimer()
	if timerConnection then
		timerConnection:Disconnect()
	end

	local lastTick = tick()
	timerConnection = RunService.Heartbeat:Connect(function()
		local now = tick()
		local delta = now - lastTick
		lastTick = now

		remainingSeconds -= delta
		if remainingSeconds <= 0 then
			remainingSeconds = 0
			stopTimer()
			if onTimerComplete then
				onTimerComplete()
			end
			return
		end

		updateTimerDisplay()
	end)
end

function stopTimer()
	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end
end

function updateTimerDisplay()
	if not frame then
		return
	end
	local timerLabel = frame:FindFirstChild("TimerLabel") :: TextLabel
	if not timerLabel then
		return
	end

	local minutes = math.floor(remainingSeconds / 60)
	local seconds = math.floor(remainingSeconds % 60)
	timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
end

function TimerUI.onSkipGranted(secondsRemoved: number)
	remainingSeconds -= secondsRemoved
	if remainingSeconds <= 0 then
		remainingSeconds = 0
		stopTimer()
		if onTimerComplete then
			onTimerComplete()
		end
	end
end

return TimerUI
