-- Client entry point: starts the background music and mounts the React UI into PlayerGui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local MusicPlayer = require(script.Parent.Audio.MusicPlayer)
local App = require(script.Parent.UI.App)

MusicPlayer.start()

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local root = ReactRoblox.createRoot(Instance.new("Folder"))
root:render(ReactRoblox.createPortal(React.createElement(App), playerGui))
