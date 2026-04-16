local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

local CollectionUI = {}

function CollectionUI.build(screenGui: ScreenGui, unlockedIds: { string }, onBack: () -> ())
	local existing = screenGui:FindFirstChild("CollectionFrame")
	if existing then
		existing:Destroy()
	end

	-- Build a set for fast lookup
	local unlockedSet: { [string]: boolean } = {}
	for _, id in unlockedIds do
		unlockedSet[id] = true
	end

	local frame = Instance.new("Frame")
	frame.Name = "CollectionFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.6, 0, 0.08, 0)
	title.Position = UDim2.new(0.2, 0, 0.03, 0)
	title.BackgroundTransparency = 1
	title.Text = "My Collection"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Progress counter
	local unlockedCount = 0
	for _ in unlockedSet do
		unlockedCount += 1
	end

	local progressLabel = Instance.new("TextLabel")
	progressLabel.Size = UDim2.new(0.3, 0, 0.04, 0)
	progressLabel.Position = UDim2.new(0.35, 0, 0.11, 0)
	progressLabel.BackgroundTransparency = 1
	progressLabel.Text = unlockedCount .. "/" .. #Archetypes.list .. " Collected"
	progressLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	progressLabel.TextScaled = true
	progressLabel.Font = Enum.Font.Gotham
	progressLabel.Parent = frame

	-- Grid of archetype cards (2 columns, 5 rows)
	local allArchetypes = Archetypes.list
	for i, archetype in allArchetypes do
		local row = math.ceil(i / 2)
		local col = ((i - 1) % 2) + 1
		local isUnlocked = unlockedSet[archetype.id] == true

		local cardX = if col == 1 then 0.08 else 0.52
		local cardY = 0.16 + (row - 1) * 0.155

		local card = Instance.new("Frame")
		card.Name = "Card_" .. archetype.id
		card.Size = UDim2.new(0.4, 0, 0.14, 0)
		card.Position = UDim2.new(cardX, 0, cardY, 0)
		card.BackgroundColor3 = if isUnlocked then Color3.fromRGB(30, 30, 55) else Color3.fromRGB(20, 20, 30)
		card.BorderSizePixel = 0
		card.Parent = frame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = if isUnlocked then Color3.fromRGB(255, 200, 50) else Color3.fromRGB(50, 50, 70)
		cardStroke.Thickness = 1
		cardStroke.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.9, 0, 0.35, 0)
		nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = if isUnlocked then archetype.name else "???"
		nameLabel.TextColor3 = if isUnlocked then Color3.fromRGB(255, 200, 50) else Color3.fromRGB(80, 80, 100)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.9, 0, 0.5, 0)
		descLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = if isUnlocked then archetype.description else "Take the quiz to unlock!"
		descLabel.TextColor3 = if isUnlocked then Color3.fromRGB(180, 180, 200) else Color3.fromRGB(60, 60, 80)
		descLabel.TextScaled = true
		descLabel.TextWrapped = true
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = card
	end

	-- Back button
	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0.15, 0, 0.06, 0)
	backButton.Position = UDim2.new(0.425, 0, 0.93, 0)
	backButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	backButton.Text = "Back"
	backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	backButton.TextScaled = true
	backButton.Font = Enum.Font.GothamBold
	backButton.Parent = frame

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 12)
	backCorner.Parent = backButton

	backButton.MouseButton1Click:Connect(function()
		onBack()
	end)
end

return CollectionUI
