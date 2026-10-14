local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

-- IMPORTANT: Replace these with real IDs from Roblox Creator Dashboard
local SKIP_5MIN_PRODUCT_ID = 3576830852 -- Developer Product ID for "Skip 5 Minutes"
local INSTANT_UNLOCK_GAMEPASS_ID = 1797259226 -- GamePass ID for "Instant Unlock"

-- Handle Developer Product purchases (timer skip)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == SKIP_5MIN_PRODUCT_ID then
		-- Notify QuizServer to clear server-side cooldown
		local timerSkipBindable = ServerScriptService:WaitForChild("QuizTimerSkipEvent")
		timerSkipBindable:Fire(player)
		local timerSkipRemote = Remotes.get("TimerSkipGranted") :: RemoteEvent
		timerSkipRemote:FireClient(player, 300) -- 300 seconds = 5 minutes
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Handle GamePass check from client
local checkGamePassRemote = Remotes.get("CheckGamePass") :: RemoteFunction
checkGamePassRemote.OnServerInvoke = function(player: Player)
	local success, ownsPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, INSTANT_UNLOCK_GAMEPASS_ID)
	end)
	if success then
		return ownsPass
	end
	return false
end

-- Expose product/gamepass IDs so client can prompt purchases
local idsFolder = Instance.new("Folder")
idsFolder.Name = "MonetizationIds"
idsFolder.Parent = ReplicatedStorage

local skipProductValue = Instance.new("IntValue")
skipProductValue.Name = "SkipProductId"
skipProductValue.Value = SKIP_5MIN_PRODUCT_ID
skipProductValue.Parent = idsFolder

local gamePassValue = Instance.new("IntValue")
gamePassValue.Name = "GamePassId"
gamePassValue.Value = INSTANT_UNLOCK_GAMEPASS_ID
gamePassValue.Parent = idsFolder
