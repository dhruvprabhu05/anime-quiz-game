local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

local CollectionUI = {}

local ARCHETYPE_COLORS: { [string]: Color3 } = {
	hot_headed_hero = Color3.fromRGB(255, 60, 40),
	cool_strategist = Color3.fromRGB(50, 130, 255),
	lone_wolf = Color3.fromRGB(120, 100, 160),
	gentle_protector = Color3.fromRGB(80, 200, 140),
	chaotic_wildcard = Color3.fromRGB(200, 50, 255),
	silent_powerhouse = Color3.fromRGB(100, 140, 180),
	loyal_companion = Color3.fromRGB(255, 120, 80),
	wise_mentor = Color3.fromRGB(180, 180, 200),
	rebel_with_a_cause = Color3.fromRGB(200, 40, 40),
	cheerful_optimist = Color3.fromRGB(255, 200, 50),
}

function CollectionUI.build(screenGui: ScreenGui, unlockedIds: { string }, onBack: () -> ())
	local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
	local C = UIEffects.COLORS

	local existing = screenGui:FindFirstChild("CollectionFrame")
	if existing then
		existing:Destroy()
	end

	local unlockedSet: { [string]: boolean } = {}
	for _, id in unlockedIds do
		unlockedSet[id] = true
	end

	-- Root frame: near-black background
	local frame = Instance.new("Frame")
	frame.Name = "CollectionFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = C.bg
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	UIEffects.addGradient(frame, Color3.fromRGB(8, 4, 20), Color3.fromRGB(4, 10, 25), 160)
	UIEffects.addDigitalParticles(frame, 18)

	-- Title: neonCyan, monospace-ish (RobotoMono)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.5, 0, 0.065, 0)
	title.Position = UDim2.new(0.25, 0, 0.025, 0)
	title.BackgroundTransparency = 1
	title.Text = "MY COLLECTION"
	title.TextColor3 = C.neonCyan
	title.TextScaled = true
	title.Font = Enum.Font.RobotoMono
	title.ZIndex = 3
	title.Parent = frame

	-- Neon glow behind title text
	UIEffects.addGlow(title, C.neonCyan, 1)

	-- Divider below title
	UIEffects.addDivider(frame, 0.095, C.neonCyan)

	-- Progress counter
	local unlockedCount = 0
	for _ in unlockedSet do
		unlockedCount += 1
	end

	local progressLabel = Instance.new("TextLabel")
	progressLabel.Size = UDim2.new(0.22, 0, 0.033, 0)
	progressLabel.Position = UDim2.new(0.39, 0, 0.098, 0)
	progressLabel.BackgroundTransparency = 1
	progressLabel.Text = unlockedCount .. " / " .. #Archetypes.list .. "  COLLECTED"
	progressLabel.TextColor3 = C.textSecondary
	progressLabel.TextScaled = true
	progressLabel.Font = Enum.Font.RobotoMono
	progressLabel.ZIndex = 3
	progressLabel.Parent = frame

	-- Progress bar track (dark)
	local progBarBg = Instance.new("Frame")
	progBarBg.Size = UDim2.new(0.32, 0, 0, 5)
	progBarBg.Position = UDim2.new(0.34, 0, 0.133, 0)
	progBarBg.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
	progBarBg.BorderSizePixel = 0
	progBarBg.ZIndex = 3
	progBarBg.Parent = frame

	local progBarCorner = Instance.new("UICorner")
	progBarCorner.CornerRadius = UDim.new(1, 0)
	progBarCorner.Parent = progBarBg

	-- Progress bar fill: neonCyan
	local progBarFill = Instance.new("Frame")
	progBarFill.Size = UDim2.new(unlockedCount / #Archetypes.list, 0, 1, 0)
	progBarFill.BackgroundColor3 = C.neonCyan
	progBarFill.BorderSizePixel = 0
	progBarFill.ZIndex = 4
	progBarFill.Parent = progBarBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progBarFill

	-- Subtle glow on fill bar
	UIEffects.addGlow(progBarFill, C.neonCyan, 1)

	-- Grid of archetype cards (2 columns, 5 rows)
	local allArchetypes = Archetypes.list
	for i, archetype in allArchetypes do
		local row = math.ceil(i / 2)
		local col = ((i - 1) % 2) + 1
		local isUnlocked = unlockedSet[archetype.id] == true
		local accentColor = ARCHETYPE_COLORS[archetype.id] or Color3.fromRGB(100, 100, 150)

		local cardX = if col == 1 then 0.06 else 0.52
		local cardY = 0.15 + (row - 1) * 0.155

		local card = Instance.new("Frame")
		card.Name = "Card_" .. archetype.id
		card.Size = UDim2.new(0.42, 0, 0.14, 0)
		card.Position = UDim2.new(cardX, 0, cardY, 0)
		card.BorderSizePixel = 0
		card.ZIndex = 3
		card.Parent = frame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 12)
		cardCorner.Parent = card

		-- Dark glass base
		UIEffects.applyDarkGlass(card)

		-- Border: archetype color for unlocked, dim dark for locked
		if isUnlocked then
			local stroke = Instance.new("UIStroke")
			stroke.Color = accentColor
			stroke.Thickness = 1.5
			stroke.Transparency = 0.3
			stroke.Parent = card
		else
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(30, 28, 50)
			stroke.Thickness = 1
			stroke.Transparency = 0.4
			stroke.Parent = card
		end

		-- Left accent stripe
		local leftStripe = Instance.new("Frame")
		leftStripe.Size = UDim2.new(0, 4, 0.7, 0)
		leftStripe.Position = UDim2.new(0, 0, 0.15, 0)
		leftStripe.BackgroundColor3 = if isUnlocked then accentColor else Color3.fromRGB(35, 33, 55)
		leftStripe.BackgroundTransparency = if isUnlocked then 0 else 0.6
		leftStripe.BorderSizePixel = 0
		leftStripe.ZIndex = 4
		leftStripe.Parent = card

		local stripeCorner = Instance.new("UICorner")
		stripeCorner.CornerRadius = UDim.new(1, 0)
		stripeCorner.Parent = leftStripe

		-- Name: archetype neon color for unlocked, textMuted for locked
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.82, 0, 0.32, 0)
		nameLabel.Position = UDim2.new(0.1, 0, 0.08, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = if isUnlocked then archetype.name else "???"
		nameLabel.TextColor3 = if isUnlocked then accentColor else C.textMuted
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 4
		nameLabel.Parent = card

		-- Description: textSecondary for unlocked, textMuted for locked
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.82, 0, 0.45, 0)
		descLabel.Position = UDim2.new(0.1, 0, 0.43, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = if isUnlocked then archetype.description else "Take the quiz to unlock!"
		descLabel.TextColor3 = if isUnlocked then C.textSecondary else C.textMuted
		descLabel.TextScaled = true
		descLabel.TextWrapped = true
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.ZIndex = 4
		descLabel.Parent = card

		-- Staggered entrance animation
		card.BackgroundTransparency = 1
		nameLabel.TextTransparency = 1
		descLabel.TextTransparency = 1
		leftStripe.BackgroundTransparency = 1

		task.delay(i * 0.04, function()
			TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			}):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
			TweenService:Create(descLabel, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
			TweenService:Create(leftStripe, TweenInfo.new(0.3), {
				BackgroundTransparency = if isUnlocked then 0 else 0.6,
			}):Play()
		end)
	end

	-- Back button: dark glass + neonButton with neonPurple
	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0.14, 0, 0.055, 0)
	backButton.Position = UDim2.new(0.43, 0, 0.93, 0)
	backButton.BorderSizePixel = 0
	backButton.Text = "[ BACK ]"
	backButton.TextColor3 = C.neonCyan
	backButton.BackgroundColor3 = Color3.fromRGB(0, 30, 40)
	backButton.BackgroundTransparency = 0
	backButton.TextScaled = true
	backButton.Font = Enum.Font.RobotoMono
	backButton.AutoButtonColor = false
	backButton.ZIndex = 10
	backButton.Parent = frame

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 8)
	backCorner.Parent = backButton

	UIEffects.addNeonButton(backButton, C.neonCyan)

	backButton.MouseButton1Click:Connect(function()
		onBack()
	end)
end

return CollectionUI
