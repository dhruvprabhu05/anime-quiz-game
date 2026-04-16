local AuraRarities = {}

export type RarityInfo = {
	name: string,
	color: Color3,
	dropRate: number,
	shardValue: number,
	craftCost: number,
	auras: { string },
}

local rarities: { RarityInfo } = {
	{
		name = "Common",
		color = Color3.fromRGB(200, 200, 200),
		dropRate = 0.40,
		shardValue = 1,
		craftCost = 5,
		auras = { "gentle_protector", "loyal_companion", "cheerful_optimist" },
	},
	{
		name = "Uncommon",
		color = Color3.fromRGB(80, 220, 100),
		dropRate = 0.25,
		shardValue = 3,
		craftCost = 10,
		auras = { "cool_strategist", "wise_mentor", "silent_powerhouse" },
	},
	{
		name = "Rare",
		color = Color3.fromRGB(60, 130, 255),
		dropRate = 0.18,
		shardValue = 5,
		craftCost = 20,
		auras = { "hot_headed_hero", "rebel_with_a_cause" },
	},
	{
		name = "Epic",
		color = Color3.fromRGB(180, 60, 255),
		dropRate = 0.12,
		shardValue = 10,
		craftCost = 40,
		auras = { "lone_wolf" },
	},
	{
		name = "Legendary",
		color = Color3.fromRGB(255, 200, 50),
		dropRate = 0.045,
		shardValue = 25,
		craftCost = 100,
		auras = { "chaotic_wildcard" },
	},
	{
		name = "Secret",
		color = Color3.fromRGB(255, 255, 255),
		dropRate = 0.005,
		shardValue = 50,
		craftCost = 200,
		auras = { "anime_transformation" },
	},
}

local auraToRarity: { [string]: RarityInfo } = {}
for _, rarity in rarities do
	for _, auraId in rarity.auras do
		auraToRarity[auraId] = rarity
	end
end

AuraRarities.list = rarities

function AuraRarities.getRarityForAura(auraId: string): RarityInfo?
	return auraToRarity[auraId]
end

function AuraRarities.getAllAuraIds(): { string }
	local ids = {}
	for _, rarity in rarities do
		for _, auraId in rarity.auras do
			table.insert(ids, auraId)
		end
	end
	return ids
end

function AuraRarities.roll(): { auraId: string, rarity: RarityInfo }
	local roll = math.random()
	local cumulative = 0

	for _, rarity in rarities do
		cumulative += rarity.dropRate
		if roll <= cumulative then
			local auraId = rarity.auras[math.random(1, #rarity.auras)]
			return { auraId = auraId, rarity = rarity }
		end
	end

	local last = rarities[#rarities]
	return { auraId = last.auras[1], rarity = last }
end

return AuraRarities
