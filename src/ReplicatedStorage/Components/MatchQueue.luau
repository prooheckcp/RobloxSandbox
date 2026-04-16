local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local QueuePad = require(script.Parent.QueuePad)

type QueuePad = QueuePad.QueuePad

local MatchQueue = Component.new({
    Tag = "MatchQueue",
})
MatchQueue.Instance = newproxy() :: Instance

function MatchQueue:Start()
    QueuePad:WaitForInstance(self.Instance):andThen(function(queuePad: QueuePad)
        queuePad.JoinedQueue:Connect(function(p)
            print("[test] Joined Queue", p)
        end)

        queuePad.LeftQueue:Connect(function(p)
            print("[test] Left Queue", p)
        end)
    end)
end

export type MatchQueue = typeof(MatchQueue)

return MatchQueue