-- Re-applies saved settings from ReplicatedStorage flags after respawn
-- Settings are stored as BoolValue/NumberValue objects that persist across respawns

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local function getFlag(name: string): Instance?
	return ReplicatedStorage:FindFirstChild(name)
end

local function applySettings()
	-- Shadows
	local shadowsFlag = getFlag("ShadowsEnabled")
	if shadowsFlag then
		Lighting.GlobalShadows = shadowsFlag.Value
	end

	-- Particles
	local particlesFlag = getFlag("ParticlesEnabled")
	if particlesFlag then
		for _, desc in workspace:GetDescendants() do
			if desc:IsA("ParticleEmitter") then
				desc.Enabled = particlesFlag.Value
			end
		end
	end

	-- Aura intensity
	local intensityFlag = getFlag("AuraIntensity")
	if intensityFlag then
		for _, desc in workspace:GetDescendants() do
			if desc:IsA("ParticleEmitter") and desc:GetAttribute("AuraEffect") then
				if not desc:GetAttribute("OriginalRate") then
					desc:SetAttribute("OriginalRate", desc.Rate)
				end
				local orig = desc:GetAttribute("OriginalRate")
				desc.Rate = math.max(1, math.floor(orig * intensityFlag.Value))
			end
		end
	end

	-- Hide other players' auras
	local hideOthersFlag = getFlag("HideOtherAuras")
	if hideOthersFlag and hideOthersFlag.Value then
		for _, otherPlayer in Players:GetPlayers() do
			if otherPlayer ~= player and otherPlayer.Character then
				for _, desc in otherPlayer.Character:GetDescendants() do
					if desc:GetAttribute("AuraEffect") then
						if desc:IsA("ParticleEmitter") or desc:IsA("PointLight") then
							desc.Enabled = false
						end
					end
				end
			end
		end
	end

	-- Bloom
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	-- Bloom state is managed by SettingsUI toggle directly, persists across respawn

	-- Atmosphere density
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	-- Atmosphere state is managed by SettingsUI toggle directly, persists across respawn

	-- FOV
	local fovFlag = getFlag("PlayerFOV")
	if fovFlag and workspace.CurrentCamera then
		workspace.CurrentCamera.FieldOfView = fovFlag.Value
	end

	-- UI particles
	local uiParticlesFlag = getFlag("UIParticlesEnabled")
	if uiParticlesFlag then
		local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("QuizGameUI")
		if screenGui then
			for _, gui in screenGui:GetDescendants() do
				if gui.Name and string.find(gui.Name, "DigiParticle") then
					gui.Visible = uiParticlesFlag.Value
				end
			end
		end
	end
end

-- Apply on respawn
player.CharacterAdded:Connect(function()
	-- Wait for character to load and auras to be applied
	task.wait(1.5)
	applySettings()
end)

-- Also apply on camera change (FOV resets when camera recreates)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.wait(0.1)
	local fovFlag = getFlag("PlayerFOV")
	if fovFlag and workspace.CurrentCamera then
		workspace.CurrentCamera.FieldOfView = fovFlag.Value
	end
end)
