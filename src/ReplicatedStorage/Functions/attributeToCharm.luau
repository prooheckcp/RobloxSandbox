local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Trove = Trove.Trove
type Atom<T> = Charm.Atom<T>

local atom = Charm.atom
local subscribe = Charm.subscribe

local function attributeToCharm(
        instance: Instance,
        attribute: string,
        default: any?,
        trove: Trove?
    ): Atom<any>

    local currentAttribute: any? = instance:GetAttribute(attribute)

    if not currentAttribute and default ~= nil then
        instance:SetAttribute(attribute, default)
    end

    local attributeAtom = atom(currentAttribute or default)

    if trove then
        trove:Add(instance:GetAttributeChangedSignal(attribute):Connect(function()
            local currentValue = attributeAtom()

            if currentValue ~= instance:GetAttribute(attribute) then
                currentValue(instance:GetAttribute(attribute))
            end
        end))      
        
        trove:Add(subscribe(attributeAtom, function(newValue)
            instance:SetAttribute(attribute, newValue)
        end))
    end

    return attributeAtom
end

return attributeToCharm