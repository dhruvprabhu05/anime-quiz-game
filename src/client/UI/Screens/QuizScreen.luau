-- One question at a time: kanji counter, progress bar, the question in a framed card, and
-- four answer buttons. Answers are locked briefly when each question appears, which stops
-- accidental double-taps and keeps the pace under the server's spam limit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local QuestionBank = require(Shared:WaitForChild("Data"):WaitForChild("QuestionBank"))

local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Kanji = require(UI.Util.Kanji)
local Components = UI.Components
local Label = require(Components.Label)
local ProgressBar = require(Components.ProgressBar)
local OrnateCard = require(Components.OrnateCard)
local AnswerButton = require(Components.AnswerButton)

local e = React.createElement
local Colors, TextSize, Fonts = Theme.Colors, Theme.TextSize, Theme.Fonts

local CONTENT_LEFT = 160
local CONTENT_WIDTH = 960
local HEADER_TOP = 44
local HEADER_HEIGHT = 40
local HEADER_GAP = UDim.new(0, 14)
local COUNTER_TEXT_SIZE = 30
local PROGRESS_HEIGHT = 8
local CARD_TOP = 150
local CARD_HEIGHT = 190
local ANSWERS_TOP = 368
local ANSWER_GAP = 18
local ANSWER_HEIGHT = 104
local HINT = "Choose the answer that feels most like you"
local WAITING_TEXT = "Reading your answers…"

export type Props = {
	questionIndex: number, -- index into QuestionBank
	number: number, -- 1-based position in this quiz
	total: number,
	finished: boolean, -- all answered; waiting for the server's result
	onAnswer: (answerIndex: number) -> (),
}

local function Header(props: { number: number, total: number })
	return e("Frame", {
		Position = UDim2.fromOffset(CONTENT_LEFT, HEADER_TOP),
		Size = UDim2.fromOffset(CONTENT_WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = HEADER_GAP }),
		Row = e("Frame", {
			Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Left = e("Frame", {
				Size = UDim2.fromScale(0.5, 1),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = HEADER_GAP,
				}),
				Counter = e(Label, {
					text = Kanji.questionLabel(props.number),
					font = Fonts.kanji,
					textSize = COUNTER_TEXT_SIZE,
					color = Colors.vermilion,
					wrapped = false,
					size = UDim2.fromScale(0, 0),
					automaticSize = Enum.AutomaticSize.XY,
					layoutOrder = 1,
				}),
				Count = e(Label, {
					text = `Question {props.number} of {props.total}`,
					font = Fonts.bodyBold,
					textSize = TextSize.labelLarge,
					color = Colors.textMuted,
					wrapped = false,
					size = UDim2.fromScale(0, 0),
					automaticSize = Enum.AutomaticSize.XY,
					layoutOrder = 2,
				}),
			}),
			Hint = e(Label, {
				text = HINT,
				font = Fonts.bodyBold,
				textSize = TextSize.caption,
				color = Colors.textMuted,
				alignX = Enum.TextXAlignment.Right,
				anchorPoint = Vector2.new(1, 0),
				position = UDim2.fromScale(1, 0),
				size = UDim2.fromScale(0.5, 1),
				automaticSize = Enum.AutomaticSize.None,
			}),
		}),
		Progress = e(ProgressBar, {
			progress = props.number / props.total,
			size = UDim2.new(1, 0, 0, PROGRESS_HEIGHT),
			layoutOrder = 2,
		}),
	})
end

local function QuizScreen(props: Props)
	local question = QuestionBank.getQuestion(props.questionIndex)
	local answersEnabled, setAnswersEnabled = React.useState(false)
	-- The question number already answered. Checked synchronously, so two taps landing in the
	-- same frame (before React re-renders with the buttons disabled) can't submit twice.
	local answeredNumber = React.useRef(0)

	-- Lock the answers for a moment each time a new question appears
	React.useEffect(function()
		setAnswersEnabled(false)
		local unlock = task.delay(Config.Quiz.CLIENT_ANSWER_LOCK_SECONDS, function()
			setAnswersEnabled(true)
		end)
		return function()
			task.cancel(unlock)
		end
	end, { props.number })

	local answers = {
		Grid = e("UIGridLayout", {
			CellSize = UDim2.fromOffset((CONTENT_WIDTH - ANSWER_GAP) / 2, ANSWER_HEIGHT),
			CellPadding = UDim2.fromOffset(ANSWER_GAP, ANSWER_GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for index, answer in question.answers do
		answers["Answer" .. index] = e(AnswerButton, {
			marker = Kanji.ANSWER_MARKERS[index],
			text = answer.text,
			enabled = answersEnabled and not props.finished,
			layoutOrder = index,
			onActivated = function()
				if answeredNumber.current == props.number then
					return
				end
				answeredNumber.current = props.number
				setAnswersEnabled(false)
				props.onAnswer(index)
			end,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Header = e(Header, { number = props.number, total = props.total }),
		Card = e(OrnateCard, {
			position = UDim2.fromOffset(CONTENT_LEFT, CARD_TOP),
			size = UDim2.fromOffset(CONTENT_WIDTH, CARD_HEIGHT),
		}, {
			Question = e(Label, {
				text = if props.finished then WAITING_TEXT else question.text,
				font = Fonts.display,
				textSize = TextSize.question,
				lineHeight = 1.15,
				size = UDim2.fromScale(1, 1),
				automaticSize = Enum.AutomaticSize.None,
			}),
		}),
		Answers = if props.finished
			then nil
			else e("Frame", {
				Position = UDim2.fromOffset(CONTENT_LEFT, ANSWERS_TOP),
				Size = UDim2.fromOffset(CONTENT_WIDTH, 2 * ANSWER_HEIGHT + ANSWER_GAP),
				BackgroundTransparency = 1,
			}, answers),
	})
end

return QuizScreen
