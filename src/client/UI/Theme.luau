--!strict
-- Every color, font, size and timing the UI uses. Screens and components read from
-- here instead of repeating literal values, so the whole look changes in one place.
-- Palette and contrast checks: docs/roblox-ui-guide.md.

local MERRIWEATHER = Font.fromEnum(Enum.Font.Merriweather).Family
local NUNITO = Font.fromEnum(Enum.Font.Nunito).Family

local Theme = {}

-- The UI is laid out in these pixels and scaled to fit the player's screen
Theme.DESIGN_SIZE = Vector2.new(1280, 720)

-- Roblox refuses TextSize above this; use the ScaledText component for bigger text
Theme.MAX_TEXT_SIZE = 100

Theme.Colors = table.freeze({
	paper = Color3.fromHex("F3EAD7"), -- washi background
	paperLight = Color3.fromHex("FBF6EA"), -- cards and answer buttons
	paperDim = Color3.fromHex("E9DFC9"), -- locked cards
	track = Color3.fromHex("E2D6BC"), -- empty part of progress bars and sliders
	ink = Color3.fromHex("1E1A17"), -- sumi ink: main text, borders
	inkSoft = Color3.fromHex("3A332D"), -- long body text
	textMuted = Color3.fromHex("5E554B"), -- secondary text (6:1 on paper)
	textLocked = Color3.fromHex("655A4E"), -- text on locked cards
	lockedBorder = Color3.fromHex("9A8F80"), -- decoration only (too faint for text)
	vermilion = Color3.fromHex("B8372B"), -- the one accent: main buttons, seals
	overlay = Color3.fromHex("000000"), -- dims the screen behind popups
})

Theme.Fonts = table.freeze({
	display = Font.new(MERRIWEATHER, Enum.FontWeight.Heavy), -- titles, main buttons
	displayBold = Font.new(MERRIWEATHER, Enum.FontWeight.Bold), -- secondary buttons
	body = Font.new(NUNITO, Enum.FontWeight.SemiBold),
	bodyBold = Font.new(NUNITO, Enum.FontWeight.Bold),
	bodyHeavy = Font.new(NUNITO, Enum.FontWeight.ExtraBold),
	-- Roblox draws kanji with its built-in Japanese font; this sets the weight
	kanji = Font.new(MERRIWEATHER, Enum.FontWeight.Heavy),
})

Theme.TextSize = table.freeze({
	hero = 58, -- welcome title
	title = 46, -- screen titles
	question = 36,
	cardTitle = 18,
	button = 24,
	buttonSmall = 21,
	body = 20,
	labelLarge = 18,
	label = 17,
	caption = 15,
	small = 14,
})

Theme.Size = table.freeze({
	border = 2, -- standard ink outline
	radius = UDim.new(0, 4),
	radiusSmall = UDim.new(0, 3),
	shadowOffset = 5, -- solid ink drop under raised buttons and cards
	buttonHeight = 64,
	iconButton = 52,
	screenPadding = 80, -- left/right margin of screen content
	gap = 16,
	gapLarge = 28,
})

Theme.Transparency = table.freeze({
	watermark = 0.95, -- giant background kanji
	overlay = 0.35,
	disabled = 0.5,
})

Theme.Motion = table.freeze({
	press = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	enter = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	PRESS_SCALE = 0.97,
})

return table.freeze(Theme)
