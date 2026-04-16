local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local TimerUI = {}

local frame: Frame? = nil
local timerConnection: RBXScriptConnection? = nil
local remainingSeconds: number = 0
local onTimerComplete: (() -> ())? = nil

function TimerUI.build(screenGui: ScreenGui, onComplete: () -> ())
	local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
	local C = UIEffects.COLORS

	onTimerComplete = onComplete
	remainingSeconds = 15 * 60

	local existing = screenGui:FindFirstChild("TimerFrame")
	if existing then
		existing:Destroy()
	end

	-- Root frame — near-black background
	local newFrame = Instance.new("Frame")
	newFrame.Name = "TimerFrame"
	newFrame.Size = UDim2.new(1, 0, 1, 0)
	newFrame.BackgroundColor3 = C.bg
	newFrame.BorderSizePixel = 0
	newFrame.Visible = false
	newFrame.Parent = screenGui

	UIEffects.addGradient(newFrame, C.bg, C.bgPanel, 160)
	UIEffects.addDigitalParticles(newFrame, 8)

	-- Title: neon gold, bold
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.5, 0, 0.06, 0)
	title.Position = UDim2.new(0.25, 0, 0.1, 0)
	title.BackgroundTransparency = 1
	title.Text = "YOUR RESULT IS READY!"
	title.TextColor3 = C.neonGold
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.ZIndex = 3
	title.Parent = newFrame

	-- Subtitle: textSecondary, monospace
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.4, 0, 0.04, 0)
	subtitle.Position = UDim2.new(0.3, 0, 0.17, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Reveal in..."
	subtitle.TextColor3 = C.textSecondary
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Code
	subtitle.ZIndex = 3
	subtitle.Parent = newFrame

	-- Timer card — dark glass with neon gold pulsing border
	local timerCard = Instance.new("Frame")
	timerCard.Size = UDim2.new(0.3, 0, 0.15, 0)
	timerCard.Position = UDim2.new(0.35, 0, 0.23, 0)
	timerCard.BorderSizePixel = 0
	timerCard.ZIndex = 3
	timerCard.Parent = newFrame

	local timerCorner = Instance.new("UICorner")
	timerCorner.CornerRadius = UDim.new(0, 16)
	timerCorner.Parent = timerCard

	UIEffects.applyDarkGlass(timerCard)
	UIEffects.addNeonPulse(timerCard, C.neonGold, 3)
	UIEffects.addScanLine(timerCard)

	-- Timer label — monospace, neon gold
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(0.8, 0, 0.6, 0)
	timerLabel.Position = UDim2.new(0.1, 0, 0.2, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "15:00"
	timerLabel.TextColor3 = C.neonGold
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.Code
	timerLabel.ZIndex = 4
	timerLabel.Parent = timerCard

	-- Divider
	UIEffects.addDivider(newFrame, 0.42, C.neonGold)

	-- "Or skip the wait" label
	local skipLabel = Instance.new("TextLabel")
	skipLabel.Size = UDim2.new(0.3, 0, 0.04, 0)
	skipLabel.Position = UDim2.new(0.35, 0, 0.44, 0)
	skipLabel.BackgroundTransparency = 1
	skipLabel.Text = "Or skip the wait..."
	skipLabel.TextColor3 = C.textMuted
	skipLabel.TextScaled = true
	skipLabel.Font = Enum.Font.Code
	skipLabel.ZIndex = 3
	skipLabel.Parent = newFrame

	-- Monetization IDs (kept exactly as-is)
	local idsFolder = ReplicatedStorage:WaitForChild("MonetizationIds")
	local skipProductId = idsFolder:WaitForChild("SkipProductId").Value
	local gamePassId = idsFolder:WaitForChild("GamePassId").Value

	-- Skip with Robux button — dark glass + neon green stroke
	local skipRobuxButton = Instance.new("TextButton")
	skipRobuxButton.Name = "SkipRobuxButton"
	skipRobuxButton.Size = UDim2.new(0.35, 0, 0.07, 0)
	skipRobuxButton.Position = UDim2.new(0.325, 0, 0.51, 0)
	skipRobuxButton.Text = "Skip 5 Minutes (5 Robux)"
	skipRobuxButton.TextColor3 = C.textPrimary
	skipRobuxButton.TextScaled = true
	skipRobuxButton.Font = Enum.Font.GothamBold
	skipRobuxButton.BorderSizePixel = 0
	skipRobuxButton.ZIndex = 3
	skipRobuxButton.Parent = newFrame

	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 14)
	corner1.Parent = skipRobuxButton

	UIEffects.applyDarkGlass(skipRobuxButton)
	UIEffects.addNeonButton(skipRobuxButton, Color3.fromRGB(0, 230, 120))

	-- Watch Ad button — dark glass + neon blue stroke
	local watchAdButton = Instance.new("TextButton")
	watchAdButton.Name = "WatchAdButton"
	watchAdButton.Size = UDim2.new(0.35, 0, 0.07, 0)
	watchAdButton.Position = UDim2.new(0.325, 0, 0.61, 0)
	watchAdButton.Text = "Watch Ad — Skip 5 Min (Free)"
	watchAdButton.TextColor3 = C.textPrimary
	watchAdButton.TextScaled = true
	watchAdButton.Font = Enum.Font.GothamBold
	watchAdButton.BorderSizePixel = 0
	watchAdButton.ZIndex = 3
	watchAdButton.Parent = newFrame

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 14)
	corner2.Parent = watchAdButton

	UIEffects.applyDarkGlass(watchAdButton)
	UIEffects.addNeonButton(watchAdButton, C.neonBlue)

	-- GamePass button — premium neon gold pulse border
	local gamePassButton = Instance.new("TextButton")
	gamePassButton.Name = "GamePassButton"
	gamePassButton.Size = UDim2.new(0.35, 0, 0.07, 0)
	gamePassButton.Position = UDim2.new(0.325, 0, 0.71, 0)
	gamePassButton.Text = "Instant Unlock — Never Wait Again (49 R$)"
	gamePassButton.TextColor3 = C.neonGold
	gamePassButton.TextScaled = true
	gamePassButton.Font = Enum.Font.GothamBlack
	gamePassButton.BorderSizePixel = 0
	gamePassButton.ZIndex = 3
	gamePassButton.Parent = newFrame

	local corner3 = Instance.new("UICorner")
	corner3.CornerRadius = UDim.new(0, 14)
	corner3.Parent = gamePassButton

	UIEffects.applyDarkGlass(gamePassButton)
	UIEffects.addNeonPulse(gamePassButton, C.neonGold, 3)
	UIEffects.addNeonButton(gamePassButton, C.neonGold)

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
	-- TimerLabel is now inside the timerCard
	local timerCard = nil
	for _, child in frame:GetChildren() do
		local label = child:FindFirstChild("TimerLabel")
		if label then
			timerCard = child
			break
		end
	end
	if not timerCard then
		return
	end
	local timerLabel = timerCard:FindFirstChild("TimerLabel") :: TextLabel
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
