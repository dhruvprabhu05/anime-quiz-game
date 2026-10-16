--!strict
-- Grants Developer Product purchases (currently only "Skip 5 Minutes").

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local QuizService = require(script.Parent:WaitForChild("QuizService"))

local MonetizationService = {}

local function processReceipt(receiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left before the purchase was granted; Roblox retries next time they join
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == Config.Products.SKIP_TIMER_PRODUCT_ID then
		QuizService.applyTimerSkip(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.init()
	MarketplaceService.ProcessReceipt = processReceipt
end

return MonetizationService
