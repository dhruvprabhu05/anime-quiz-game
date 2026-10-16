--!strict
-- Japanese numerals for the quiz counter ("第三問" = "question three").

local DIGITS = table.freeze({ "一", "二", "三", "四", "五", "六", "七", "八", "九" })
local TEN = "十"
local QUESTION_PREFIX = "第"
local QUESTION_SUFFIX = "問"

local Kanji = {}

-- 1 -> "一", 10 -> "十", 14 -> "十四", 24 -> "二十四" (valid for 1–99)
function Kanji.number(n: number): string
	local tens, ones = n // 10, n % 10
	local result = ""
	if tens > 1 then
		result ..= DIGITS[tens]
	end
	if tens >= 1 then
		result ..= TEN
	end
	if ones > 0 then
		result ..= DIGITS[ones]
	end
	return result
end

-- 3 -> "第三問"
function Kanji.questionLabel(n: number): string
	return QUESTION_PREFIX .. Kanji.number(n) .. QUESTION_SUFFIX
end

-- Answer markers, in answer order
Kanji.ANSWER_MARKERS = table.freeze({ DIGITS[1], DIGITS[2], DIGITS[3], DIGITS[4] })

return table.freeze(Kanji)
