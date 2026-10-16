--!strict
-- Every RemoteEvent / RemoteFunction the game uses, plus helpers to create and find them.
-- Always refer to a remote through these name constants so a typo can't silently break it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOLDER_NAME = "Remotes"

export type PlayerData = {
	currentArchetype: string, -- archetype id of the latest result ("" before the first quiz)
	unlockedArchetypes: { string }, -- archetype ids collected so far
}

export type StartQuizResult = { ok: true, questionOrder: { number } } | { ok: false, waitSeconds: number }

local Remotes = {}

local EVENT_NAMES = {
	SubmitAnswer = "SubmitAnswer", -- client -> server: (answerIndex: number)
	QuizResult = "QuizResult", -- server -> client: (archetypeId: string, waitSeconds: number)
	TimerSkipGranted = "TimerSkipGranted", -- server -> client: (secondsRemoved: number)
}

local FUNCTION_NAMES = {
	LoadPlayerData = "LoadPlayerData", -- client -> server: () -> PlayerData
	StartQuiz = "StartQuiz", -- client -> server: () -> StartQuizResult
}

Remotes.Events = table.freeze(EVENT_NAMES)
Remotes.Functions = table.freeze(FUNCTION_NAMES)

-- Server only: creates every remote. The folder is parented last, so a client that
-- finds the folder always finds all of its remotes too.
function Remotes.createAll()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in EVENT_NAMES :: { [string]: string } do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	for _, name in FUNCTION_NAMES :: { [string]: string } do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

function Remotes.event(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild(FOLDER_NAME):WaitForChild(name) :: RemoteEvent
end

function Remotes.func(name: string): RemoteFunction
	return ReplicatedStorage:WaitForChild(FOLDER_NAME):WaitForChild(name) :: RemoteFunction
end

return table.freeze(Remotes)
