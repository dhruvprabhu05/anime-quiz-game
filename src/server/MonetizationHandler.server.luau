local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

-- IMPORTANT: Replace these with real IDs from Roblox Creator Dashboard
local SKIP_5MIN_PRODUCT_ID = 1797175133 -- Developer Product ID for "Skip 5 Minutes"
local INSTANT_UNLOCK_GAMEPASS_ID = 1797259226 -- GamePass ID for "Instant Unlock"
local BUY_1_SPIN_PRODUCT_ID = 0  -- Developer Product: 1 spin for 10 Robux
local BUY_5_SPINS_PRODUCT_ID = 0 -- Developer Product: 5 spins for 40 Robux

-- Handle Developer Product purchases (timer skip)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == SKIP_5MIN_PRODUCT_ID then
		local timerSkipRemote = Remotes.get("TimerSkipGranted") :: RemoteEvent
		timerSkipRemote:FireClient(player, 300) -- 300 seconds = 5 minutes
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if receiptInfo.ProductId == BUY_1_SPIN_PRODUCT_ID then
		local spinBindable = game:GetService("ServerScriptService"):WaitForChild("SpinPurchaseEvent")
		spinBindable:Fire(player, 1)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if receiptInfo.ProductId == BUY_5_SPINS_PRODUCT_ID then
		local spinBindable = game:GetService("ServerScriptService"):WaitForChild("SpinPurchaseEvent")
		spinBindable:Fire(player, 5)
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

local buy1SpinValue = Instance.new("IntValue")
buy1SpinValue.Name = "Buy1SpinProductId"
buy1SpinValue.Value = BUY_1_SPIN_PRODUCT_ID
buy1SpinValue.Parent = idsFolder

local buy5SpinsValue = Instance.new("IntValue")
buy5SpinsValue.Name = "Buy5SpinsProductId"
buy5SpinsValue.Value = BUY_5_SPINS_PRODUCT_ID
buy5SpinsValue.Parent = idsFolder
