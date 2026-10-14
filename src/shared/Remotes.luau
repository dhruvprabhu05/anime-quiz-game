-- Declares all RemoteEvents and RemoteFunctions used for client-server communication.
-- Both client and server require this module to get references by name.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local remoteEvents = {
	"SubmitAnswer",       -- Client -> Server: player picked an answer
	"QuizResult",         -- Server -> Client: final archetype result
	"TimerSkipGranted",   -- Server -> Client: 5 minutes removed from timer
}

local remoteFunctions = {
	"LoadPlayerData",     -- Client -> Server: get saved collection + current archetype
	"StartQuiz",          -- Client -> Server: get shuffled question order, returns question indices
	"CheckGamePass",      -- Client -> Server: check if player owns Instant Unlock
	"CheckQuizCooldown",  -- Client -> Server: get remaining quiz cooldown seconds
}

function Remotes.init()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage

	for _, name in remoteEvents do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	for _, name in remoteFunctions do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end
end

function Remotes.get(name: string): Instance
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	return folder:WaitForChild(name)
end

return Remotes
