--!strict
-- Answers "does this player own Instant Unlock?", caching the answer.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PASS_ID = Config.Products.INSTANT_UNLOCK_PASS_ID

local ownsPass: { [Player]: boolean } = {}

local GamePassService = {}

function GamePassService.ownsInstantUnlock(player: Player): boolean
	local cached = ownsPass[player]
	if cached ~= nil then
		return cached
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PASS_ID)
	end)
	if not ok then
		return false -- don't cache a failed lookup; ask again next time
	end
	ownsPass[player] = owns
	return owns
end

function GamePassService.init()
	-- A purchase made in this session counts immediately
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if passId == PASS_ID and wasPurchased then
			ownsPass[player] = true
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		ownsPass[player] = nil
	end)
end

return GamePassService
