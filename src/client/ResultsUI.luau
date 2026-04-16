local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

local ResultsUI = {}

function ResultsUI.build(screenGui: ScreenGui, archetypeId: string, onRetake: () -> (), onCollection: () -> ())
	local existing = screenGui:FindFirstChild("ResultsFrame")
	if existing then
		existing:Destroy()
	end

	local archetype = Archetypes.getById(archetypeId)
	if not archetype then
		return
	end

	local frame = Instance.new("Frame")
	frame.Name = "ResultsFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	-- Result card container
	local card = Instance.new("Frame")
	card.Name = "ResultCard"
	card.Size = UDim2.new(0.5, 0, 0.65, 0)
	card.Position = UDim2.new(0.25, 0, 0.05, 0)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
	card.BorderSizePixel = 0
	card.Parent = frame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(255, 200, 50)
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- "Your archetype is..." label
	local yourLabel = Instance.new("TextLabel")
	yourLabel.Size = UDim2.new(0.8, 0, 0.08, 0)
	yourLabel.Position = UDim2.new(0.1, 0, 0.05, 0)
	yourLabel.BackgroundTransparency = 1
	yourLabel.Text = "Your anime archetype is..."
	yourLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	yourLabel.TextScaled = true
	yourLabel.Font = Enum.Font.Gotham
	yourLabel.Parent = card

	-- Archetype name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ArchetypeName"
	nameLabel.Size = UDim2.new(0.8, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.1, 0, 0.15, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = archetype.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
	descLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = archetype.description
	descLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.Parent = card

	-- Example characters
	local examplesLabel = Instance.new("TextLabel")
	examplesLabel.Name = "Examples"
	examplesLabel.Size = UDim2.new(0.8, 0, 0.06, 0)
	examplesLabel.Position = UDim2.new(0.1, 0, 0.63, 0)
	examplesLabel.BackgroundTransparency = 1
	examplesLabel.Text = "Like: " .. table.concat(archetype.examples, ", ")
	examplesLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
	examplesLabel.TextScaled = true
	examplesLabel.Font = Enum.Font.GothamBold
	examplesLabel.Parent = card

	-- Screenshot hint
	local screenshotHint = Instance.new("TextLabel")
	screenshotHint.Size = UDim2.new(0.8, 0, 0.05, 0)
	screenshotHint.Position = UDim2.new(0.1, 0, 0.75, 0)
	screenshotHint.BackgroundTransparency = 1
	screenshotHint.Text = "Screenshot to share with friends!"
	screenshotHint.TextColor3 = Color3.fromRGB(120, 120, 150)
	screenshotHint.TextScaled = true
	screenshotHint.Font = Enum.Font.Gotham
	screenshotHint.Parent = card

	-- Watermark
	local watermark = Instance.new("TextLabel")
	watermark.Size = UDim2.new(0.8, 0, 0.05, 0)
	watermark.Position = UDim2.new(0.1, 0, 0.85, 0)
	watermark.BackgroundTransparency = 1
	watermark.Text = "AnimeQuizGame on Roblox"
	watermark.TextColor3 = Color3.fromRGB(80, 80, 100)
	watermark.TextScaled = true
	watermark.Font = Enum.Font.Gotham
	watermark.Parent = card

	-- Retake button
	local retakeButton = Instance.new("TextButton")
	retakeButton.Name = "RetakeButton"
	retakeButton.Size = UDim2.new(0.22, 0, 0.07, 0)
	retakeButton.Position = UDim2.new(0.15, 0, 0.82, 0)
	retakeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	retakeButton.Text = "Retake Quiz"
	retakeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	retakeButton.TextScaled = true
	retakeButton.Font = Enum.Font.GothamBold
	retakeButton.Parent = frame

	local retakeCorner = Instance.new("UICorner")
	retakeCorner.CornerRadius = UDim.new(0, 12)
	retakeCorner.Parent = retakeButton

	-- Collection button
	local collectionButton = Instance.new("TextButton")
	collectionButton.Name = "CollectionButton"
	collectionButton.Size = UDim2.new(0.22, 0, 0.07, 0)
	collectionButton.Position = UDim2.new(0.63, 0, 0.82, 0)
	collectionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
	collectionButton.Text = "View Collection"
	collectionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectionButton.TextScaled = true
	collectionButton.Font = Enum.Font.GothamBold
	collectionButton.Parent = frame

	local collectionCorner = Instance.new("UICorner")
	collectionCorner.CornerRadius = UDim.new(0, 12)
	collectionCorner.Parent = collectionButton

	retakeButton.MouseButton1Click:Connect(function()
		onRetake()
	end)

	collectionButton.MouseButton1Click:Connect(function()
		onCollection()
	end)
end

return ResultsUI
