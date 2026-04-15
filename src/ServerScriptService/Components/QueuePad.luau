local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ZonePlus = require(ReplicatedStorage.Packages.ZonePlus)
local Comm = require(ReplicatedStorage.Packages.Comm)

type Signal<T> = Signal.Signal<T>
type Trove = Trove.Trove

local DEFAULT_MAX_QUEUE: number = 5

-- Attributes
local CURRENT_QUEUE_COUNT: string = "CurrentQueueCount"
local MAX_QUEUE_SIZE: string = "MaxQueueSize"

local QueuePad = Component.new({
    Tag = "QueuePad",
})
QueuePad.Instance = newproxy() :: Instance
QueuePad.JoinedQueue = newproxy() :: Signal<Player>
QueuePad.LeftLobby = newproxy() :: Signal<Player>
QueuePad._CurrentQueue = {} :: {[Player]: true} -- O(1) search

function QueuePad:Construct()
    self._Trove = Trove.new()
    self._CurrentQueue = {}
    self.Instance:SetAttribute(self.Instance:GetAttribute)

    self._Trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
        self:_RemovePlayerFromQueue(player)
    end))

    local zone = ZonePlus.new(self.Instance)

    self._Trove:Add(zone.playerEntered:Connect(function(player: Player)
        self:_AddPlayerToQueue(player)
    end), "Disconnect")

    self._Trove:Add(zone.playerExited:Connect(function(player: Player)
        self:_RemovePlayerFromQueue(player)
    end), "Disconnect")
end

function QueuePad:_AddPlayerToQueue(player: Player)
    if 
        self._CurrentQueue[player] or -- Already in queue
        self._CurrentPlayerCount >= QUEUE_SIZE  -- Queue is full
    then
        return
    end

    self._CurrentQueue[player] = true
    self.JoinedQueue:Fire(player)
end

function QueuePad:_RemovePlayerFromQueue(player: Player)
    if not self._CurrentQueue[player] then -- Not in queue
        return
    end

    self._CurrentQueue[player] = nil
    self.LeftLobby:Fire(player)
end

function QueuePad:Stop()
    self._Trove:Destroy()
end

return QueuePad