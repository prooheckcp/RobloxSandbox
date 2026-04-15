--[[
    Loads a whole directory of files and returns the cached data
    from each file in that directory

    @param directory Instance -- The path to the place

    @return {any} -- Returns the return data of all module scripts in the directory
]]
local function loadDirectory(directory: Instance, useKeyIndex: boolean?): {any}
    local newArray: {any} = {}

    for _, instance: Instance in directory:GetChildren() do
        if not instance:IsA("ModuleScript") then
            continue
        end

        local success: boolean, errorMessage: string = pcall(function()
            debug.setmemorycategory(instance.Name)
            if useKeyIndex then
                newArray[instance.Name] = require(instance)
            else
                table.insert(newArray, require(instance))
            end
        end)

        if not success then
            warn(errorMessage)
            return {}
        end
    end

    return newArray
end

return loadDirectory