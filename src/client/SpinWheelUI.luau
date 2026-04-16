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
	btn.TextColor3 = neonColor
	btn.TextScaled = true
	btn.Font = Enum.Font.RobotoMono
	btn.ZIndex = zIndex or 5
	btn.Parent = parent
	UIEffects.applyDarkGlass(btn)
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
	UIEffects.addScanLine(frame)

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

	local slotContainer = Instance.new("Frame")
	slotContainer.Name = "SlotContainer"
	slotContainer.Size = UDim2.new(0.55, 0, 0, windowHeight + 20)
	slotContainer.Position = UDim2.new(0.5, 0, 0.18, 0)
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
	resultOverlay.BackgroundTransparency = 1
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

	-- Result aura name
	local resultName = Instance.new("TextLabel")
	resultName.Size = UDim2.new(0.7, 0, 0.1, 0)
	resultName.Position = UDim2.new(0.15, 0, 0.32, 0)
	resultName.BackgroundTransparency = 1
	resultName.Text = ""
	resultName.TextColor3 = C.neonGold
	resultName.TextScaled = true
	resultName.Font = Enum.Font.GothamBlack
	resultName.ZIndex = 12
	resultName.Parent = resultOverlay

	-- NEW! or +X SHARDS badge
	local resultBadge = Instance.new("TextLabel")
	resultBadge.Size = UDim2.new(0.3, 0, 0.055, 0)
	resultBadge.Position = UDim2.new(0.35, 0, 0.43, 0)
	resultBadge.BackgroundTransparency = 1
	resultBadge.Text = ""
	resultBadge.TextScaled = true
	resultBadge.Font = Enum.Font.GothamBold
	resultBadge.ZIndex = 12
	resultBadge.Parent = resultOverlay

	-- Rarity name below
	local resultRarity = Instance.new("TextLabel")
	resultRarity.Size = UDim2.new(0.3, 0, 0.04, 0)
	resultRarity.Position = UDim2.new(0.35, 0, 0.49, 0)
	resultRarity.BackgroundTransparency = 1
	resultRarity.Text = ""
	resultRarity.TextColor3 = C.textSecondary
	resultRarity.TextScaled = true
	resultRarity.Font = Enum.Font.RobotoMono
	resultRarity.ZIndex = 12
	resultRarity.Parent = resultOverlay

	-- ============================================================
	-- Buttons
	-- ============================================================
	local buttonAreaY = 0.18 + (windowHeight + 20) / 1080 + 0.42 -- approximate; use scale positioning
	-- We'll place buttons below the slot container using a calculated offset
	local btnStartY = 0.60

	local spinAgainBtn = makeButton(frame, "[ SPIN AGAIN ]", UDim2.new(0.5, 0, btnStartY, 0), UDim2.new(0.32, 0, 0.05, 0), C.neonCyan, UIEffects, 5)
	spinAgainBtn.Visible = false

	local buy1Btn = makeButton(frame, "[ BUY 1 SPIN \226\128\148 10 R$ ]", UDim2.new(0.3, 0, btnStartY + 0.065, 0), UDim2.new(0.32, 0, 0.05, 0), C.neonGold, UIEffects, 5)

	local buy5Btn = makeButton(frame, "[ BUY 5 SPINS \226\128\148 40 R$ ]", UDim2.new(0.7, 0, btnStartY + 0.065, 0), UDim2.new(0.32, 0, 0.05, 0), C.neonGold, UIEffects, 5)

	local inventoryBtn = makeButton(frame, "[ INVENTORY ]", UDim2.new(0.3, 0, btnStartY + 0.13, 0), UDim2.new(0.32, 0, 0.05, 0), C.neonMagenta, UIEffects, 5)

	local backBtn = makeButton(frame, "[ BACK ]", UDim2.new(0.7, 0, btnStartY + 0.13, 0), UDim2.new(0.32, 0, 0.05, 0), C.neonCyan, UIEffects, 5)

	-- ============================================================
	-- Spin logic
	-- ============================================================
	local function showResult(result: { auraId: string, rarityName: string, rarityColor: { R: number, G: number, B: number }, isNew: boolean, shardsAwarded: number })
		local rarityColor = Color3.fromRGB(result.rarityColor.R, result.rarityColor.G, result.rarityColor.B)

		resultOverlay.Visible = true

		-- Flash in rarity color
		flashFrame.BackgroundColor3 = rarityColor
		flashFrame.BackgroundTransparency = 0.7
		TweenService:Create(flashFrame, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
			BackgroundTransparency = 1,
		}):Play()

		-- Set result text
		resultName.Text = getAuraDisplayName(result.auraId)
		resultName.TextColor3 = rarityColor

		if result.isNew then
			resultBadge.Text = "NEW!"
			resultBadge.TextColor3 = C.neonCyan
		else
			resultBadge.Text = "+" .. result.shardsAwarded .. " SHARDS"
			resultBadge.TextColor3 = C.neonGold
		end

		resultRarity.Text = result.rarityName

		-- Show spin again if free spins remain
		if freeSpins > 0 then
			spinAgainBtn.Visible = true
		else
			spinAgainBtn.Visible = false
		end
	end

	local function doSpin()
		if isSpinning then
			return
		end

		-- Hide result overlay and spin again button during spin
		resultOverlay.Visible = false
		spinAgainBtn.Visible = false
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
	spinAgainBtn.MouseButton1Click:Connect(function()
		if not isSpinning and freeSpins > 0 then
			doSpin()
		end
	end)

	buy1Btn.MouseButton1Click:Connect(function()
		if not isSpinning then
			MarketplaceService:PromptProductPurchase(player, spinData.buy1SpinProductId)
		end
	end)

	buy5Btn.MouseButton1Click:Connect(function()
		if not isSpinning then
			MarketplaceService:PromptProductPurchase(player, spinData.buy5SpinsProductId)
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
		freeSpins = spinCount
		freeSpinsLabel.Text = "FREE SPINS: " .. freeSpins
		if freeSpins > 0 then
			spinAgainBtn.Visible = true
		end
	end)

	-- ============================================================
	-- Initial state: if free spins available, auto-spin or show spin button
	-- ============================================================
	if freeSpins > 0 then
		-- Start first spin automatically
		task.spawn(function()
			-- Wait a moment for UI to be shown by UIController
			task.wait(0.5)
			if frame.Visible and freeSpins > 0 then
				doSpin()
			else
				spinAgainBtn.Visible = true
			end
		end)
	end

	return frame
end

return SpinWheelUI
