local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))
local AuraRarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraRarities"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local SpinWheelUI = {}

local ENTRY_HEIGHT = 50
local VISIBLE_ENTRIES = 5
local SPIN_REPEATS = 8
local SPIN_DURATION = 4

local function getAuraDisplayName(auraId: string): string
	if auraId == "anime_transformation" then
		return "??? ANIME TRANSFORMATION ???"
	end
	local archetype = Archetypes.getById(auraId)
	if archetype then
		return archetype.name
	end
	return auraId
end

local function getRarityForAura(auraId: string): { name: string, color: Color3 }
	local rarity = AuraRarities.getRarityForAura(auraId)
	if rarity then
		return { name = rarity.name, color = rarity.color }
	end
	return { name = "Unknown", color = Color3.fromRGB(200, 200, 200) }
end

local function makeButton(parent: GuiObject, text: string, pos: UDim2, size: UDim2, neonColor: Color3, UIEffects: any, zIndex: number?): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = pos
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BackgroundColor3 = Color3.fromRGB(22, 18, 45)
	btn.BackgroundTransparency = 0
	btn.BorderSizePixel = 0
	btn.ZIndex = zIndex or 5
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = neonColor
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = btn

	UIEffects.addNeonButton(btn, neonColor)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = btn

	return btn
end

