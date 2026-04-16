local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ZonePlus = require(ReplicatedStorage.Packages.ZonePlus)
local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm
local attributeToCharm = require(ReplicatedStorage.Functions.attributeToCharm)
local Charm = require(ReplicatedStorage.Packages.Charm)

type Signal<T> = Signal.Signal<T>
type Trove = Trove.Trove
type Atom<T> = Charm.Atom<T>

local DEFAULT_MAX_QUEUE: number = 5

-- Attributes
local CURRENT_QUEUE_COUNT: string = "CurrentQueueCount"
local MAX_QUEUE_SIZE: string = "MaxQueueSize"

local QueuePad = Component.new({
    Tag = "QueuePad",
})
QueuePad.Instance = newproxy() :: Instance
QueuePad.JoinedQueue = newproxy() :: Signal<Player>
QueuePad.LeftQueue = newproxy() :: Signal<Player>
QueuePad.CurrentCount = newproxy() :: Atom<number>
QueuePad.MaxCount = newproxy() :: Atom<number>
QueuePad._CurrentQueue = {} :: {[string]: true} -- O(1) search <PlayerId, boolean>

function QueuePad:Construct()
    self._CurrentQueue = {}

    self._Trove = Trove.new()
    self.JoinedQueue = self._Trove:Add(Signal.new())
    self.LeftQueue = self._Trove:Add(Signal.new())
    
    self.CurrentCount = attributeToCharm(self.Instance, CURRENT_QUEUE_COUNT, 0, self._Trove)
    self.MaxCount = attributeToCharm(self.Instance, MAX_QUEUE_SIZE, DEFAULT_MAX_QUEUE, self._Trove)

    self._Trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
        self:_RemovePlayerFromQueue(player)
    end))

    local zone = ZonePlus.new(self.Instance)
    local serverComm = ServerComm.new(self.Instance, script.Name)

    serverComm:BindFunction("GetCurrentQueue", function()
        return self._CurrentQueue
    end)

    local joinedQueueSignal = serverComm:CreateSignal("JoinedQueue")
    local leftQueueSignal = serverComm:CreateSignal("LeftQueue")

    self._Trove:Add(self.JoinedQueue:Connect(function(player: Player)
        joinedQueueSignal:FireAll(tostring(player.UserId))
    end))

    self._Trove:Add(self.LeftQueue:Connect(function(player: Player)
        leftQueueSignal:FireAll(tostring(player.UserId))
    end))

    self._Trove:Add(zone.playerEntered:Connect(function(player: Player)
        self:_AddPlayerToQueue(player)
    end), "Disconnect")

    self._Trove:Add(zone.playerExited:Connect(function(player: Player)
        self:_RemovePlayerFromQueue(player)
    end), "Disconnect")

    self._Trove:Add(serverComm)
end

function QueuePad:_AddPlayerToQueue(player: Player)
    if 
        self._CurrentQueue[tostring(player.UserId)] or -- Already in queue
        self._CurrentPlayerCount >= self._MaxCount()  -- Queue is full
    then
        return
    end

    self.CurrentCount(self.CurrentCount() + 1)
    self._CurrentQueue[tostring(player.UserId)] = true
    self.JoinedQueue:Fire(player)
end

function QueuePad:_RemovePlayerFromQueue(player: Player)
    if not self._CurrentQueue[tostring(player.UserId)] then -- Not in queue
        return
    end

    self.CurrentCount(self.CurrentCount() - 1)
    self._CurrentQueue[tostring(player.UserId)] = nil
    self.LeftQueue:Fire(player)
end

function QueuePad:Stop()
    self._Trove:Destroy()
end

return QueuePad