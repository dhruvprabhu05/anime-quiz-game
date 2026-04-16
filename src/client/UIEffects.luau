local TweenService = game:GetService("TweenService")

local UIEffects = {}

-- ============================================================
-- Color palette — Dark Anime / JJK / Solo Leveling
-- ============================================================
UIEffects.COLORS = {
	bg = Color3.fromRGB(5, 3, 15),
	bgCard = Color3.fromRGB(10, 8, 22),
	bgPanel = Color3.fromRGB(12, 10, 28),

	neonCyan = Color3.fromRGB(0, 240, 255),
	neonMagenta = Color3.fromRGB(255, 0, 200),
	neonPurple = Color3.fromRGB(160, 60, 255),
	neonBlue = Color3.fromRGB(60, 100, 255),
	neonGold = Color3.fromRGB(255, 200, 50),

	textPrimary = Color3.fromRGB(240, 240, 255),
	textSecondary = Color3.fromRGB(120, 115, 150),
	textMuted = Color3.fromRGB(60, 55, 80),
}

-- ============================================================
-- Core effects
-- ============================================================

function UIEffects.addGradient(parent: GuiObject, colorStart: Color3, colorEnd: Color3, rotation: number?)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorStart),
		ColorSequenceKeypoint.new(1, colorEnd),
	})
	gradient.Rotation = rotation or 135
	gradient.Parent = parent
	return gradient
end

function UIEffects.addGlow(parent: GuiObject, color: Color3, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = 0.3
	stroke.Parent = parent
	return stroke
end

-- Neon pulsing border — the JJK signature effect
function UIEffects.addNeonPulse(parent: GuiObject, color: Color3, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "NeonPulse"
	stroke.Color = color
	stroke.Thickness = thickness or 1.5
	stroke.Transparency = 0.2
	stroke.Parent = parent

	task.spawn(function()
		while stroke and stroke.Parent do
			TweenService:Create(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.6,
			}):Play()
			task.wait(1.5)
			TweenService:Create(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.15,
			}):Play()
			task.wait(1.5)
		end
	end)

	return stroke
end

-- Horizontal scan line that sweeps down the frame
function UIEffects.addScanLine(parent: Frame)
	local scanLine = Instance.new("Frame")
	scanLine.Name = "ScanLine"
	scanLine.Size = UDim2.new(1, 0, 0, 1)
	scanLine.Position = UDim2.new(0, 0, 0, 0)
	scanLine.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
	scanLine.BackgroundTransparency = 0.7
	scanLine.BorderSizePixel = 0
	scanLine.ZIndex = 15
	scanLine.Parent = parent

	task.spawn(function()
		while scanLine and scanLine.Parent do
			scanLine.Position = UDim2.new(0, 0, -0.02, 0)
			scanLine.BackgroundTransparency = 0.7
			TweenService:Create(scanLine, TweenInfo.new(3, Enum.EasingStyle.Linear), {
				Position = UDim2.new(0, 0, 1.02, 0),
			}):Play()
			task.wait(3)
			task.wait(math.random(20, 50) / 10)
		end
	end)
end

-- Digital noise particles (tiny dots that flicker)
function UIEffects.addDigitalParticles(parent: Frame, count: number?)
	local numParticles = count or 15
	for i = 1, numParticles do
		local particle = Instance.new("Frame")
		particle.Name = "DigiParticle_" .. i
		particle.BorderSizePixel = 0
		local size = math.random(1, 3)
		particle.Size = UDim2.new(0, size, 0, size)
		particle.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0)
		particle.ZIndex = 2
		particle.Parent = parent

		-- Random neon color
		local colors = {
			Color3.fromRGB(0, 240, 255),
			Color3.fromRGB(255, 0, 200),
			Color3.fromRGB(160, 60, 255),
			Color3.fromRGB(60, 100, 255),
		}
		particle.BackgroundColor3 = colors[math.random(1, #colors)]
		particle.BackgroundTransparency = math.random(50, 80) / 100

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		task.spawn(function()
			task.wait(math.random(0, 40) / 10)
			while particle and particle.Parent do
				-- Flicker: appear, drift slightly, fade
				particle.BackgroundTransparency = math.random(40, 70) / 100
				local targetX = particle.Position.X.Scale + (math.random(-5, 5) / 100)
				local targetY = particle.Position.Y.Scale + (math.random(-8, -2) / 100)

				TweenService:Create(particle, TweenInfo.new(math.random(20, 40) / 10, Enum.EasingStyle.Sine), {
					Position = UDim2.new(targetX, 0, targetY, 0),
					BackgroundTransparency = 0.95,
				}):Play()
				task.wait(math.random(20, 40) / 10)

				-- Reset to random position
				particle.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(80, 110) / 100, 0)
				particle.BackgroundTransparency = math.random(40, 70) / 100
			end
		end)
	end
end

-- Neon button style with hover glow
function UIEffects.addNeonButton(button: TextButton, neonColor: Color3)
	local stroke = Instance.new("UIStroke")
	stroke.Color = neonColor
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), {
			Thickness = 2.5,
			Transparency = 0,
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.1,
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.2), {
			Thickness = 1.5,
			Transparency = 0.3,
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.3,
		}):Play()
	end)
