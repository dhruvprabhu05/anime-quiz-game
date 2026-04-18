local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SettingsUI = {}

-- Helper: get or create a shared flag in ReplicatedStorage
local function getFlag(name: string, defaultValue: any): Instance
	local flag = ReplicatedStorage:FindFirstChild(name)
	if not flag then
		if type(defaultValue) == "boolean" then
			flag = Instance.new("BoolValue")
		else
			flag = Instance.new("NumberValue")
		end
		flag.Name = name
		flag.Value = defaultValue
		flag.Parent = ReplicatedStorage
	end
	return flag
end

function SettingsUI.build(screenGui: ScreenGui, onClose: () -> ())
	local UIEffects = require(script.Parent:WaitForChild("UIEffects"))
	local C = UIEffects.COLORS

	local existing = screenGui:FindFirstChild("SettingsFrame")
	if existing then
		existing:Destroy()
	end

	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "SettingsFrame"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 30
	overlay.Parent = screenGui

	-- Scrollable settings panel (centered)
	local panel = Instance.new("ScrollingFrame")
	panel.Name = "SettingsPanel"
	panel.Size = UDim2.new(0.42, 0, 0.75, 0)
	panel.Position = UDim2.new(0.29, 0, 0.1, 0)
	panel.BackgroundColor3 = Color3.fromRGB(12, 10, 28)
	panel.BackgroundTransparency = 0
	panel.BorderSizePixel = 0
	panel.ScrollBarThickness = 4
	panel.ScrollBarImageColor3 = C.neonPurple
	panel.CanvasSize = UDim2.new(0, 0, 0, 680)
	panel.ZIndex = 31
	panel.Parent = overlay

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = C.neonPurple
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	-- ============================================================
	-- Helpers (use pixel offsets inside ScrollingFrame)
	-- ============================================================
	local function makeHeader(text: string, yOffset: number)
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(0.8, 0, 0, 28)
		header.Position = UDim2.new(0.1, 0, 0, yOffset)
		header.BackgroundTransparency = 1
		header.Text = "// " .. text
		header.TextColor3 = C.neonCyan
		header.TextScaled = true
		header.Font = Enum.Font.RobotoMono
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.ZIndex = 32
		header.Parent = panel

		local divider = Instance.new("Frame")
		divider.Size = UDim2.new(0.8, 0, 0, 1)
		divider.Position = UDim2.new(0.1, 0, 0, yOffset + 30)
		divider.BackgroundColor3 = C.neonCyan
		divider.BackgroundTransparency = 0.6
		divider.BorderSizePixel = 0
		divider.ZIndex = 32
		divider.Parent = panel
	end

	local function makeSlider(labelText: string, yOffset: number, currentVal: number, onChange: (number) -> ())
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.4, 0, 0, 24)
		label.Position = UDim2.new(0.1, 0, 0, yOffset)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = C.textPrimary
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 32
		label.Parent = panel

		local pct = Instance.new("TextLabel")
		pct.Size = UDim2.new(0, 40, 0, 22)
		pct.Position = UDim2.new(0.78, 0, 0, yOffset)
		pct.BackgroundTransparency = 1
		pct.Text = tostring(math.floor(currentVal * 100)) .. "%"
		pct.TextColor3 = C.textSecondary
		pct.TextScaled = true
		pct.Font = Enum.Font.RobotoMono
		pct.ZIndex = 32
		pct.Parent = panel

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(0.6, 0, 0, 8)
		bg.Position = UDim2.new(0.1, 0, 0, yOffset + 28)
		bg.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
		bg.BorderSizePixel = 0
		bg.ZIndex = 32
		bg.Parent = panel

		local bgCorner = Instance.new("UICorner")
		bgCorner.CornerRadius = UDim.new(1, 0)
		bgCorner.Parent = bg

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(currentVal, 0, 1, 0)
		fill.BackgroundColor3 = C.neonCyan
		fill.BorderSizePixel = 0
		fill.ZIndex = 33
		fill.Parent = bg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 16, 0, 16)
		knob.Position = UDim2.new(currentVal, -8, 0.5, -8)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.ZIndex = 34
		knob.Parent = bg

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		local dragging = false

		local function update(input: InputObject)
			local absPos = bg.AbsolutePosition.X
			local absSize = bg.AbsoluteSize.X
			local rel = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			knob.Position = UDim2.new(rel, -8, 0.5, -8)
			pct.Text = tostring(math.floor(rel * 100)) .. "%"
			onChange(rel)
		end

		bg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(input)
			end
		end)

		knob.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				update(input)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	local function makeToggle(labelText: string, yOffset: number, defaultOn: boolean, onChange: (boolean) -> ())
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.5, 0, 0, 24)
		label.Position = UDim2.new(0.1, 0, 0, yOffset)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = C.textPrimary
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 32
		label.Parent = panel

		local isOn = defaultOn

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 50, 0, 26)
		btn.Position = UDim2.new(0.78, 0, 0, yOffset - 1)
		btn.BackgroundColor3 = if isOn then Color3.fromRGB(0, 45, 55) else Color3.fromRGB(25, 20, 40)
		btn.BackgroundTransparency = 0
		btn.Text = if isOn then "ON" else "OFF"
		btn.TextColor3 = if isOn then C.neonCyan else C.textMuted
		btn.TextScaled = true
		btn.Font = Enum.Font.GothamBold
		btn.ZIndex = 33
		btn.Parent = panel

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = if isOn then C.neonCyan else C.textMuted
		stroke.Thickness = 1.5
		stroke.Parent = btn

		btn.MouseButton1Click:Connect(function()
			isOn = not isOn
			btn.Text = if isOn then "ON" else "OFF"
			btn.TextColor3 = if isOn then C.neonCyan else C.textMuted
			btn.BackgroundColor3 = if isOn then Color3.fromRGB(0, 45, 55) else Color3.fromRGB(25, 20, 40)
			stroke.Color = if isOn then C.neonCyan else C.textMuted
			if onChange then
				pcall(onChange, isOn)
			end
		end)
	end

	-- ============================================================
	-- TITLE + CLOSE
	-- ============================================================
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.6, 0, 0, 36)
	title.Position = UDim2.new(0.2, 0, 0, 12)
	title.BackgroundTransparency = 1
	title.Text = "SETTINGS"
	title.TextColor3 = C.neonPurple
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.ZIndex = 32
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -42, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 40)
	closeBtn.BackgroundTransparency = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = C.neonMagenta
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.ZIndex = 33
	closeBtn.Parent = panel

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 6)
	closeBtnCorner.Parent = closeBtn

	local closeBtnStroke = Instance.new("UIStroke")
	closeBtnStroke.Color = C.neonMagenta
	closeBtnStroke.Thickness = 1.5
	closeBtnStroke.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		onClose()
	end)

	-- Close on overlay click
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local absPos = panel.AbsolutePosition
			local absSize = panel.AbsoluteSize
			local pos = input.Position
			if pos.X < absPos.X or pos.X > absPos.X + absSize.X or pos.Y < absPos.Y or pos.Y > absPos.Y + absSize.Y then
				onClose()
			end
		end
	end)

	-- ============================================================
	-- AUDIO (starts at y=55)
	-- ============================================================
	makeHeader("AUDIO", 55)

	-- Music Volume
	local musicVolumeFlag = getFlag("MusicVolume", 0.3)
	makeSlider("Music Volume", 95, musicVolumeFlag.Value, function(val)
		musicVolumeFlag.Value = val
	end)

	-- SFX Volume
	local sfxVolumeFlag = getFlag("SFXVolume", 0.8)
	makeSlider("SFX Volume", 145, sfxVolumeFlag.Value, function(val)
		sfxVolumeFlag.Value = val
	end)

	-- ============================================================
	-- GRAPHICS (starts at y=200)
	-- ============================================================
	makeHeader("GRAPHICS", 200)

	-- Shadows
	local shadowsFlag = getFlag("ShadowsEnabled", true)
	makeToggle("Shadows", 240, shadowsFlag.Value, function(on)
		shadowsFlag.Value = on
		Lighting.GlobalShadows = on
	end)

	-- Particles (world auras)
	local particlesFlag = getFlag("ParticlesEnabled", true)
	makeToggle("Particles (Auras)", 275, particlesFlag.Value, function(on)
		particlesFlag.Value = on
		for _, desc in workspace:GetDescendants() do
			if desc:IsA("ParticleEmitter") then
				desc.Enabled = on
			end
		end
	end)

	-- Aura Intensity
	local auraIntensityFlag = getFlag("AuraIntensity", 1.0)
	makeSlider("Aura Intensity", 310, auraIntensityFlag.Value, function(val)
		auraIntensityFlag.Value = val
		-- Adjust all existing particle emitter rates
		for _, desc in workspace:GetDescendants() do
			if desc:IsA("ParticleEmitter") and desc:GetAttribute("AuraEffect") then
				-- Store original rate on first adjustment
				if not desc:GetAttribute("OriginalRate") then
					desc:SetAttribute("OriginalRate", desc.Rate)
				end
				local orig = desc:GetAttribute("OriginalRate")
				desc.Rate = math.max(1, math.floor(orig * val))
			end
		end
	end)

	-- Hide Other Players' Auras
	local hideOtherAurasFlag = getFlag("HideOtherAuras", false)
	makeToggle("Hide Others' Auras", 360, not hideOtherAurasFlag.Value, function(on)
		hideOtherAurasFlag.Value = not on
		local Players = game:GetService("Players")
		local localPlayer = Players.LocalPlayer
		for _, player in Players:GetPlayers() do
			if player ~= localPlayer and player.Character then
				for _, desc in player.Character:GetDescendants() do
					if desc:GetAttribute("AuraEffect") then
						if desc:IsA("ParticleEmitter") then
							desc.Enabled = on
						elseif desc:IsA("PointLight") then
							desc.Enabled = on
						end
					end
				end
			end
		end
	end)

	-- Bloom/Glow
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	makeToggle("Bloom / Glow", 395, if bloom then bloom.Enabled else true, function(on)
		local b = Lighting:FindFirstChildOfClass("BloomEffect")
		if b then
			b.Enabled = on
		end
	end)

	-- Atmosphere
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local originalDensity = if atmosphere then atmosphere.Density else 0.3
	makeToggle("Atmosphere", 430, if atmosphere then atmosphere.Density > 0 else false, function(on)
		local a = Lighting:FindFirstChildOfClass("Atmosphere")
		if a then
			a.Density = if on then originalDensity else 0
		end
	end)

	-- ============================================================
	-- DISPLAY (starts at y=485)
	-- ============================================================
	makeHeader("DISPLAY", 485)

	-- UI Particles
	local uiParticlesFlag = getFlag("UIParticlesEnabled", true)
	makeToggle("UI Particles", 525, uiParticlesFlag.Value, function(on)
		uiParticlesFlag.Value = on
		for _, gui in screenGui:GetDescendants() do
			if gui.Name and string.find(gui.Name, "DigiParticle") then
				gui.Visible = on
			end
		end
	end)

	-- FOV Slider
	local fovFlag = getFlag("PlayerFOV", 70)
	local camera = workspace.CurrentCamera
	local currentFOV = if fovFlag.Value ~= 70 then fovFlag.Value else (if camera then camera.FieldOfView else 70)
	makeSlider("Field of View", 560, (currentFOV - 40) / 80, function(val)
		local fov = math.floor(40 + val * 80) -- Range: 40-120
		fovFlag.Value = fov
		if workspace.CurrentCamera then
			workspace.CurrentCamera.FieldOfView = fov
		end
	end)

	-- ============================================================
	-- RESET BUTTON (at bottom)
	-- ============================================================
	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.new(0.35, 0, 0, 30)
	resetBtn.Position = UDim2.new(0.325, 0, 0, 650)
	resetBtn.BackgroundColor3 = Color3.fromRGB(25, 8, 15)
	resetBtn.BackgroundTransparency = 0
	resetBtn.Text = "Reset Defaults"
	resetBtn.TextColor3 = C.textSecondary
	resetBtn.TextScaled = true
	resetBtn.Font = Enum.Font.Gotham
	resetBtn.ZIndex = 32
	resetBtn.Parent = panel

	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 6)
	resetCorner.Parent = resetBtn

	local resetStroke = Instance.new("UIStroke")
	resetStroke.Color = C.textMuted
	resetStroke.Thickness = 1
	resetStroke.Transparency = 0.3
	resetStroke.Parent = resetBtn

	resetBtn.MouseButton1Click:Connect(function()
		-- Reset all settings to defaults
		musicVolumeFlag.Value = 0.3
		sfxVolumeFlag.Value = 0.8
		shadowsFlag.Value = true
		particlesFlag.Value = true
		auraIntensityFlag.Value = 1.0
		hideOtherAurasFlag.Value = false
		uiParticlesFlag.Value = true
		fovFlag.Value = 70
		Lighting.GlobalShadows = true

		local b = Lighting:FindFirstChildOfClass("BloomEffect")
		if b then b.Enabled = true end

		local a = Lighting:FindFirstChildOfClass("Atmosphere")
		if a then a.Density = originalDensity end

		if workspace.CurrentCamera then
			workspace.CurrentCamera.FieldOfView = 70
		end

		-- Re-enable all particles
		for _, desc in workspace:GetDescendants() do
			if desc:IsA("ParticleEmitter") then
				desc.Enabled = true
			end
		end

		for _, gui in screenGui:GetDescendants() do
			if gui.Name and string.find(gui.Name, "DigiParticle") then
				gui.Visible = true
			end
		end

		-- Rebuild the settings UI to reflect reset values
		onClose()
		task.wait(0.1)
		SettingsUI.build(screenGui, onClose)
	end)
end

return SettingsUI
