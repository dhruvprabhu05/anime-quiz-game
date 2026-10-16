-- The root of the UI. Owns all UI state (which screen is showing, quiz progress, the latest
-- result, the player's collection) and is the only part of the UI that talks to the server.
-- Screens just draw the state they are given and report button presses back up.
--
-- Three ScreenGuis, back to front:
--   Backdrop: full-screen paper, scroll rods and watermark
--   Content:  the current screen, kept clear of Roblox's top bar and notches, scaled to fit
--   Overlay:  meme interludes and the settings popup

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("React"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local UI = script.Parent
local Theme = require(UI.Theme)
local Format = require(UI.Util.Format)
local useFitScale = require(UI.Hooks.useFitScale)
local useRemoteEvent = require(UI.Hooks.useRemoteEvent)
local ScreenBackdrop = require(UI.Components.ScreenBackdrop)
local Interludes = require(UI.Interlude.Interludes)
local InterludeOverlay = require(UI.Interlude.InterludeOverlay)
local Screens = UI.Screens
local WelcomeScreen = require(Screens.WelcomeScreen)
local QuizScreen = require(Screens.QuizScreen)
local TimerScreen = require(Screens.TimerScreen)
local ResultsScreen = require(Screens.ResultsScreen)
local CollectionScreen = require(Screens.CollectionScreen)
local SettingsPanel = require(Screens.SettingsPanel)

local e = React.createElement

type ScreenName = "welcome" | "quiz" | "timer" | "results" | "collection"

type QuizState = {
	questionOrder: { number },
	position: number, -- 1-based index of the question being shown
	finished: boolean, -- every answer sent; waiting for the result
}

type Result = {
	archetypeId: string,
	isNew: boolean,
	revealAt: number, -- os.clock() time the wait ends
}

-- Giant faint kanji behind each screen
local WATERMARKS: { [ScreenName]: string } = table.freeze({
	welcome = "魂", -- soul
	quiz = "問", -- question
	timer = "待", -- wait
	collection = "集", -- collect
})

local DISPLAY_ORDER = table.freeze({ backdrop = 0, content = 1, overlay = 2 })
local BUSY_NOTICE = "Your last quiz is still being scored. Try again in a moment."

local function screenGui(props, children)
	props.ResetOnSpawn = false
	props.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	return e("ScreenGui", props, children)
end

local function App()
	local screen, setScreen = React.useState("welcome" :: ScreenName)
	local unlockedIds, setUnlockedIds = React.useState({} :: { string })
	local quiz, setQuiz = React.useState(nil :: QuizState?)
	local result, setResult = React.useState(nil :: Result?)
	local notice, setNotice = React.useState(nil :: string?)
	local interludeIndex, setInterludeIndex = React.useState(nil :: number?)
	local settingsOpen, setSettingsOpen = React.useState(false)
	local shownInterludes = React.useRef({})
	local scale, contentRef = useFitScale()

	-- Load the player's collection once
	React.useEffect(function()
		task.spawn(function()
			local data = Remotes.func(Remotes.Functions.LoadPlayerData):InvokeServer()
			if data then
				setUnlockedIds(data.unlockedArchetypes)
			end
		end)
	end, {})

	useRemoteEvent(Remotes.Events.QuizResult, function(archetypeId: string, waitSeconds: number)
		local isNew = not table.find(unlockedIds, archetypeId)
		if isNew then
			local updated = table.clone(unlockedIds)
			table.insert(updated, archetypeId)
			setUnlockedIds(updated)
		end
		setResult({ archetypeId = archetypeId, isNew = isNew, revealAt = os.clock() + waitSeconds })
		setQuiz(nil)
		setScreen(if waitSeconds > 0 then "timer" else "results")
	end)

	useRemoteEvent(Remotes.Events.TimerSkipGranted, function(secondsRemoved: number)
		setResult(function(current)
			if not current then
				return current
			end
			local updated = table.clone(current)
			updated.revealAt -= secondsRemoved
			return updated
		end)
	end)

	local function startQuiz()
		setNotice(nil)
		task.spawn(function()
			local ok, response = pcall(function()
				return Remotes.func(Remotes.Functions.StartQuiz):InvokeServer()
			end)
			if ok and response and response.ok then
				table.clear(shownInterludes.current)
				setQuiz({ questionOrder = response.questionOrder, position = 1, finished = false })
				setScreen("quiz")
			else
				setNotice(
					if ok and response and response.waitSeconds > 0
						then `You can take the quiz again in {Format.clock(response.waitSeconds)}.`
						else BUSY_NOTICE
				)
				setScreen("welcome")
			end
		end)
	end

	local function answer(answerIndex: number)
		Remotes.event(Remotes.Events.SubmitAnswer):FireServer(answerIndex)
		local current = quiz :: QuizState
		local isLast = current.position >= #current.questionOrder
		setQuiz({
			questionOrder = current.questionOrder,
			position = if isLast then current.position else current.position + 1,
			finished = isLast,
		})
		if not isLast and math.random(1, Config.Quiz.INTERLUDE_ONE_IN) == 1 then
			setInterludeIndex(Interludes.pickUnshown(shownInterludes.current))
		end
	end

	local currentScreen
	if screen == "quiz" and quiz then
		currentScreen = e(QuizScreen, {
			questionIndex = quiz.questionOrder[quiz.position],
			number = quiz.position,
			total = #quiz.questionOrder,
			finished = quiz.finished,
			onAnswer = answer,
		})
	elseif screen == "timer" and result then
		currentScreen = e(TimerScreen, {
			deadline = result.revealAt,
			onReveal = function()
				setScreen("results")
			end,
		})
	elseif screen == "results" and result then
		currentScreen = e(ResultsScreen, {
			archetypeId = result.archetypeId,
			isNew = result.isNew,
			unlockedCount = #unlockedIds,
			onCollection = function()
				setScreen("collection")
			end,
			onRetake = startQuiz,
		})
	elseif screen == "collection" then
		currentScreen = e(CollectionScreen, {
			unlockedIds = unlockedIds,
			onBack = function()
				setScreen("welcome")
			end,
		})
	else
		currentScreen = e(WelcomeScreen, {
			unlockedIds = unlockedIds,
			notice = notice,
			onStart = startQuiz,
			onCollection = function()
				setScreen("collection")
			end,
			onSettings = function()
				setSettingsOpen(true)
			end,
		})
	end

	return e(React.Fragment, nil, {
		Backdrop = screenGui({
			DisplayOrder = DISPLAY_ORDER.backdrop,
			ScreenInsets = Enum.ScreenInsets.None,
		}, {
			Paper = e(ScreenBackdrop, { watermark = WATERMARKS[screen] }),
		}),
		Content = screenGui({
			ref = contentRef,
			DisplayOrder = DISPLAY_ORDER.content,
			ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		}, {
			Canvas = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(Theme.DESIGN_SIZE.X, Theme.DESIGN_SIZE.Y),
				BackgroundTransparency = 1,
			}, {
				Scale = e("UIScale", { Scale = scale }),
				Screen = currentScreen,
			}),
		}),
		Overlay = screenGui({
			DisplayOrder = DISPLAY_ORDER.overlay,
			ScreenInsets = Enum.ScreenInsets.None,
		}, {
			Interlude = if interludeIndex
				then e(InterludeOverlay, {
					interludeIndex = interludeIndex,
					onDone = function()
						setInterludeIndex(nil)
					end,
				})
				else nil,
			Settings = if settingsOpen
				then e(SettingsPanel, {
					scale = scale,
					onClose = function()
						setSettingsOpen(false)
					end,
				})
				else nil,
		}),
	})
end

return App