end

-- Legacy-compatible button hover (for non-neon buttons)
function UIEffects.addButtonHover(button: TextButton, baseColor: Color3)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 0
	stroke.Transparency = 0.5
	stroke.Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), { Thickness = 1.5, Transparency = 0.4 }):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), { Thickness = 0, Transparency = 0.5 }):Play()
	end)
end

-- Pulse animation
function UIEffects.addPulse(element: GuiObject)
	task.spawn(function()
		while element and element.Parent do
			local tween = TweenService:Create(element, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
				Size = UDim2.new(
					element.Size.X.Scale + 0.005, element.Size.X.Offset,
					element.Size.Y.Scale + 0.003, element.Size.Y.Offset
				),
			})
			tween:Play()
			tween.Completed:Wait()
		end
	end)
end

-- Neon divider line with glow
function UIEffects.addDivider(parent: GuiObject, yPosition: number, color: Color3?)
	local neonColor = color or Color3.fromRGB(0, 240, 255)

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0.5, 0, 0, 1)
	divider.Position = UDim2.new(0.25, 0, yPosition, 0)
	divider.BackgroundColor3 = neonColor
	divider.BackgroundTransparency = 0.3
	divider.BorderSizePixel = 0
	divider.ZIndex = 3
	divider.Parent = parent

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = divider

	-- Subtle glow line behind it
	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(0.5, 0, 0, 5)
	glow.Position = UDim2.new(0.25, 0, yPosition, -2)
	glow.BackgroundColor3 = neonColor
	glow.BackgroundTransparency = 0.85
	glow.BorderSizePixel = 0
	glow.ZIndex = 2
	glow.Parent = parent

	local glowGrad = gradient:Clone()
	glowGrad.Parent = glow

	return divider
end

-- Glitch text effect (brief offset flicker)
function UIEffects.addGlitchText(label: TextLabel)
	task.spawn(function()
		while label and label.Parent do
			task.wait(math.random(30, 80) / 10)
			local origPos = label.Position
			-- Quick offset
			label.Position = UDim2.new(origPos.X.Scale + 0.003, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset)
			label.TextColor3 = Color3.fromRGB(255, 0, 200)
			task.wait(0.05)
			label.Position = UDim2.new(origPos.X.Scale - 0.002, origPos.X.Offset, origPos.Y.Scale + 0.002, origPos.Y.Offset)
			label.TextColor3 = Color3.fromRGB(0, 240, 255)
			task.wait(0.05)
			label.Position = origPos
			label.TextColor3 = Color3.fromRGB(240, 240, 255)
		end
	end)
end

-- Dark glass background for a frame
function UIEffects.applyDarkGlass(frame: Frame)
	frame.BackgroundColor3 = Color3.fromRGB(8, 6, 20)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	UIEffects.addGradient(frame, Color3.fromRGB(12, 8, 25), Color3.fromRGB(5, 3, 15), 160)
end

-- Kept for backwards compatibility
function UIEffects.addFloatingParticles(parent: Frame, count: number?)
	UIEffects.addDigitalParticles(parent, count)
end

-- Slide an element in
function UIEffects.slideIn(element: GuiObject, fromDirection: string?, duration: number?)
	local targetPos = element.Position
	local offset = 0.05
	if fromDirection == "bottom" then
		element.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale + offset, targetPos.Y.Offset)
	elseif fromDirection == "left" then
		element.Position = UDim2.new(targetPos.X.Scale - offset, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset)
	elseif fromDirection == "right" then
		element.Position = UDim2.new(targetPos.X.Scale + offset, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset)
	else
		element.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale - offset, targetPos.Y.Offset)
	end
	TweenService:Create(element, TweenInfo.new(duration or 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = targetPos,
	}):Play()
end

return UIEffects
