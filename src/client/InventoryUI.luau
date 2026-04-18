local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
local AuraRarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraRarities"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local InventoryUI = {}

-- ============================================================
-- Internal build helper
-- ============================================================

local function build(
	screenGui: ScreenGui,
	inventoryData: { unlockedAuras: { string }, selectedAura: string, shards: number },
	onBack: () -> ()
)
	local C = UIEffects.COLORS

	-- Remove any existing frame
	local existing = screenGui:FindFirstChild("InventoryFrame")
	if existing then
		existing:Destroy()
	end

	-- Build owned lookup
	local ownedSet: { [string]: boolean } = {}
	for _, id in inventoryData.unlockedAuras do
		ownedSet[id] = true
	end

	-- --------------------------------------------------------
	-- Root frame
	-- --------------------------------------------------------
	local frame = Instance.new("Frame")
	frame.Name = "InventoryFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = C.bg
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	UIEffects.addGradient(frame, Color3.fromRGB(8, 4, 20), Color3.fromRGB(4, 10, 25), 160)
	UIEffects.addDigitalParticles(frame, 12)

	-- --------------------------------------------------------
	-- Header row: title + shard balance
	-- --------------------------------------------------------
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.35, 0, 0.055, 0)
	title.Position = UDim2.new(0.2, 0, 0.06, 0)
	title.BackgroundTransparency = 1
	title.Text = "AURA INVENTORY"
	title.TextColor3 = C.neonMagenta
	title.TextScaled = true
	title.Font = Enum.Font.RobotoMono
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 3
	title.Parent = frame

	UIEffects.addGlow(title, C.neonMagenta, 1)

	local shardLabel = Instance.new("TextLabel")
	shardLabel.Size = UDim2.new(0.2, 0, 0.045, 0)
	shardLabel.Position = UDim2.new(0.55, 0, 0.065, 0)
	shardLabel.BackgroundTransparency = 1
	shardLabel.Text = "SHARDS: " .. tostring(inventoryData.shards)
	shardLabel.TextColor3 = C.neonGold
	shardLabel.TextScaled = true
	shardLabel.Font = Enum.Font.RobotoMono
	shardLabel.TextXAlignment = Enum.TextXAlignment.Right
	shardLabel.ZIndex = 3
	shardLabel.Parent = frame

	UIEffects.addGlow(shardLabel, C.neonGold, 1)

	-- Divider below header
	UIEffects.addDivider(frame, 0.125, C.neonMagenta)

	-- --------------------------------------------------------
	-- Grid: 2 columns, all 11 aura IDs from AuraRarities
	-- --------------------------------------------------------
	local allAuraIds = AuraRarities.getAllAuraIds()

	-- Grid layout constants
	local CARD_W = 0.42
	local CARD_H = 0.126
	local COL1_X = 0.05
	local COL2_X = 0.53
	local GRID_TOP = 0.15
	local ROW_GAP = 0.135

	for i, auraId in allAuraIds do
		local row = math.ceil(i / 2)
		local col = ((i - 1) % 2) + 1

		local cardX = if col == 1 then COL1_X else COL2_X
		local cardY = GRID_TOP + (row - 1) * ROW_GAP

		local rarity = AuraRarities.getRarityForAura(auraId)
		local rarityColor = if rarity then rarity.color else Color3.fromRGB(100, 100, 150)
		local rarityName = if rarity then rarity.name else "?"
		local craftCost = if rarity then rarity.craftCost else 999

		local isOwned = ownedSet[auraId] == true
		local isEquipped = auraId == inventoryData.selectedAura

		-- Display name
		local displayName: string
		if auraId == "anime_transformation" then
			displayName = "??? ANIME TRANSFORMATION ???"
		else
			local archetype = Archetypes.getById(auraId)
			displayName = if archetype then archetype.name else auraId
		end

		-- ---- Card frame ----
		local card = Instance.new("Frame")
		card.Name = "AuraCard_" .. auraId
		card.Size = UDim2.new(CARD_W, 0, CARD_H, 0)
		card.Position = UDim2.new(cardX, 0, cardY, 0)
		card.BorderSizePixel = 0
		card.ZIndex = 3
		card.Parent = frame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		-- Dark glass base
		UIEffects.applyDarkGlass(card)

		-- Border
		if isOwned then
			if isEquipped then
				UIEffects.addNeonPulse(card, rarityColor, 2)
			else
				local stroke = Instance.new("UIStroke")
				stroke.Color = rarityColor
				stroke.Thickness = 1.5
				stroke.Transparency = 0.35
				stroke.Parent = card
			end
		else
			-- Dim border for unowned
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(28, 24, 45)
			stroke.Thickness = 1
			stroke.Transparency = 0.55
			stroke.Parent = card
		end

		-- Left accent stripe
		local accent = Instance.new("Frame")
		accent.Size = UDim2.new(0, 4, 0.65, 0)
		accent.Position = UDim2.new(0, 0, 0.175, 0)
		accent.BackgroundColor3 = if isOwned then rarityColor else Color3.fromRGB(35, 30, 55)
		accent.BackgroundTransparency = if isOwned then 0 else 0.7
		accent.BorderSizePixel = 0
		accent.ZIndex = 4
		accent.Parent = card

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(1, 0)
		accentCorner.Parent = accent

		-- Aura name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.55, 0, 0.35, 0)
		nameLabel.Position = UDim2.new(0.08, 0, 0.08, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = if isOwned then displayName else "???"
		nameLabel.TextColor3 = if isOwned then rarityColor else C.textMuted
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 5
		nameLabel.Parent = card

		-- Rarity badge
		local rarityBadge = Instance.new("TextLabel")
		rarityBadge.Size = UDim2.new(0.28, 0, 0.28, 0)
		rarityBadge.Position = UDim2.new(0.08, 0, 0.52, 0)
		rarityBadge.BackgroundColor3 = if isOwned then rarityColor else Color3.fromRGB(28, 24, 45)
		rarityBadge.BackgroundTransparency = if isOwned then 0.75 else 0.5
		rarityBadge.Text = rarityName
		rarityBadge.TextColor3 = if isOwned then rarityColor else C.textMuted
		rarityBadge.TextScaled = true
		rarityBadge.Font = Enum.Font.RobotoMono
		rarityBadge.ZIndex = 5
		rarityBadge.Parent = card

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 4)
		badgeCorner.Parent = rarityBadge

		if isOwned then
			local badgeStroke = Instance.new("UIStroke")
			badgeStroke.Color = rarityColor
			badgeStroke.Thickness = 1
			badgeStroke.Transparency = 0.5
			badgeStroke.Parent = rarityBadge
		end

		-- Right-side action area
		if isOwned then
			if isEquipped then
				-- "EQUIPPED" label
				local equippedLabel = Instance.new("TextLabel")
				equippedLabel.Size = UDim2.new(0.28, 0, 0.38, 0)
				equippedLabel.Position = UDim2.new(0.69, 0, 0.31, 0)
				equippedLabel.BackgroundColor3 = rarityColor
				equippedLabel.BackgroundTransparency = 0.1
				equippedLabel.Text = "EQUIPPED"
				equippedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				equippedLabel.TextScaled = true
				equippedLabel.Font = Enum.Font.GothamBold
				equippedLabel.ZIndex = 6
				equippedLabel.Parent = card

				local eqCorner = Instance.new("UICorner")
				eqCorner.CornerRadius = UDim.new(0, 5)
				eqCorner.Parent = equippedLabel

				local eqStroke = Instance.new("UIStroke")
				eqStroke.Color = rarityColor
				eqStroke.Thickness = 1.5
				eqStroke.Transparency = 0.1
				eqStroke.Parent = equippedLabel
			else
				-- "EQUIP" button
				local equipBtn = Instance.new("TextButton")
				equipBtn.Name = "EquipButton"
				equipBtn.Size = UDim2.new(0.25, 0, 0.38, 0)
				equipBtn.Position = UDim2.new(0.71, 0, 0.31, 0)
				equipBtn.BackgroundColor3 = Color3.fromRGB(0, 18, 30)
				equipBtn.BackgroundTransparency = 0.2
				equipBtn.Text = "EQUIP"
				equipBtn.TextColor3 = rarityColor
				equipBtn.TextScaled = true
				equipBtn.Font = Enum.Font.GothamBold
				equipBtn.AutoButtonColor = false
				equipBtn.ZIndex = 6
				equipBtn.Parent = card

				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 5)
				btnCorner.Parent = equipBtn

				UIEffects.addNeonButton(equipBtn, rarityColor)

				equipBtn.MouseButton1Click:Connect(function()
					local selectRemote = Remotes.get("SelectAura") :: RemoteFunction
					local success = selectRemote:InvokeServer(auraId)
					if success then
						local newData = {
							unlockedAuras = inventoryData.unlockedAuras,
							selectedAura = auraId,
							shards = inventoryData.shards,
						}
						build(screenGui, newData, onBack)
						local newFrame = screenGui:FindFirstChild("InventoryFrame")
						if newFrame then
							newFrame.Visible = true
						end
					end
				end)
			end
		else
			-- Unowned: show craft cost or button
			local canAfford = inventoryData.shards >= craftCost

			if canAfford then
				-- "CRAFT (X shards)" button
				local craftBtn = Instance.new("TextButton")
				craftBtn.Name = "CraftButton"
				craftBtn.Size = UDim2.new(0.33, 0, 0.38, 0)
				craftBtn.Position = UDim2.new(0.63, 0, 0.31, 0)
				craftBtn.BackgroundColor3 = Color3.fromRGB(15, 5, 28)
				craftBtn.BackgroundTransparency = 0.2
				craftBtn.Text = "CRAFT (" .. tostring(craftCost) .. ")"
				craftBtn.TextColor3 = C.neonPurple
				craftBtn.TextScaled = true
				craftBtn.Font = Enum.Font.GothamBold
				craftBtn.AutoButtonColor = false
				craftBtn.ZIndex = 6
				craftBtn.Parent = card

				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 5)
				btnCorner.Parent = craftBtn

				UIEffects.addNeonButton(craftBtn, C.neonPurple)

				craftBtn.MouseButton1Click:Connect(function()
					local craftRemote = Remotes.get("CraftAura") :: RemoteFunction
					local result = craftRemote:InvokeServer(auraId)
					if result and result.success then
						-- Add aura to unlocked list locally
						local newUnlocked = table.clone(inventoryData.unlockedAuras)
						table.insert(newUnlocked, auraId)
						local newData = {
							unlockedAuras = newUnlocked,
							selectedAura = inventoryData.selectedAura,
							shards = inventoryData.shards - craftCost,
						}
						build(screenGui, newData, onBack)
						local newFrame = screenGui:FindFirstChild("InventoryFrame")
						if newFrame then
							newFrame.Visible = true
						end
					end
				end)
			else
				-- Not enough shards — show dimmed cost
				local costLabel = Instance.new("TextLabel")
				costLabel.Size = UDim2.new(0.33, 0, 0.38, 0)
				costLabel.Position = UDim2.new(0.63, 0, 0.31, 0)
				costLabel.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
				costLabel.BackgroundTransparency = 0.45
				costLabel.Text = "CRAFT (" .. tostring(craftCost) .. ")"
				costLabel.TextColor3 = C.textMuted
				costLabel.TextScaled = true
				costLabel.Font = Enum.Font.GothamBold
				costLabel.ZIndex = 6
				costLabel.Parent = card

				local costCorner = Instance.new("UICorner")
				costCorner.CornerRadius = UDim.new(0, 5)
				costCorner.Parent = costLabel

				local costStroke = Instance.new("UIStroke")
				costStroke.Color = C.textMuted
				costStroke.Thickness = 1
				costStroke.Transparency = 0.7
				costStroke.Parent = costLabel
			end
		end

		-- ---- Staggered fade-in ----
		card.BackgroundTransparency = 1
		nameLabel.TextTransparency = 1
		rarityBadge.TextTransparency = 1

		task.delay(i * 0.04, function()
			if not card or not card.Parent then return end
			-- Fade card background in
			TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.15,
			}):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
			TweenService:Create(rarityBadge, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
		end)
	end

	-- --------------------------------------------------------
	-- Back button
	-- --------------------------------------------------------
	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0.16, 0, 0.06, 0)
	backButton.Position = UDim2.new(0.42, 0, 0.93, 0)
	backButton.BorderSizePixel = 0
	backButton.Text = "[ BACK ]"
	backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	backButton.BackgroundColor3 = Color3.fromRGB(0, 35, 45)
	backButton.BackgroundTransparency = 0
	backButton.TextScaled = true
	backButton.Font = Enum.Font.GothamBold
	backButton.AutoButtonColor = false
	backButton.ZIndex = 10
	backButton.Parent = frame

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 8)
	backCorner.Parent = backButton

	local backStroke = Instance.new("UIStroke")
	backStroke.Color = C.neonCyan
	backStroke.Thickness = 2
	backStroke.Transparency = 0.2
	backStroke.Parent = backButton

	UIEffects.addNeonButton(backButton, C.neonCyan)

	backButton.MouseButton1Click:Connect(function()
		onBack()
	end)
end

-- ============================================================
-- Public API
-- ============================================================

function InventoryUI.build(
	screenGui: ScreenGui,
	inventoryData: { unlockedAuras: { string }, selectedAura: string, shards: number },
	onBack: () -> ()
)
	build(screenGui, inventoryData, onBack)
end

return InventoryUI
