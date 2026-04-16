local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local ClientComm = require(ReplicatedStorage.Packages.Comm).ClientComm
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

type Trove = Trove.Trove
type Signal<T> = Signal.Signal<T>

local QueuePad = Component.new({
    Tag = "QueuePad",
})
QueuePad.Instance = newproxy() :: Instance
QueuePad.JoinedQueue = newproxy() :: Signal<Player>
QueuePad.LeftQueue = newproxy() :: Signal<Player>
QueuePad._CurrentQueue = {} :: {[string]: true} -- O(1) search <PlayerId, boolean>

function QueuePad:Construct()
    self._CurrentQueue = {}
    self._Trove = Trove.new()

    self.JoinedQueue = self._Trove:Add(Signal.new())
    self.LeftQueue = self._Trove:Add(Signal.new())

    local clientComm = ClientComm.new(self.Instance, true, script.Name)

    clientComm:GetFunction("GetCurrentQueue")():andThen(function(currentQueue: {[string]: true})
        self._CurrentQueue = currentQueue
    end)

    local joinedQueueSignal = self._Trove:Add(clientComm:GetSignal("JoinedQueue"))
    local leftQueueSignal = self._Trove:Add(clientComm:GetSignal("LeftQueue"))

    joinedQueueSignal:Connect(function(userid: string)
        if self._CurrentQueue[userid] then
            return
        end

        self._CurrentQueue[userid] = true
        self.JoinedQueue:Fire(Players:GetPlayerByUserId(tonumber(userid)))
    end)

    leftQueueSignal:Connect(function(userid: string)
        if not self._CurrentQueue[userid] then
            return
        end

        self._CurrentQueue[userid] = nil
        self.LeftQueue:Fire(Players:GetPlayerByUserId(tonumber(userid)))
    end)
end

function QueuePad:Stop()
    self._Trove:Destroy()
end

return QueuePad