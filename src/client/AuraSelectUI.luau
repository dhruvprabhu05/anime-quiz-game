local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

local AuraSelectUI = {}

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

local ARCHETYPE_ICONS: { [string]: string } = {
	hot_headed_hero = "🔥",
	cool_strategist = "🧠",
	lone_wolf = "🐺",
	gentle_protector = "🛡️",
	chaotic_wildcard = "⚡",
	silent_powerhouse = "💪",
	loyal_companion = "❤️",
	wise_mentor = "📖",
	rebel_with_a_cause = "⚔️",
	cheerful_optimist = "☀️",
}

function AuraSelectUI.build(screenGui: ScreenGui, unlockedIds: { string }, currentAura: string, onBack: () -> ())
	local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
	local C = UIEffects.COLORS

	local existing = screenGui:FindFirstChild("AuraSelectFrame")
	if existing then
		existing:Destroy()
	end

	local unlockedSet: { [string]: boolean } = {}
	for _, id in unlockedIds do
		unlockedSet[id] = true
	end

	-- Root frame: near-black background
	local frame = Instance.new("Frame")
	frame.Name = "AuraSelectFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = C.bg
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	UIEffects.addGradient(frame, Color3.fromRGB(8, 4, 20), Color3.fromRGB(4, 10, 25), 160)
	UIEffects.addDigitalParticles(frame, 18)
	UIEffects.addScanLine(frame)

	-- Title: neonMagenta
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.5, 0, 0.065, 0)
	title.Position = UDim2.new(0.25, 0, 0.025, 0)
	title.BackgroundTransparency = 1
	title.Text = "CHOOSE YOUR AURA"
	title.TextColor3 = C.neonMagenta
	title.TextScaled = true
	title.Font = Enum.Font.RobotoMono
	title.ZIndex = 3
	title.Parent = frame

	UIEffects.addGlow(title, C.neonMagenta, 1)

	-- Subtitle: monospace, textSecondary
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.52, 0, 0.033, 0)
	subtitle.Position = UDim2.new(0.24, 0, 0.093, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Select an aura from your unlocked archetypes"
	subtitle.TextColor3 = C.textSecondary
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.RobotoMono
	subtitle.ZIndex = 3
	subtitle.Parent = frame

	UIEffects.addDivider(frame, 0.135, C.neonMagenta)

	-- Status label: neonCyan monospace
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(0.42, 0, 0.035, 0)
	statusLabel.Position = UDim2.new(0.29, 0, 0.89, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = C.neonCyan
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.RobotoMono
	statusLabel.ZIndex = 3
	statusLabel.Parent = frame

	-- Grid of archetype aura cards (2 columns, 5 rows)
	local allArchetypes = Archetypes.list
	for i, archetype in allArchetypes do
		local row = math.ceil(i / 2)
		local col = ((i - 1) % 2) + 1
		local isUnlocked = unlockedSet[archetype.id] == true
		local isActive = archetype.id == currentAura
		local accentColor = ARCHETYPE_COLORS[archetype.id] or Color3.fromRGB(100, 100, 150)
		local icon = ARCHETYPE_ICONS[archetype.id] or "?"

		local cardX = if col == 1 then 0.06 else 0.52
		local cardY = 0.15 + (row - 1) * 0.145

		local card = Instance.new("TextButton")
		card.Name = "AuraCard_" .. archetype.id
		card.Size = UDim2.new(0.42, 0, 0.13, 0)
		card.Position = UDim2.new(cardX, 0, cardY, 0)
		card.BorderSizePixel = 0
		card.Text = ""
		card.AutoButtonColor = false
		card.ZIndex = 3
		card.Parent = frame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 12)
		cardCorner.Parent = card

		-- Dark glass base (extra dim for locked cards)
		UIEffects.applyDarkGlass(card)

		-- Locked cards: very dim via additional transparency overlay
		if not isUnlocked then
			local dimOverlay = Instance.new("Frame")
			dimOverlay.Size = UDim2.new(1, 0, 1, 0)
			dimOverlay.BackgroundColor3 = C.bg
			dimOverlay.BackgroundTransparency = 0.35
			dimOverlay.BorderSizePixel = 0
			dimOverlay.ZIndex = card.ZIndex + 1
			dimOverlay.Parent = card

			local dimCorner = Instance.new("UICorner")
			dimCorner.CornerRadius = UDim.new(0, 12)
			dimCorner.Parent = dimOverlay
		end

		-- Border: equipped card gets neonPulse, unlocked gets accent border, locked gets dim border
		if isActive then
			local stroke = Instance.new("UIStroke")
			stroke.Color = accentColor
			stroke.Thickness = 2
			stroke.Transparency = 0
			stroke.Parent = card
			UIEffects.addNeonPulse(card, accentColor, 2)
		elseif isUnlocked then
			local stroke = Instance.new("UIStroke")
			stroke.Color = accentColor
			stroke.Thickness = 1.5
			stroke.Transparency = 0.4
			stroke.Parent = card
		else
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(28, 26, 45)
			stroke.Thickness = 1
			stroke.Transparency = 0.5
			stroke.Parent = card
		end

		-- Left color accent stripe
		local leftAccent = Instance.new("Frame")
		leftAccent.Size = UDim2.new(0, 4, 0.7, 0)
		leftAccent.Position = UDim2.new(0, 0, 0.15, 0)
		leftAccent.BackgroundColor3 = if isUnlocked then accentColor else Color3.fromRGB(35, 33, 55)
		leftAccent.BackgroundTransparency = if isUnlocked then 0 else 0.65
		leftAccent.BorderSizePixel = 0
		leftAccent.ZIndex = 4
		leftAccent.Parent = card

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(1, 0)
		accentCorner.Parent = leftAccent

		-- Icon (lock icon for locked cards)
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 30, 0, 30)
		iconLabel.Position = UDim2.new(0, 12, 0.5, -15)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = if isUnlocked then icon else "🔒"
		iconLabel.TextScaled = true
		iconLabel.ZIndex = 5
		iconLabel.Parent = card

		-- Name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.55, 0, 0.35, 0)
		nameLabel.Position = UDim2.new(0.18, 0, 0.1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = if isUnlocked then archetype.name else "???"
		nameLabel.TextColor3 = if isUnlocked then accentColor else C.textMuted
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 5
		nameLabel.Parent = card

		-- Example characters / unlock hint
		local exLabel = Instance.new("TextLabel")
		exLabel.Size = UDim2.new(0.55, 0, 0.25, 0)
		exLabel.Position = UDim2.new(0.18, 0, 0.45, 0)
		exLabel.BackgroundTransparency = 1
		exLabel.Text = if isUnlocked then table.concat(archetype.examples, ", ") else "Take the quiz to unlock"
		exLabel.TextColor3 = if isUnlocked then C.textSecondary else C.textMuted
		exLabel.TextScaled = true
		exLabel.Font = Enum.Font.Gotham
		exLabel.TextXAlignment = Enum.TextXAlignment.Left
		exLabel.ZIndex = 5
		exLabel.Parent = card

		-- "EQUIPPED" or "SELECT" badge on right side
		if isUnlocked then
			local badge = Instance.new("TextLabel")
			badge.Size = UDim2.new(0.2, 0, 0.3, 0)
			badge.Position = UDim2.new(0.77, 0, 0.35, 0)
			-- EQUIPPED: neon filled with archetype color; SELECT: dark with textMuted
			badge.BackgroundColor3 = if isActive then accentColor else Color3.fromRGB(10, 9, 22)
			badge.BackgroundTransparency = if isActive then 0.1 else 0.3
			badge.Text = if isActive then "EQUIPPED" else "SELECT"
			badge.TextColor3 = if isActive then Color3.fromRGB(255, 255, 255) else C.textMuted
			badge.TextScaled = true
			badge.Font = Enum.Font.GothamBold
			badge.ZIndex = 6
			badge.Parent = card

			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 6)
			badgeCorner.Parent = badge

			-- Neon stroke on EQUIPPED badge
			if isActive then
				local badgeStroke = Instance.new("UIStroke")
				badgeStroke.Color = accentColor
				badgeStroke.Thickness = 1.5
				badgeStroke.Transparency = 0.1
				badgeStroke.Parent = badge
			end
		end

		-- Click handler
		if isUnlocked and not isActive then
			UIEffects.addButtonHover(card, Color3.fromRGB(10, 9, 22))

			card.MouseButton1Click:Connect(function()
				local selectRemote = Remotes.get("SelectAura") :: RemoteFunction
				local success = selectRemote:InvokeServer(archetype.id)

				if success then
					statusLabel.Text = "> Aura switched to " .. archetype.name
					statusLabel.TextColor3 = C.neonCyan

					-- Fade out status after 2 seconds
					task.delay(2, function()
						TweenService:Create(statusLabel, TweenInfo.new(0.5), {
							TextTransparency = 1,
						}):Play()
						task.wait(0.5)
						statusLabel.Text = ""
						statusLabel.TextTransparency = 0
					end)

					-- Rebuild the UI to reflect the change
					AuraSelectUI.build(screenGui, unlockedIds, archetype.id, onBack)
					local newFrame = screenGui:FindFirstChild("AuraSelectFrame")
					if newFrame then
						newFrame.Visible = true
					end
				end
			end)
		end

		-- Staggered entrance
		card.BackgroundTransparency = 1
		nameLabel.TextTransparency = 1
		exLabel.TextTransparency = 1
		iconLabel.TextTransparency = 1

		task.delay(i * 0.03, function()
			TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
			TweenService:Create(exLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
			TweenService:Create(iconLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
		end)
	end

	-- Back button: dark glass + neonButton with neonPurple
	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0.12, 0, 0.05, 0)
	backButton.Position = UDim2.new(0.44, 0, 0.93, 0)
	backButton.BorderSizePixel = 0
	backButton.Text = "BACK"
	backButton.TextColor3 = C.neonPurple
	backButton.TextScaled = true
	backButton.Font = Enum.Font.GothamBold
	backButton.AutoButtonColor = false
	backButton.ZIndex = 3
	backButton.Parent = frame

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 12)
	backCorner.Parent = backButton

	UIEffects.applyDarkGlass(backButton)
	UIEffects.addNeonButton(backButton, C.neonPurple)

	backButton.MouseButton1Click:Connect(function()
		onBack()
	end)
end

return AuraSelectUI
