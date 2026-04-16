local LeaderboardUI = {}

local panel: Frame? = nil
local contentFrame: Frame? = nil
local isOpen: boolean = false

function LeaderboardUI.build(screenGui: ScreenGui)
	local existing = screenGui:FindFirstChild("LeaderboardPanel")
	if existing then
		existing:Destroy()
	end

	-- Toggle button (always visible)
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "LeaderboardToggle"
	toggleButton.Size = UDim2.new(0, 120, 0, 35)
	toggleButton.Position = UDim2.new(1, -130, 0, 10)
	toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	toggleButton.Text = "Leaderboard"
	toggleButton.TextColor3 = Color3.fromRGB(255, 200, 50)
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.ZIndex = 10
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	-- Side panel
	local newPanel = Instance.new("Frame")
	newPanel.Name = "LeaderboardPanel"
	newPanel.Size = UDim2.new(0.25, 0, 0.7, 0)
	newPanel.Position = UDim2.new(0.74, 0, 0.06, 0)
	newPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
	newPanel.BorderSizePixel = 0
	newPanel.Visible = false
	newPanel.ZIndex = 9
	newPanel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = newPanel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(60, 60, 100)
	panelStroke.Thickness = 1
	panelStroke.Parent = newPanel

	-- Panel title
	local panelTitle = Instance.new("TextLabel")
	panelTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	panelTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	panelTitle.BackgroundTransparency = 1
	panelTitle.Text = "Server Archetypes"
	panelTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
	panelTitle.TextScaled = true
	panelTitle.Font = Enum.Font.GothamBold
	panelTitle.Parent = newPanel

	-- Top archetype label
	local topLabel = Instance.new("TextLabel")
	topLabel.Name = "TopArchetype"
	topLabel.Size = UDim2.new(0.9, 0, 0.05, 0)
	topLabel.Position = UDim2.new(0.05, 0, 0.09, 0)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = "No results yet"
	topLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	topLabel.TextScaled = true
	topLabel.Font = Enum.Font.Gotham
	topLabel.Parent = newPanel

	-- Scrolling content area for player entries
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PlayerList"
	scrollFrame.Size = UDim2.new(0.9, 0, 0.78, 0)
	scrollFrame.Position = UDim2.new(0.05, 0, 0.16, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = newPanel

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = scrollFrame

	panel = newPanel
	contentFrame = scrollFrame

	toggleButton.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		newPanel.Visible = isOpen
	end)
end

function LeaderboardUI.update(data: { { name: string, archetypeId: string, archetypeName: string } })
	if not panel or not contentFrame then
		return
	end

	-- Clear existing entries
	for _, child in contentFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Find most common archetype
	local counts: { [string]: number } = {}
	for _, entry in data do
		counts[entry.archetypeName] = (counts[entry.archetypeName] or 0) + 1
	end

	local topName = "None"
	local topCount = 0
	for name, count in counts do
		if count > topCount then
			topCount = count
			topName = name
		end
	end

	local topLabel = panel:FindFirstChild("TopArchetype") :: TextLabel
	if topLabel then
		if #data > 0 then
			topLabel.Text = "Top: " .. topName .. " (" .. topCount .. " players)"
		else
			topLabel.Text = "No results yet"
		end
	end

	-- Add player entries
	for i, entry in data do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 28)
		label.BackgroundTransparency = 1
		label.Text = entry.name .. " - " .. entry.archetypeName
		label.TextColor3 = Color3.fromRGB(200, 200, 220)
		label.TextScaled = true
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = i
		label.Parent = contentFrame
	end

	-- Update canvas size
	local listLayout = contentFrame:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end
end

return LeaderboardUI
