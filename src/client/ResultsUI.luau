local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

local ResultsUI = {}

-- Each archetype gets its own accent color
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

function ResultsUI.build(screenGui: ScreenGui, archetypeId: string, onRetake: () -> (), onCollection: () -> (), onHub: (() -> ())?, onSpinWheel: (() -> ())?)
	local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
	local C = UIEffects.COLORS

	local existing = screenGui:FindFirstChild("ResultsFrame")
	if existing then
		existing:Destroy()
	end

	local archetype = Archetypes.getById(archetypeId)
	if not archetype then
		return
	end

	local accentColor = ARCHETYPE_COLORS[archetypeId] or C.neonGold

	-- Root frame: near-black background
	local frame = Instance.new("Frame")
	frame.Name = "ResultsFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = C.bg
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	UIEffects.addGradient(frame, C.bg, C.bgPanel, 160)
	UIEffects.addDigitalParticles(frame, 20)
	UIEffects.addScanLine(frame)

	-- Result card: dark glass panel
	local card = Instance.new("Frame")
	card.Name = "ResultCard"
	card.Size = UDim2.new(0.46, 0, 0.72, 0)
	card.Position = UDim2.new(0.27, 0, 0.04, 0)
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.ZIndex = 3
	card.Parent = frame

	UIEffects.applyDarkGlass(card)
	UIEffects.addNeonPulse(card, accentColor, 2)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 18)
	cardCorner.Parent = card

	-- "YOUR ANIME ARCHETYPE IS..." — monospace, neon cyan
	local yourLabel = Instance.new("TextLabel")
	yourLabel.Size = UDim2.new(0.82, 0, 0.07, 0)
	yourLabel.Position = UDim2.new(0.09, 0, 0.05, 0)
	yourLabel.BackgroundTransparency = 1
	yourLabel.Text = "YOUR ANIME ARCHETYPE IS..."
	yourLabel.TextColor3 = C.neonCyan
	yourLabel.TextScaled = true
	yourLabel.Font = Enum.Font.RobotoMono
	yourLabel.ZIndex = 4
	yourLabel.Parent = card

	UIEffects.addGlow(yourLabel, C.neonCyan, 1)

	-- Archetype name: large, accent color, glitch effect
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ArchetypeName"
	nameLabel.Size = UDim2.new(0.85, 0, 0.13, 0)
	nameLabel.Position = UDim2.new(0.075, 0, 0.14, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = archetype.name
	nameLabel.TextColor3 = accentColor
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.ZIndex = 4
	nameLabel.Parent = card

	-- Entrance fade-in, then glitch
	nameLabel.TextTransparency = 1
	local fadeIn = TweenService:Create(
		nameLabel,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 0 }
	)
	fadeIn:Play()
	fadeIn.Completed:Connect(function()
		UIEffects.addGlitchText(nameLabel)
	end)

	-- Neon glow divider below name
	UIEffects.addDivider(card, 0.295, accentColor)

	-- Description: textPrimary color
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(0.82, 0, 0.28, 0)
	descLabel.Position = UDim2.new(0.09, 0, 0.33, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = archetype.description
	descLabel.TextColor3 = C.textPrimary
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.ZIndex = 4
	descLabel.Parent = card

	-- Example characters: dark glass container with accent neon border
	local examplesBg = Instance.new("Frame")
	examplesBg.Name = "ExamplesContainer"
	examplesBg.Size = UDim2.new(0.82, 0, 0.09, 0)
	examplesBg.Position = UDim2.new(0.09, 0, 0.64, 0)
	examplesBg.BackgroundTransparency = 1
	examplesBg.BorderSizePixel = 0
	examplesBg.ZIndex = 4
	examplesBg.Parent = card

	UIEffects.applyDarkGlass(examplesBg)
	UIEffects.addNeonPulse(examplesBg, accentColor, 1)

	local exBgCorner = Instance.new("UICorner")
	exBgCorner.CornerRadius = UDim.new(0, 8)
	exBgCorner.Parent = examplesBg

	local examplesLabel = Instance.new("TextLabel")
	examplesLabel.Size = UDim2.new(0.92, 0, 0.7, 0)
	examplesLabel.Position = UDim2.new(0.04, 0, 0.15, 0)
	examplesLabel.BackgroundTransparency = 1
	examplesLabel.Text = "Like: " .. table.concat(archetype.examples, "  •  ")
	examplesLabel.TextColor3 = accentColor
	examplesLabel.TextScaled = true
	examplesLabel.Font = Enum.Font.GothamBold
	examplesLabel.ZIndex = 5
	examplesLabel.Parent = examplesBg

	-- Screenshot hint
	local screenshotHint = Instance.new("TextLabel")
	screenshotHint.Size = UDim2.new(0.82, 0, 0.05, 0)
	screenshotHint.Position = UDim2.new(0.09, 0, 0.77, 0)
	screenshotHint.BackgroundTransparency = 1
	screenshotHint.Text = "Screenshot & share with friends!"
	screenshotHint.TextColor3 = C.textMuted
	screenshotHint.TextScaled = true
	screenshotHint.Font = Enum.Font.Gotham
	screenshotHint.ZIndex = 4
	screenshotHint.Parent = card

	-- Watermark
	local watermark = Instance.new("TextLabel")
	watermark.Size = UDim2.new(0.6, 0, 0.04, 0)
	watermark.Position = UDim2.new(0.2, 0, 0.9, 0)
	watermark.BackgroundTransparency = 1
	watermark.Text = "AnimeQuizGame on Roblox"
	watermark.TextColor3 = C.textMuted
	watermark.TextTransparency = 0.4
	watermark.TextScaled = true
	watermark.Font = Enum.Font.GothamBold
	watermark.ZIndex = 4
	watermark.Parent = card

	-- RETAKE button
	local retakeButton = Instance.new("TextButton")
	retakeButton.Name = "RetakeButton"
	retakeButton.Size = UDim2.new(0.2, 0, 0.065, 0)
	retakeButton.Position = UDim2.new(0.03, 0, 0.84, 0)
	retakeButton.BackgroundColor3 = Color3.fromRGB(0, 30, 40)
	retakeButton.BackgroundTransparency = 0
	retakeButton.Text = "[ RETAKE QUIZ ]"
	retakeButton.TextColor3 = C.neonCyan
	retakeButton.TextScaled = true
	retakeButton.Font = Enum.Font.RobotoMono
	retakeButton.ZIndex = 5
	retakeButton.Parent = frame

	local retakeCorner = Instance.new("UICorner")
	retakeCorner.CornerRadius = UDim.new(0, 8)
	retakeCorner.Parent = retakeButton

	local retakeStroke = Instance.new("UIStroke")
	retakeStroke.Color = C.neonCyan
	retakeStroke.Thickness = 2
	retakeStroke.Transparency = 0.2
	retakeStroke.Parent = retakeButton

	UIEffects.addNeonButton(retakeButton, C.neonCyan)

	-- SPIN WHEEL button
	local spinButton = Instance.new("TextButton")
	spinButton.Name = "SpinButton"
	spinButton.Size = UDim2.new(0.2, 0, 0.065, 0)
	spinButton.Position = UDim2.new(0.27, 0, 0.84, 0)
	spinButton.BackgroundColor3 = Color3.fromRGB(35, 25, 5)
	spinButton.BackgroundTransparency = 0
	spinButton.Text = "[ SPIN WHEEL ]"
	spinButton.TextColor3 = C.neonGold
	spinButton.TextScaled = true
	spinButton.Font = Enum.Font.RobotoMono
	spinButton.ZIndex = 5
	spinButton.Parent = frame

	local spinCorner = Instance.new("UICorner")
	spinCorner.CornerRadius = UDim.new(0, 8)
	spinCorner.Parent = spinButton

	local spinStroke = Instance.new("UIStroke")
	spinStroke.Color = C.neonGold
	spinStroke.Thickness = 2
	spinStroke.Transparency = 0.2
	spinStroke.Parent = spinButton

	UIEffects.addNeonButton(spinButton, C.neonGold)

	-- COLLECTION button
	local collectionButton = Instance.new("TextButton")
	collectionButton.Name = "CollectionButton"
	collectionButton.Size = UDim2.new(0.2, 0, 0.065, 0)
	collectionButton.Position = UDim2.new(0.51, 0, 0.84, 0)
	collectionButton.BackgroundColor3 = Color3.fromRGB(10, 10, 40)
	collectionButton.BackgroundTransparency = 0
	collectionButton.Text = "[ COLLECTION ]"
	collectionButton.TextColor3 = C.neonBlue
	collectionButton.TextScaled = true
	collectionButton.Font = Enum.Font.RobotoMono
	collectionButton.ZIndex = 5
	collectionButton.Parent = frame

	local collectionCorner = Instance.new("UICorner")
	collectionCorner.CornerRadius = UDim.new(0, 8)
	collectionCorner.Parent = collectionButton

	local collectionStroke = Instance.new("UIStroke")
	collectionStroke.Color = C.neonBlue
	collectionStroke.Thickness = 2
	collectionStroke.Transparency = 0.2
	collectionStroke.Parent = collectionButton

	UIEffects.addNeonButton(collectionButton, C.neonBlue)

	-- EXPLORE HUB button
	local hubButton = Instance.new("TextButton")
	hubButton.Name = "HubButton"
	hubButton.Size = UDim2.new(0.2, 0, 0.065, 0)
	hubButton.Position = UDim2.new(0.75, 0, 0.84, 0)
	hubButton.BackgroundColor3 = Color3.fromRGB(30, 5, 25)
	hubButton.BackgroundTransparency = 0
	hubButton.Text = "[ EXPLORE HUB ]"
	hubButton.TextColor3 = C.neonMagenta
	hubButton.TextScaled = true
	hubButton.Font = Enum.Font.RobotoMono
	hubButton.ZIndex = 5
	hubButton.Parent = frame

	local hubCorner = Instance.new("UICorner")
	hubCorner.CornerRadius = UDim.new(0, 8)
	hubCorner.Parent = hubButton

	local hubStroke = Instance.new("UIStroke")
	hubStroke.Color = C.neonMagenta
	hubStroke.Thickness = 2
	hubStroke.Transparency = 0.2
	hubStroke.Parent = hubButton

	UIEffects.addNeonButton(hubButton, C.neonMagenta)

	-- Wire up callbacks
	retakeButton.MouseButton1Click:Connect(function()
		onRetake()
	end)

	collectionButton.MouseButton1Click:Connect(function()
		onCollection()
	end)

	hubButton.MouseButton1Click:Connect(function()
		if onHub then
			onHub()
		end
	end)

	spinButton.MouseButton1Click:Connect(function()
		if onSpinWheel then
			onSpinWheel()
		end
	end)
end

return ResultsUI
