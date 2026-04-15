local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local loadDictionary = require(ReplicatedStorage.Functions.loadDirectory)

loadDictionary(ServerScriptService.Components)