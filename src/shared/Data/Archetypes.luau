--!strict
-- The 10 personality titles a player can earn, in collection order.

export type Archetype = {
	id: string,
	name: string,
	description: string,
	examples: { string },
	-- Kanji shown on the title's seal stamp, and what it means
	kanji: string,
	kanjiMeaning: string,
}

local Archetypes: { Archetype } = {
	{
		id = "hot_headed_hero",
		name = "The Hot-Headed Hero",
		description = "You charge in headfirst and figure it out along the way. Your passion is your greatest weapon — when you believe in something, nothing can stop you. You might be reckless, but your fire inspires everyone around you.",
		examples = { "Naruto", "Goku", "Asta" },
		kanji = "炎",
		kanjiMeaning = "flame",
	},
	{
		id = "cool_strategist",
		name = "The Cool Strategist",
		description = "You see ten moves ahead while everyone else is stuck on one. Calm under pressure, you prefer brains over brawn. People might mistake your composure for coldness, but you care deeply — you just show it through action.",
		examples = { "Lelouch", "Shikamaru", "Light" },
		kanji = "智",
		kanjiMeaning = "wisdom",
	},
	{
		id = "lone_wolf",
		name = "The Lone Wolf",
		description = "You walk your own path and don't need anyone's approval. Independent and self-reliant, you've learned to depend on yourself. Behind the tough exterior, there's someone who protects what matters most — silently.",
		examples = { "Sasuke", "Levi", "Guts" },
		kanji = "狼",
		kanjiMeaning = "wolf",
	},
	{
		id = "gentle_protector",
		name = "The Gentle Protector",
		description = "Your kindness isn't weakness — it's your greatest strength. You fight not because you love battle, but because you love the people behind you. You see the good in everyone, even your enemies.",
		examples = { "Tanjiro", "Deku", "Tohru" },
		kanji = "守",
		kanjiMeaning = "protect",
	},
	{
		id = "chaotic_wildcard",
		name = "The Chaotic Wildcard",
		description = "Nobody can predict your next move — not even you sometimes. You live for excitement and thrive in chaos. Your unpredictability makes you dangerous, but also endlessly entertaining.",
		examples = { "Gojo", "Hisoka", "Denji" },
		kanji = "乱",
		kanjiMeaning = "chaos",
	},
	{
		id = "silent_powerhouse",
		name = "The Silent Powerhouse",
		description = "You don't talk about what you can do — you just do it. Your strength speaks for itself. While others boast, you stay quiet, and when you finally act, everyone watches in awe.",
		examples = { "Saitama", "Jotaro", "Mob" },
		kanji = "静",
		kanjiMeaning = "stillness",
	},
	{
		id = "loyal_companion",
		name = "The Loyal Companion",
		description = "You'd walk through fire for the people you care about. Loyalty isn't just a word to you — it's your defining trait. You might doubt yourself, but when your friends need you, you become unstoppable.",
		examples = { "Killua", "Zenitsu", "Chopper" },
		kanji = "絆",
		kanjiMeaning = "bond",
	},
	{
		id = "wise_mentor",
		name = "The Wise Mentor",
		description = "You've seen things, learned things, and now you guide others with quiet confidence. You're laid-back on the surface but carry deep knowledge and experience. People come to you for answers — and you always deliver.",
		examples = { "Kakashi", "Urahara", "Shanks" },
		kanji = "師",
		kanjiMeaning = "teacher",
	},
	{
		id = "rebel_with_a_cause",
		name = "The Rebel With a Cause",
		description = "You refuse to accept the world as it is. Rules that don't make sense? You break them. Systems that are unjust? You tear them down. Your rebellion isn't random — it's fueled by a vision only you can see.",
		examples = { "Eren", "Lelouch", "Vegeta" },
		kanji = "反",
		kanjiMeaning = "rebel",
	},
	{
		id = "cheerful_optimist",
		name = "The Cheerful Optimist",
		description = "Your energy is infectious and your smile is a weapon. No matter how dark things get, you refuse to give up. You lift everyone around you just by being yourself — and that's your true superpower.",
		examples = { "Luffy", "Anya", "Hinata Shoyo" },
		kanji = "陽",
		kanjiMeaning = "sun",
	},
}

for _, archetype in Archetypes do
	table.freeze(archetype.examples)
	table.freeze(archetype)
end
table.freeze(Archetypes)

local ArchetypesModule = {}

ArchetypesModule.list = Archetypes

function ArchetypesModule.getById(id: string): Archetype?
	for _, archetype in Archetypes do
		if archetype.id == id then
			return archetype
		end
	end
	return nil
end

function ArchetypesModule.getIds(): { string }
	local ids = {}
	for _, archetype in Archetypes do
		table.insert(ids, archetype.id)
	end
	return ids
end

return ArchetypesModule