function SpinWheelUI.build(screenGui: ScreenGui, spinData: { freeSpinsAvailable: number, buy1SpinProductId: number, buy5SpinsProductId: number }, onBack: () -> (), onInventory: () -> ())
	local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
	local C = UIEffects.COLORS

	local existing = screenGui:FindFirstChild("SpinWheelFrame")
	if existing then
		existing:Destroy()
	end

	local player = Players.LocalPlayer
	local freeSpins = spinData.freeSpinsAvailable
	local isSpinning = false

	-- ============================================================
	-- Root frame
	-- ============================================================
	local frame = Instance.new("Frame")
	frame.Name = "SpinWheelFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = C.bg
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	UIEffects.addGradient(frame, Color3.fromRGB(8, 4, 20), Color3.fromRGB(4, 10, 25), 160)
	UIEffects.addDigitalParticles(frame, 18)

	-- ============================================================
	-- Title
	-- ============================================================
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.5, 0, 0.065, 0)
	title.Position = UDim2.new(0.25, 0, 0.025, 0)
	title.BackgroundTransparency = 1
	title.Text = "SPIN WHEEL"
	title.TextColor3 = C.neonGold
	title.TextScaled = true
	title.Font = Enum.Font.RobotoMono
	title.ZIndex = 3
	title.Parent = frame

	UIEffects.addGlow(title, C.neonGold, 1)

	-- Free spins counter
	local freeSpinsLabel = Instance.new("TextLabel")
	freeSpinsLabel.Size = UDim2.new(0.3, 0, 0.04, 0)
	freeSpinsLabel.Position = UDim2.new(0.35, 0, 0.095, 0)
	freeSpinsLabel.BackgroundTransparency = 1
	freeSpinsLabel.Text = "FREE SPINS: " .. freeSpins
	freeSpinsLabel.TextColor3 = C.neonCyan
	freeSpinsLabel.TextScaled = true
	freeSpinsLabel.Font = Enum.Font.RobotoMono
	freeSpinsLabel.ZIndex = 3
	freeSpinsLabel.Parent = frame

	UIEffects.addGlow(freeSpinsLabel, C.neonCyan, 1)

	-- Divider
	UIEffects.addDivider(frame, 0.14, C.neonGold)

	-- ============================================================
	-- Slot machine container
	-- ============================================================
	local windowHeight = VISIBLE_ENTRIES * ENTRY_HEIGHT

	-- Odds panel (right side of screen)
	local oddsPanel = Instance.new("Frame")
	oddsPanel.Name = "OddsPanel"
	oddsPanel.Size = UDim2.new(0.18, 0, 0, windowHeight + 20)
	oddsPanel.Position = UDim2.new(0.8, 0, 0.18, 0)
	oddsPanel.BackgroundColor3 = Color3.fromRGB(12, 10, 28)
	oddsPanel.BackgroundTransparency = 0
	oddsPanel.BorderSizePixel = 0
	oddsPanel.ZIndex = 3
	oddsPanel.Parent = frame

	local oddsPanelCorner = Instance.new("UICorner")
	oddsPanelCorner.CornerRadius = UDim.new(0, 10)
	oddsPanelCorner.Parent = oddsPanel

	local oddsPanelStroke = Instance.new("UIStroke")
	oddsPanelStroke.Color = C.neonPurple
	oddsPanelStroke.Thickness = 1
	oddsPanelStroke.Transparency = 0.4
	oddsPanelStroke.Parent = oddsPanel

	-- Odds title
	local oddsTitle = Instance.new("TextLabel")
	oddsTitle.Size = UDim2.new(0.9, 0, 0.08, 0)
	oddsTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	oddsTitle.BackgroundTransparency = 1
	oddsTitle.Text = "DROP RATES"
	oddsTitle.TextColor3 = C.neonPurple
	oddsTitle.TextScaled = true
	oddsTitle.Font = Enum.Font.GothamBold
	oddsTitle.ZIndex = 4
	oddsTitle.Parent = oddsPanel

	-- List each rarity with its drop rate
	for i, rarity in AuraRarities.list do
		local entryY = 0.1 + (i - 1) * 0.145

		-- Rarity color dot
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 8, 0, 8)
		dot.Position = UDim2.new(0.08, 0, entryY + 0.03, 0)
		dot.BackgroundColor3 = rarity.color
		dot.BorderSizePixel = 0
		dot.ZIndex = 4
		dot.Parent = oddsPanel

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dot

		-- Rarity name
		local rarityName = Instance.new("TextLabel")
		rarityName.Size = UDim2.new(0.55, 0, 0.06, 0)
		rarityName.Position = UDim2.new(0.22, 0, entryY, 0)
		rarityName.BackgroundTransparency = 1
		rarityName.Text = rarity.name
		rarityName.TextColor3 = rarity.color
		rarityName.TextScaled = true
		rarityName.Font = Enum.Font.GothamBold
		rarityName.TextXAlignment = Enum.TextXAlignment.Left
		rarityName.ZIndex = 4
		rarityName.Parent = oddsPanel

		-- Percentage
		local pctText = string.format("%.1f%%", rarity.dropRate * 100)
		if rarity.dropRate < 0.01 then
			pctText = string.format("%.1f%%", rarity.dropRate * 100)
		end

		local pctLabel = Instance.new("TextLabel")
		pctLabel.Size = UDim2.new(0.55, 0, 0.05, 0)
		pctLabel.Position = UDim2.new(0.22, 0, entryY + 0.06, 0)
		pctLabel.BackgroundTransparency = 1
		pctLabel.Text = pctText
		pctLabel.TextColor3 = C.textSecondary
		pctLabel.TextScaled = true
		pctLabel.Font = Enum.Font.RobotoMono
		pctLabel.TextXAlignment = Enum.TextXAlignment.Left
		pctLabel.ZIndex = 4
		pctLabel.Parent = oddsPanel
	end

	-- Slot machine (shifted left to make room for odds panel)
	local slotContainer = Instance.new("Frame")
	slotContainer.Name = "SlotContainer"
	slotContainer.Size = UDim2.new(0.52, 0, 0, windowHeight + 20)
	slotContainer.Position = UDim2.new(0.4, 0, 0.18, 0)
	slotContainer.AnchorPoint = Vector2.new(0.5, 0)
	slotContainer.ZIndex = 3
	slotContainer.Parent = frame
	UIEffects.applyDarkGlass(slotContainer)
	UIEffects.addNeonPulse(slotContainer, C.neonGold, 2)

	-- Clipping window inside container
	local clipWindow = Instance.new("Frame")
	clipWindow.Name = "ClipWindow"
	clipWindow.Size = UDim2.new(1, -16, 1, -16)
	clipWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	clipWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	clipWindow.BackgroundTransparency = 1
	clipWindow.ClipsDescendants = true
	clipWindow.ZIndex = 4
	clipWindow.Parent = slotContainer

	-- Scrolling inner frame (we tween its Position.Y)
	local scrollFrame = Instance.new("Frame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, 0, 0, 0) -- resized dynamically
	scrollFrame.Position = UDim2.new(0, 0, 0, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ZIndex = 4
	scrollFrame.Parent = clipWindow

	-- Center highlight bar
	local highlightBar = Instance.new("Frame")
	highlightBar.Name = "HighlightBar"
	highlightBar.Size = UDim2.new(1, 0, 0, ENTRY_HEIGHT)
	highlightBar.Position = UDim2.new(0, 0, 0, ENTRY_HEIGHT * 2) -- 3rd of 5 = index 2
	highlightBar.BackgroundColor3 = C.neonGold
	highlightBar.BackgroundTransparency = 0.85
	highlightBar.BorderSizePixel = 0
	highlightBar.ZIndex = 5
	highlightBar.Parent = clipWindow

	local highlightCorner = Instance.new("UICorner")
	highlightCorner.CornerRadius = UDim.new(0, 4)
	highlightCorner.Parent = highlightBar

	UIEffects.addGlow(highlightBar, C.neonGold, 1.5)

	-- Pointer arrow on the right
	local pointer = Instance.new("TextLabel")
	pointer.Size = UDim2.new(0, 30, 0, ENTRY_HEIGHT)
	pointer.Position = UDim2.new(1, 4, 0, ENTRY_HEIGHT * 2)
	pointer.BackgroundTransparency = 1
	pointer.Text = "▶"
	pointer.TextColor3 = C.neonGold
	pointer.TextScaled = true
	pointer.Font = Enum.Font.GothamBold
	pointer.ZIndex = 6
	pointer.Parent = clipWindow

	-- ============================================================
	-- Build the list of entries
	-- ============================================================
	local allAuraIds = AuraRarities.getAllAuraIds()

	local function buildSpinList(targetAuraId: string): number
		-- Clear existing entries
		for _, child in scrollFrame:GetChildren() do
			child:Destroy()
		end

		-- Build repeated shuffled list
		local entries: { string } = {}
		for _ = 1, SPIN_REPEATS do
			local shuffled = table.clone(allAuraIds)
			-- Fisher-Yates shuffle
			for i = #shuffled, 2, -1 do
				local j = math.random(1, i)
				shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
			end
			for _, id in shuffled do
				table.insert(entries, id)
			end
		end

		-- Place target near the end (leave ~5 entries after it for deceleration visual)
		local targetIndex = #entries - 7
		entries[targetIndex] = targetAuraId

		-- Create entry frames
		for i, auraId in entries do
			local rarity = getRarityForAura(auraId)

			local entry = Instance.new("Frame")
			entry.Name = "Entry_" .. i
			entry.Size = UDim2.new(1, 0, 0, ENTRY_HEIGHT)
			entry.Position = UDim2.new(0, 0, 0, (i - 1) * ENTRY_HEIGHT)
			entry.BackgroundTransparency = 1
			entry.ZIndex = 4
			entry.Parent = scrollFrame

			-- Rarity color stripe on left
			local stripe = Instance.new("Frame")
			stripe.Size = UDim2.new(0, 5, 0.7, 0)
			stripe.Position = UDim2.new(0, 4, 0.15, 0)
			stripe.BackgroundColor3 = rarity.color
			stripe.BorderSizePixel = 0
			stripe.ZIndex = 5
			stripe.Parent = entry

			local stripeCorner = Instance.new("UICorner")
			stripeCorner.CornerRadius = UDim.new(0, 2)
			stripeCorner.Parent = stripe

			-- Aura name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, 0, 0.55, 0)
			nameLabel.Position = UDim2.new(0, 16, 0.05, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = getAuraDisplayName(auraId)
			nameLabel.TextColor3 = C.textPrimary
			nameLabel.TextScaled = true
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.ZIndex = 5
			nameLabel.Parent = entry

			-- Rarity name
			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Size = UDim2.new(0.4, 0, 0.35, 0)
			rarityLabel.Position = UDim2.new(0, 16, 0.55, 0)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Text = rarity.name
			rarityLabel.TextColor3 = rarity.color
			rarityLabel.TextScaled = true
			rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
			rarityLabel.Font = Enum.Font.RobotoMono
			rarityLabel.ZIndex = 5
			rarityLabel.Parent = entry

			-- Subtle separator line
			if i < #entries then
				local sep = Instance.new("Frame")
				sep.Size = UDim2.new(0.9, 0, 0, 1)
				sep.Position = UDim2.new(0.05, 0, 1, -1)
				sep.BackgroundColor3 = C.textMuted
				sep.BackgroundTransparency = 0.7
				sep.BorderSizePixel = 0
				sep.ZIndex = 5
				sep.Parent = entry
			end
		end

		scrollFrame.Size = UDim2.new(1, 0, 0, #entries * ENTRY_HEIGHT)

		-- Return the Y offset to land target in center slot
		-- Center slot is at index 2 (0-indexed) within the visible window
		local targetY = (targetIndex - 1) * ENTRY_HEIGHT - (2 * ENTRY_HEIGHT)
		return targetY
	end

	-- Build initial idle list (just show shuffled auras, no target)
	do
		local entries: { string } = {}
		for _ = 1, 3 do
			local shuffled = table.clone(allAuraIds)
			for i = #shuffled, 2, -1 do
				local j = math.random(1, i)
				shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
			end
			for _, id in shuffled do
				table.insert(entries, id)
			end
		end

		for i, auraId in entries do
			local rarity = getRarityForAura(auraId)

			local entry = Instance.new("Frame")
			entry.Name = "Entry_" .. i
			entry.Size = UDim2.new(1, 0, 0, ENTRY_HEIGHT)
			entry.Position = UDim2.new(0, 0, 0, (i - 1) * ENTRY_HEIGHT)
			entry.BackgroundTransparency = 1
			entry.ZIndex = 4
			entry.Parent = scrollFrame

			local stripe = Instance.new("Frame")
			stripe.Size = UDim2.new(0, 5, 0.7, 0)
			stripe.Position = UDim2.new(0, 4, 0.15, 0)
			stripe.BackgroundColor3 = rarity.color
			stripe.BorderSizePixel = 0
			stripe.ZIndex = 5
			stripe.Parent = entry

			local stripeCorner = Instance.new("UICorner")
			stripeCorner.CornerRadius = UDim.new(0, 2)
			stripeCorner.Parent = stripe

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, 0, 0.55, 0)
			nameLabel.Position = UDim2.new(0, 16, 0.05, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = getAuraDisplayName(auraId)
			nameLabel.TextColor3 = C.textPrimary
			nameLabel.TextScaled = true
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.ZIndex = 5
			nameLabel.Parent = entry

			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Size = UDim2.new(0.4, 0, 0.35, 0)
			rarityLabel.Position = UDim2.new(0, 16, 0.55, 0)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Text = rarity.name
			rarityLabel.TextColor3 = rarity.color
			rarityLabel.TextScaled = true
			rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
			rarityLabel.Font = Enum.Font.RobotoMono
			rarityLabel.ZIndex = 5
			rarityLabel.Parent = entry

			if i < #entries then
				local sep = Instance.new("Frame")
				sep.Size = UDim2.new(0.9, 0, 0, 1)
				sep.Position = UDim2.new(0.05, 0, 1, -1)
				sep.BackgroundColor3 = C.textMuted
				sep.BackgroundTransparency = 0.7
				sep.BorderSizePixel = 0
				sep.ZIndex = 5
				sep.Parent = entry
			end
		end

		scrollFrame.Size = UDim2.new(1, 0, 0, #entries * ENTRY_HEIGHT)
	end

	-- ============================================================
	-- Result overlay (hidden until spin completes)
	-- ============================================================
	local resultOverlay = Instance.new("Frame")
	resultOverlay.Name = "ResultOverlay"
	resultOverlay.Size = UDim2.new(1, 0, 1, 0)
	resultOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	resultOverlay.BackgroundTransparency = 0.3
	resultOverlay.BorderSizePixel = 0
	resultOverlay.Visible = false
	resultOverlay.ZIndex = 10
	resultOverlay.Parent = frame

	-- Flash frame (full screen, rarity color)
	local flashFrame = Instance.new("Frame")
	flashFrame.Name = "Flash"
	flashFrame.Size = UDim2.new(1, 0, 1, 0)
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.ZIndex = 11
	flashFrame.Parent = resultOverlay

	-- Result card (centered dark panel)
	local resultCard = Instance.new("Frame")
	resultCard.Name = "ResultCard"
	resultCard.Size = UDim2.new(0.4, 0, 0.45, 0)
	resultCard.Position = UDim2.new(0.3, 0, 0.2, 0)
	resultCard.BackgroundColor3 = Color3.fromRGB(12, 10, 28)
	resultCard.BackgroundTransparency = 0
	resultCard.BorderSizePixel = 0
	resultCard.ZIndex = 12
	resultCard.Parent = resultOverlay

	local resultCardCorner = Instance.new("UICorner")
	resultCardCorner.CornerRadius = UDim.new(0, 14)
	resultCardCorner.Parent = resultCard

	local resultCardStroke = Instance.new("UIStroke")
	resultCardStroke.Name = "CardStroke"
	resultCardStroke.Color = C.neonGold
	resultCardStroke.Thickness = 2
	resultCardStroke.Parent = resultCard

	-- Archetype icon (emoji) at top of card
	local ARCHETYPE_ICONS = {
		hot_headed_hero = "🔥", cool_strategist = "🧠", lone_wolf = "🐺",
		gentle_protector = "🛡️", chaotic_wildcard = "⚡", silent_powerhouse = "💪",
		loyal_companion = "❤️", wise_mentor = "📖", rebel_with_a_cause = "⚔️",
		cheerful_optimist = "☀️", anime_transformation = "✨",
	}

	local resultIcon = Instance.new("TextLabel")
	resultIcon.Name = "ResultIcon"
	resultIcon.Size = UDim2.new(0.3, 0, 0.25, 0)
	resultIcon.Position = UDim2.new(0.35, 0, 0.05, 0)
	resultIcon.BackgroundTransparency = 1
	resultIcon.Text = "✨"
	resultIcon.TextScaled = true
	resultIcon.ZIndex = 13
	resultIcon.Parent = resultCard

	-- "YOU GOT" label
	local youGotLabel = Instance.new("TextLabel")
	youGotLabel.Size = UDim2.new(0.8, 0, 0.08, 0)
	youGotLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
	youGotLabel.BackgroundTransparency = 1
	youGotLabel.Text = "YOU GOT"
	youGotLabel.TextColor3 = C.textSecondary
	youGotLabel.TextScaled = true
	youGotLabel.Font = Enum.Font.RobotoMono
	youGotLabel.ZIndex = 13
	youGotLabel.Parent = resultCard

	-- Result aura name (large, white, bold)
	local resultName = Instance.new("TextLabel")
	resultName.Size = UDim2.new(0.85, 0, 0.14, 0)
	resultName.Position = UDim2.new(0.075, 0, 0.38, 0)
	resultName.BackgroundTransparency = 1
	resultName.Text = ""
	resultName.TextColor3 = Color3.fromRGB(255, 255, 255)
	resultName.TextScaled = true
	resultName.Font = Enum.Font.GothamBlack
	resultName.ZIndex = 13
	resultName.Parent = resultCard

	-- Rarity name (colored)
	local resultRarity = Instance.new("TextLabel")
	resultRarity.Size = UDim2.new(0.5, 0, 0.07, 0)
	resultRarity.Position = UDim2.new(0.25, 0, 0.54, 0)
	resultRarity.BackgroundTransparency = 1
	resultRarity.Text = ""
	resultRarity.TextColor3 = C.neonGold
	resultRarity.TextScaled = true
	resultRarity.Font = Enum.Font.RobotoMono
	resultRarity.ZIndex = 13
	resultRarity.Parent = resultCard

	-- Divider
	local resultDivider = Instance.new("Frame")
	resultDivider.Size = UDim2.new(0.6, 0, 0, 1)
	resultDivider.Position = UDim2.new(0.2, 0, 0.63, 0)
	resultDivider.BackgroundColor3 = C.neonGold
	resultDivider.BackgroundTransparency = 0.5
	resultDivider.BorderSizePixel = 0
	resultDivider.ZIndex = 13
	resultDivider.Parent = resultCard

	-- NEW! or +X SHARDS badge (large, prominent)
	local resultBadge = Instance.new("TextLabel")
	resultBadge.Size = UDim2.new(0.6, 0, 0.12, 0)
	resultBadge.Position = UDim2.new(0.2, 0, 0.67, 0)
	resultBadge.BackgroundColor3 = Color3.fromRGB(0, 40, 50)
	resultBadge.BackgroundTransparency = 0
	resultBadge.Text = ""
	resultBadge.TextScaled = true
	resultBadge.Font = Enum.Font.GothamBlack
	resultBadge.ZIndex = 13
	resultBadge.Parent = resultCard

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 8)
	badgeCorner.Parent = resultBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Name = "BadgeStroke"
	badgeStroke.Color = C.neonCyan
	badgeStroke.Thickness = 1.5
	badgeStroke.Parent = resultBadge

	-- Description / example characters
	local resultDesc = Instance.new("TextLabel")
	resultDesc.Name = "ResultDesc"
	resultDesc.Size = UDim2.new(0.8, 0, 0.08, 0)
	resultDesc.Position = UDim2.new(0.1, 0, 0.82, 0)
	resultDesc.BackgroundTransparency = 1
	resultDesc.Text = ""
	resultDesc.TextColor3 = C.textSecondary
	resultDesc.TextScaled = true
	resultDesc.TextWrapped = true
	resultDesc.Font = Enum.Font.Gotham
	resultDesc.ZIndex = 13
	resultDesc.Parent = resultCard

	-- SPIN AGAIN button on result overlay (gold, prominent)
	local resultSpinAgainBtn = Instance.new("TextButton")
	resultSpinAgainBtn.Name = "ResultSpinAgain"
	resultSpinAgainBtn.Size = UDim2.new(0.22, 0, 0.06, 0)
	resultSpinAgainBtn.Position = UDim2.new(0.18, 0, 0.68, 0)
	resultSpinAgainBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 5)
	resultSpinAgainBtn.BackgroundTransparency = 0
	resultSpinAgainBtn.Text = "[ SPIN AGAIN ]"
	resultSpinAgainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	resultSpinAgainBtn.TextScaled = true
	resultSpinAgainBtn.Font = Enum.Font.GothamBold
	resultSpinAgainBtn.ZIndex = 14
	resultSpinAgainBtn.Visible = false
	resultSpinAgainBtn.Parent = resultOverlay

	local rsaCorner = Instance.new("UICorner")
	rsaCorner.CornerRadius = UDim.new(0, 8)
	rsaCorner.Parent = resultSpinAgainBtn

	local rsaStroke = Instance.new("UIStroke")
	rsaStroke.Color = C.neonGold
	rsaStroke.Thickness = 2
	rsaStroke.Transparency = 0.2
	rsaStroke.Parent = resultSpinAgainBtn

	UIEffects.addNeonButton(resultSpinAgainBtn, C.neonGold)

	-- CONTINUE button on result overlay (cyan)
	local continueBtn = Instance.new("TextButton")
	continueBtn.Size = UDim2.new(0.22, 0, 0.06, 0)
	continueBtn.Position = UDim2.new(0.6, 0, 0.68, 0)
	continueBtn.BackgroundColor3 = Color3.fromRGB(0, 35, 45)
	continueBtn.BackgroundTransparency = 0
	continueBtn.Text = "[ CONTINUE ]"
	continueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	continueBtn.TextScaled = true
	continueBtn.Font = Enum.Font.GothamBold
	continueBtn.ZIndex = 14
	continueBtn.Parent = resultOverlay

	local continueBtnCorner = Instance.new("UICorner")
	continueBtnCorner.CornerRadius = UDim.new(0, 8)
	continueBtnCorner.Parent = continueBtn

	local continueBtnStroke = Instance.new("UIStroke")
	continueBtnStroke.Color = C.neonCyan
	continueBtnStroke.Thickness = 2
	continueBtnStroke.Transparency = 0.2
	continueBtnStroke.Parent = continueBtn

	UIEffects.addNeonButton(continueBtn, C.neonCyan)

	continueBtn.MouseButton1Click:Connect(function()
		resultOverlay.Visible = false
	end)

	-- ============================================================
	-- Buttons
	-- ============================================================
	-- Buttons start well below the slot machine
	local btnStartY = 0.7

	-- SPIN x1 — spins if free spins available, otherwise prompts purchase
	local mainSpinBtn = makeButton(frame, "[ SPIN ]", UDim2.new(0.3, 0, btnStartY, 0), UDim2.new(0.3, 0, 0.055, 0), C.neonCyan, UIEffects, 5)

	-- SPIN x5 — bulk spins if 5+ available, otherwise prompts 5-spin purchase
	local bulk5Btn = makeButton(frame, "[ SPIN x5 ]", UDim2.new(0.7, 0, btnStartY, 0), UDim2.new(0.3, 0, 0.055, 0), C.neonGold, UIEffects, 5)

	local inventoryBtn = makeButton(frame, "[ INVENTORY ]", UDim2.new(0.3, 0, btnStartY + 0.065, 0), UDim2.new(0.3, 0, 0.045, 0), C.neonMagenta, UIEffects, 5)

	local backBtn = makeButton(frame, "[ BACK ]", UDim2.new(0.7, 0, btnStartY + 0.065, 0), UDim2.new(0.3, 0, 0.045, 0), C.neonCyan, UIEffects, 5)

	-- Bulk results overlay (shows all 5 results at once)
	local bulkOverlay = Instance.new("Frame")
	bulkOverlay.Name = "BulkResultOverlay"
	bulkOverlay.Size = UDim2.new(1, 0, 1, 0)
	bulkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bulkOverlay.BackgroundTransparency = 0.2
	bulkOverlay.BorderSizePixel = 0
	bulkOverlay.Visible = false
	bulkOverlay.ZIndex = 10
	bulkOverlay.Parent = frame

	-- Bulk results card
	local bulkCard = Instance.new("Frame")
	bulkCard.Size = UDim2.new(0.5, 0, 0.75, 0)
	bulkCard.Position = UDim2.new(0.25, 0, 0.08, 0)
	bulkCard.BackgroundColor3 = Color3.fromRGB(12, 10, 28)
	bulkCard.BackgroundTransparency = 0
	bulkCard.BorderSizePixel = 0
	bulkCard.ZIndex = 11
	bulkCard.Parent = bulkOverlay

	local bulkCardCorner = Instance.new("UICorner")
	bulkCardCorner.CornerRadius = UDim.new(0, 14)
	bulkCardCorner.Parent = bulkCard

	local bulkCardStroke = Instance.new("UIStroke")
	bulkCardStroke.Color = C.neonGold
	bulkCardStroke.Thickness = 2
	bulkCardStroke.Parent = bulkCard

	-- Title
	local bulkTitle = Instance.new("TextLabel")
	bulkTitle.Size = UDim2.new(0.8, 0, 0.07, 0)
	bulkTitle.Position = UDim2.new(0.1, 0, 0.02, 0)
	bulkTitle.BackgroundTransparency = 1
	bulkTitle.Text = "5x SPIN RESULTS"
	bulkTitle.TextColor3 = C.neonGold
	bulkTitle.TextScaled = true
	bulkTitle.Font = Enum.Font.GothamBlack
	bulkTitle.ZIndex = 12
	bulkTitle.Parent = bulkCard

	-- Results list container
	local bulkList = Instance.new("Frame")
	bulkList.Name = "BulkList"
	bulkList.Size = UDim2.new(0.9, 0, 0.72, 0)
	bulkList.Position = UDim2.new(0.05, 0, 0.1, 0)
	bulkList.BackgroundTransparency = 1
	bulkList.ZIndex = 12
	bulkList.Parent = bulkCard

	-- Close button on bulk overlay
	local bulkCloseBtn = Instance.new("TextButton")
	bulkCloseBtn.Size = UDim2.new(0.3, 0, 0.07, 0)
	bulkCloseBtn.Position = UDim2.new(0.35, 0, 0.85, 0)
	bulkCloseBtn.BackgroundColor3 = Color3.fromRGB(0, 35, 45)
	bulkCloseBtn.BackgroundTransparency = 0
	bulkCloseBtn.Text = "[ CONTINUE ]"
	bulkCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	bulkCloseBtn.TextScaled = true
	bulkCloseBtn.Font = Enum.Font.GothamBold
	bulkCloseBtn.ZIndex = 12
	bulkCloseBtn.Parent = bulkCard

	local bulkCloseBtnCorner = Instance.new("UICorner")
	bulkCloseBtnCorner.CornerRadius = UDim.new(0, 8)
	bulkCloseBtnCorner.Parent = bulkCloseBtn

	local bulkCloseBtnStroke = Instance.new("UIStroke")
	bulkCloseBtnStroke.Color = C.neonCyan
	bulkCloseBtnStroke.Thickness = 2
	bulkCloseBtnStroke.Transparency = 0.2
	bulkCloseBtnStroke.Parent = bulkCloseBtn

	UIEffects.addNeonButton(bulkCloseBtn, C.neonCyan)

	bulkCloseBtn.MouseButton1Click:Connect(function()
		bulkOverlay.Visible = false
	end)

	local ARCHETYPE_ICONS_BULK = {
		hot_headed_hero = "🔥", cool_strategist = "🧠", lone_wolf = "🐺",
		gentle_protector = "🛡️", chaotic_wildcard = "⚡", silent_powerhouse = "💪",
		loyal_companion = "❤️", wise_mentor = "📖", rebel_with_a_cause = "⚔️",
		cheerful_optimist = "☀️", anime_transformation = "✨",
	}

	local function showBulkResults(results)
		-- Clear old entries
		for _, child in bulkList:GetChildren() do
			child:Destroy()
		end

		for i, result in results do
			local rarityColor = Color3.fromRGB(result.rarityColor[1] or result.rarityColor.R or 255, result.rarityColor[2] or result.rarityColor.G or 255, result.rarityColor[3] or result.rarityColor.B or 255)

			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0.18, 0)
			row.Position = UDim2.new(0, 0, (i - 1) * 0.2, 0)
			row.BackgroundColor3 = Color3.fromRGB(15, 12, 32)
			row.BackgroundTransparency = 0
			row.BorderSizePixel = 0
			row.ZIndex = 13
			row.Parent = bulkList

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 8)
			rowCorner.Parent = row

			local rowStroke = Instance.new("UIStroke")
			rowStroke.Color = rarityColor
			rowStroke.Thickness = 1.5
			rowStroke.Transparency = 0.3
			rowStroke.Parent = row

			-- Icon
			local icon = Instance.new("TextLabel")
			icon.Size = UDim2.new(0.1, 0, 0.8, 0)
			icon.Position = UDim2.new(0.02, 0, 0.1, 0)
			icon.BackgroundTransparency = 1
			icon.Text = ARCHETYPE_ICONS_BULK[result.auraId] or "?"
			icon.TextScaled = true
			icon.ZIndex = 14
			icon.Parent = row

			-- Name
			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(0.4, 0, 0.5, 0)
			name.Position = UDim2.new(0.14, 0, 0.05, 0)
			name.BackgroundTransparency = 1
			name.Text = getAuraDisplayName(result.auraId)
			name.TextColor3 = Color3.fromRGB(255, 255, 255)
			name.TextScaled = true
			name.Font = Enum.Font.GothamBold
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.ZIndex = 14
			name.Parent = row

			-- Rarity
			local rarity = Instance.new("TextLabel")
			rarity.Size = UDim2.new(0.3, 0, 0.4, 0)
			rarity.Position = UDim2.new(0.14, 0, 0.55, 0)
			rarity.BackgroundTransparency = 1
			rarity.Text = result.rarityName
			rarity.TextColor3 = rarityColor
			rarity.TextScaled = true
			rarity.Font = Enum.Font.RobotoMono
			rarity.TextXAlignment = Enum.TextXAlignment.Left
			rarity.ZIndex = 14
			rarity.Parent = row

			-- NEW or SHARDS badge on right
			local badge = Instance.new("TextLabel")
			badge.Size = UDim2.new(0.28, 0, 0.5, 0)
			badge.Position = UDim2.new(0.7, 0, 0.25, 0)
			badge.BackgroundTransparency = 1
			badge.TextScaled = true
			badge.Font = Enum.Font.GothamBold
			badge.ZIndex = 14
			badge.Parent = row

			if result.isNew then
				badge.Text = "★ NEW!"
				badge.TextColor3 = C.neonCyan
			else
				badge.Text = "+" .. result.shardsAwarded .. " shards"
				badge.TextColor3 = C.neonGold
			end

			-- Staggered fade in
			row.BackgroundTransparency = 1
			name.TextTransparency = 1
			rarity.TextTransparency = 1
			badge.TextTransparency = 1
			icon.TextTransparency = 1

			task.delay(i * 0.15, function()
				TweenService:Create(row, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
				TweenService:Create(name, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
				TweenService:Create(rarity, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
				TweenService:Create(badge, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
				TweenService:Create(icon, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
			end)
		end

		bulkOverlay.Visible = true

		-- Update free spins display
		freeSpinsLabel.Text = "FREE SPINS: " .. freeSpins
		-- bulk5Btn always visible
	end

	-- ============================================================
	-- Spin logic
	-- ============================================================
	local function showResult(result: { auraId: string, rarityName: string, rarityColor: { R: number, G: number, B: number }, isNew: boolean, shardsAwarded: number })
		local rarityColor = Color3.fromRGB(result.rarityColor.R, result.rarityColor.G, result.rarityColor.B)

		resultOverlay.Visible = true

		-- Flash in rarity color
		flashFrame.BackgroundColor3 = rarityColor
		flashFrame.BackgroundTransparency = 0.5
		TweenService:Create(flashFrame, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
			BackgroundTransparency = 1,
		}):Play()

		-- Update card border color to match rarity
		resultCardStroke.Color = rarityColor
		resultDivider.BackgroundColor3 = rarityColor

		-- Set icon
		resultIcon.Text = ARCHETYPE_ICONS[result.auraId] or "✨"

		-- Set aura name
		resultName.Text = getAuraDisplayName(result.auraId)

		-- Set rarity
		resultRarity.Text = "// " .. string.upper(result.rarityName) .. " //"
		resultRarity.TextColor3 = rarityColor

		-- Set badge
		if result.isNew then
			resultBadge.Text = "★  NEW AURA UNLOCKED  ★"
			resultBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
			resultBadge.BackgroundColor3 = Color3.fromRGB(0, 40, 50)
			badgeStroke.Color = C.neonCyan
		else
			resultBadge.Text = "+" .. result.shardsAwarded .. " SHARDS"
			resultBadge.TextColor3 = C.neonGold
			resultBadge.BackgroundColor3 = Color3.fromRGB(35, 25, 5)
			badgeStroke.Color = C.neonGold
		end

		-- Set description
		local archetype = Archetypes.getById(result.auraId)
		if archetype then
			resultDesc.Text = "Like: " .. table.concat(archetype.examples, ", ")
		elseif result.auraId == "anime_transformation" then
			resultDesc.Text = "The ultimate transformation — ultra rare!"
		else
			resultDesc.Text = ""
		end

		-- Animate card entrance (scale in from small)
		resultCard.Size = UDim2.new(0.1, 0, 0.1, 0)
		resultCard.Position = UDim2.new(0.45, 0, 0.4, 0)
		TweenService:Create(resultCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.4, 0, 0.45, 0),
			Position = UDim2.new(0.3, 0, 0.2, 0),
		}):Play()

		-- Show spin again if free spins remain
		if freeSpins > 0 then
			resultSpinAgainBtn.Visible = true
		else
			resultSpinAgainBtn.Visible = false
		end
	end

	local function doSpin()
		if isSpinning then
			return
		end

		-- Hide result overlay and spin again button during spin
		resultOverlay.Visible = false
		resultSpinAgainBtn.Visible = false
		isSpinning = true

		-- Request spin from server
		local requestSpin = Remotes.get("RequestSpin")
		local result = requestSpin:InvokeServer()

		if not result then
			isSpinning = false
			return
		end

		-- Decrement free spins
		if freeSpins > 0 then
			freeSpins -= 1
			freeSpinsLabel.Text = "FREE SPINS: " .. freeSpins
			-- bulk5Btn always visible
		end

		-- Build spin list with target
		local targetY = buildSpinList(result.auraId)

		-- Reset scroll position
		scrollFrame.Position = UDim2.new(0, 0, 0, 0)

		-- Animate scroll
		local tween = TweenService:Create(scrollFrame, TweenInfo.new(SPIN_DURATION, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, -targetY),
		})
		tween:Play()
		tween.Completed:Wait()

		-- Small pause before reveal
		task.wait(0.3)

		isSpinning = false
		showResult(result)
	end

	-- ============================================================
	-- Button connections
	-- ============================================================
	-- SPIN x1: if free spins available, spin. Otherwise prompt purchase.
	mainSpinBtn.MouseButton1Click:Connect(function()
		if isSpinning then return end
		if freeSpins > 0 then
			doSpin()
		else
			MarketplaceService:PromptProductPurchase(player, spinData.buy1SpinProductId)
		end
	end)

	-- SPIN x5: if 5+ free spins, bulk spin. Otherwise prompt 5-spin purchase.
	bulk5Btn.MouseButton1Click:Connect(function()
		if isSpinning then return end
		if freeSpins >= 5 then
			isSpinning = true
			local bulkSpinRemote = Remotes.get("RequestBulkSpin") :: RemoteFunction
			local results = bulkSpinRemote:InvokeServer()
			isSpinning = false

			if results and #results > 0 then
				freeSpins = freeSpins - #results
				freeSpinsLabel.Text = "FREE SPINS: " .. freeSpins
				-- bulk5Btn always visible
				showBulkResults(results)
			end
		else
			MarketplaceService:PromptProductPurchase(player, spinData.buy5SpinsProductId)
		end
	end)

	-- Result overlay spin again — same logic as main spin
	resultSpinAgainBtn.MouseButton1Click:Connect(function()
		if not isSpinning and freeSpins > 0 then
			doSpin()
		end
	end)

	inventoryBtn.MouseButton1Click:Connect(function()
		if not isSpinning then
			onInventory()
		end
	end)

	backBtn.MouseButton1Click:Connect(function()
		if not isSpinning then
			onBack()
		end
	end)

	-- ============================================================
	-- SpinPurchaseComplete listener
	-- ============================================================
	local spinPurchaseEvent = Remotes.get("SpinPurchaseComplete")
	spinPurchaseEvent.OnClientEvent:Connect(function(spinCount: number)
		freeSpins = freeSpins + spinCount
		freeSpinsLabel.Text = "FREE SPINS: " .. freeSpins
		-- bulk5Btn always visible
		if freeSpins > 0 then
			resultSpinAgainBtn.Visible = true
		end
	end)

	-- No auto-spin — player must click SPIN button

	return frame
end

return SpinWheelUI
