local AuraDefinitions = {}

export type AuraConfig = {
	torsoColor: ColorSequence,
	torsoSpeed: NumberRange,
	torsoRate: number,
	torsoLifetime: NumberRange,
	torsoSize: NumberSequence,
	torsoSpread: Vector2,
	groundColor: ColorSequence,
	groundRate: number,
	lightColor: Color3,
	lightBrightness: number,
}

local definitions: { [string]: AuraConfig } = {
	hot_headed_hero = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 30)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30, 10)),
		}),
		torsoSpeed = NumberRange.new(3, 6),
		torsoRate = 18,
		torsoLifetime = NumberRange.new(0.4, 0.9),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(25, 25),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 10)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(255, 100, 30),
		lightBrightness = 0.6,
	},

	cool_strategist = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 220, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 170, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 120, 220)),
		}),
		torsoSpeed = NumberRange.new(1, 3),
		torsoRate = 15,
		torsoLifetime = NumberRange.new(0.8, 1.4),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(40, 40),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 150, 230)),
		}),
		groundRate = 8,
		lightColor = Color3.fromRGB(100, 170, 255),
		lightBrightness = 0.4,
	},

	lone_wolf = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 180)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 50, 140)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 80)),
		}),
		torsoSpeed = NumberRange.new(0.5, 2),
		torsoRate = 12,
		torsoLifetime = NumberRange.new(1.0, 1.5),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(50, 50),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 60, 160)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 30, 100)),
		}),
		groundRate = 8,
		lightColor = Color3.fromRGB(100, 60, 160),
		lightBrightness = 0.3,
	},

	gentle_protector = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 255, 160)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 220, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 80)),
		}),
		torsoSpeed = NumberRange.new(1, 3),
		torsoRate = 14,
		torsoLifetime = NumberRange.new(0.8, 1.3),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(35, 35),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 230, 140)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 180, 100)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(80, 220, 120),
		lightBrightness = 0.4,
	},

	chaotic_wildcard = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(220, 80, 255)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(180, 50, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 20, 200)),
		}),
		torsoSpeed = NumberRange.new(4, 8),
		torsoRate = 20,
		torsoLifetime = NumberRange.new(0.3, 0.7),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.3, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(60, 60),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 220)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 40, 255)),
		}),
		groundRate = 12,
		lightColor = Color3.fromRGB(200, 80, 255),
		lightBrightness = 0.5,
	},

	silent_powerhouse = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 225, 240)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 190, 210)),
		}),
		torsoSpeed = NumberRange.new(1.5, 4),
		torsoRate = 16,
		torsoLifetime = NumberRange.new(0.5, 1.0),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.4, 0.7),
			NumberSequenceKeypoint.new(0.8, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(30, 30),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 240, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 210, 230)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(230, 235, 255),
		lightBrightness = 0.5,
	},

	loyal_companion = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 80)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 100, 30)),
		}),
		torsoSpeed = NumberRange.new(1.5, 3.5),
		torsoRate = 14,
		torsoLifetime = NumberRange.new(0.6, 1.2),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(30, 30),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 120, 40)),
		}),
		groundRate = 8,
		lightColor = Color3.fromRGB(255, 150, 60),
		lightBrightness = 0.4,
	},

	wise_mentor = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 160, 40)),
		}),
		torsoSpeed = NumberRange.new(1, 2.5),
		torsoRate = 12,
		torsoLifetime = NumberRange.new(0.8, 1.5),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(45, 45),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 180, 60)),
		}),
		groundRate = 8,
		lightColor = Color3.fromRGB(255, 210, 80),
		lightBrightness = 0.5,
	},

	rebel_with_a_cause = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 30, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 15, 15)),
		}),
		torsoSpeed = NumberRange.new(3, 6),
		torsoRate = 18,
		torsoLifetime = NumberRange.new(0.4, 0.8),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(20, 20),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 40, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 20, 15)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(200, 40, 30),
		lightBrightness = 0.5,
	},

	cheerful_optimist = {
		torsoColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 30)),
		}),
		torsoSpeed = NumberRange.new(2, 5),
		torsoRate = 16,
		torsoLifetime = NumberRange.new(0.5, 1.0),
		torsoSize = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.3, 0.7),
			NumberSequenceKeypoint.new(0.7, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		}),
		torsoSpread = Vector2.new(40, 40),
		groundColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 40)),
		}),
		groundRate = 10,
		lightColor = Color3.fromRGB(255, 230, 60),
		lightBrightness = 0.5,
	},
}

function AuraDefinitions.get(archetypeId: string): AuraConfig?
	return definitions[archetypeId]
end

return AuraDefinitions
