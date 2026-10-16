--!strict
-- Server entry point: creates the remotes, then starts each service in dependency order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local Services = script.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GamePassService = require(Services:WaitForChild("GamePassService"))
local QuizService = require(Services:WaitForChild("QuizService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))

Remotes.createAll()

PlayerDataService.init()
GamePassService.init()
QuizService.init()
MonetizationService.init()
