--!strict
-- Game-wide constants shared by the server and the client.
-- Change a number here and every script that uses it follows.

local Config = {}

Config.Quiz = {
	-- Wait between finishing a quiz and seeing the result (also the gap before the next quiz)
	COOLDOWN_SECONDS = 15 * 60,
	-- Seconds removed from the wait by one "Skip 5 Minutes" purchase
	SKIP_SECONDS = 5 * 60,
	ANSWERS_PER_QUESTION = 4,
	-- Server spam limit: minimum average seconds per answer, measured from quiz start.
	-- Must stay below CLIENT_ANSWER_LOCK_SECONDS, or honest answers get dropped.
	MIN_SECONDS_PER_ANSWER = 0.3,
	-- The client ignores taps for this long after a question appears
	CLIENT_ANSWER_LOCK_SECONDS = 0.4,
	-- A quiz with no accepted answer for this long counts as abandoned and can be restarted
	STALE_SESSION_SECONDS = 120,
	-- One meme interlude every N questions on average (never before the first question)
	INTERLUDE_ONE_IN = 5,
}

Config.Products = {
	-- Developer Product bought to skip 5 minutes of the wait.
	-- NOTE: this ID currently points at a product named "Class Change" (99 R$) on the game's
	-- Creator Dashboard. Create a 5 R$ "Skip 5 Minutes" product and put its ID here.
	SKIP_TIMER_PRODUCT_ID = 3576830852,
	-- Game Pass that removes the wait forever.
	-- NOTE: currently the "Grand Master Pass" (199 R$); rename/reprice or replace it.
	INSTANT_UNLOCK_PASS_ID = 1797259226,
}

Config.DataStore = {
	NAME = "PlayerArchetypeData_v1",
	KEY_PREFIX = "player_",
}

table.freeze(Config.Quiz)
table.freeze(Config.Products)
table.freeze(Config.DataStore)

return table.freeze(Config)
