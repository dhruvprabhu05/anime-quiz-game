local TweenService = game:GetService("TweenService")

local LeaderboardUI = {}

local panel: Frame? = nil
local contentFrame: Frame? = nil
local isOpen: boolean = false

function LeaderboardUI.build(screenGui: ScreenGui)
	local UIEffects = require(script.Parent:WaitForChild("UIEffects"))

	local existing = screenGui:FindFirstChild("LeaderboardPanel")
	if existing then
		existing:Destroy()
	end

	-- Remove old toggle if present
	local existingToggle = screenGui:FindFirstChild("LeaderboardToggle")
	if existingToggle then
		existingToggle:Destroy()
	end

	-- Toggle button (always visible, top right)
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "LeaderboardToggle"
	toggleButton.Size = UDim2.new(0, 160, 0, 36)
	toggleButton.Position = UDim2.new(1, -170, 0, 50)
	toggleButton.BackgroundColor3 = UIEffects.COLORS.bg
	toggleButton.BackgroundTransparency = 0.2
	toggleButton.Text = "[ LEADERBOARD ]"
	toggleButton.TextColor3 = UIEffects.COLORS.neonCyan
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.RobotoMono
	toggleButton.ZIndex = 12
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 6)
	toggleCorner.Parent = toggleButton

	UIEffects.addNeonButton(toggleButton, UIEffects.COLORS.neonCyan)

	local togglePadding = Instance.new("UIPadding")
	togglePadding.PaddingLeft = UDim.new(0, 8)
	togglePadding.PaddingRight = UDim.new(0, 8)
	togglePadding.Parent = toggleButton

	-- Side panel
	local newPanel = Instance.new("Frame")
	newPanel.Name = "LeaderboardPanel"
	newPanel.Size = UDim2.new(0.23, 0, 0.7, 0)
	newPanel.Position = UDim2.new(0.76, 0, 0.12, 0)
	newPanel.BackgroundColor3 = UIEffects.COLORS.bgPanel
	newPanel.BorderSizePixel = 0
	newPanel.Visible = false
	newPanel.ZIndex = 11
	newPanel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = newPanel

	UIEffects.applyDarkGlass(newPanel)
	UIEffects.addNeonPulse(newPanel, UIEffects.COLORS.neonPurple, 2)

	-- Panel title
	local panelTitle = Instance.new("TextLabel")
	panelTitle.Size = UDim2.new(0.85, 0, 0.06, 0)
	panelTitle.Position = UDim2.new(0.075, 0, 0.03, 0)
	panelTitle.BackgroundTransparency = 1
	panelTitle.Text = "SERVER ARCHETYPES"
	panelTitle.TextColor3 = UIEffects.COLORS.neonCyan
	panelTitle.TextScaled = true
	panelTitle.Font = Enum.Font.RobotoMono
	panelTitle.ZIndex = 12
	panelTitle.Parent = newPanel

	-- Divider under title
	local titleDivider = Instance.new("Frame")
	titleDivider.Size = UDim2.new(0.85, 0, 0, 1)
	titleDivider.Position = UDim2.new(0.075, 0, 0.1, 0)
	titleDivider.BackgroundColor3 = UIEffects.COLORS.neonCyan
	titleDivider.BackgroundTransparency = 0.4
	titleDivider.BorderSizePixel = 0
	titleDivider.ZIndex = 12
	titleDivider.Parent = newPanel

	-- Top archetype label
	local topLabel = Instance.new("TextLabel")
	topLabel.Name = "TopArchetype"
	topLabel.Size = UDim2.new(0.85, 0, 0.05, 0)
	topLabel.Position = UDim2.new(0.075, 0, 0.12, 0)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = "No results yet"
	topLabel.TextColor3 = UIEffects.COLORS.textSecondary
	topLabel.TextScaled = true
	topLabel.Font = Enum.Font.RobotoMono
	topLabel.ZIndex = 12
	topLabel.Parent = newPanel

	-- Scrolling content area
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PlayerList"
	scrollFrame.Size = UDim2.new(0.85, 0, 0.75, 0)
	scrollFrame.Position = UDim2.new(0.075, 0, 0.19, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 3
	scrollFrame.ScrollBarImageColor3 = UIEffects.COLORS.neonPurple
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.ZIndex = 12
	scrollFrame.Parent = newPanel

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = scrollFrame

	panel = newPanel
	contentFrame = scrollFrame

	toggleButton.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			newPanel.Visible = true
			newPanel.BackgroundTransparency = 1
			TweenService:Create(newPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			}):Play()
		else
			TweenService:Create(newPanel, TweenInfo.new(0.15), {
				BackgroundTransparency = 1,
			}):Play()
			task.delay(0.15, function()
				if not isOpen then
					newPanel.Visible = false
				end
			end)
		end
	end)
end

function LeaderboardUI.update(data: { { name: string, archetypeId: string, archetypeName: string } })
	if not panel or not contentFrame then
		return
	end

	for _, child in contentFrame:GetChildren() do
		if child:IsA("Frame") then
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
			topLabel.Text = "Most common: " .. topName .. " (" .. topCount .. ")"
		else
			topLabel.Text = "No results yet"
		end
	end

	-- Add player entries as styled rows
	for i, entry in data do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundColor3 = UIEffects.COLORS.bgCard
		row.BackgroundTransparency = if i % 2 == 0 then 0.3 else 0.45
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.ZIndex = 13
		row.Parent = contentFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.03, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.name
		nameLabel.TextColor3 = UIEffects.COLORS.textPrimary
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.RobotoMono
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 14
		nameLabel.Parent = row

		local archLabel = Instance.new("TextLabel")
		archLabel.Size = UDim2.new(0.48, 0, 1, 0)
		archLabel.Position = UDim2.new(0.5, 0, 0, 0)
		archLabel.BackgroundTransparency = 1
		archLabel.Text = entry.archetypeName
		archLabel.TextColor3 = UIEffects.COLORS.neonGold
		archLabel.TextScaled = true
		archLabel.Font = Enum.Font.RobotoMono
		archLabel.TextXAlignment = Enum.TextXAlignment.Right
		archLabel.ZIndex = 14
		archLabel.Parent = row
	end

	-- Update canvas size
	local listLayout = contentFrame:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end
end

return LeaderboardUI
