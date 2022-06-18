local addonName, addon = ...
local modules = {}

function addon.module(...)
    local namespace = addon

    for _, key in ipairs({...}) do
        if namespace[key] == nil then
            namespace[key] = {}
        end

        namespace = namespace[key]
    end

    table.insert(modules, namespace)

    return namespace, {}
end

addon.on('ADDON_LOADED', function (name)
    if name == addonName then
        for _, module in ipairs(modules) do
            if module.init then
                module.init()
            end
        end

        return false
    end
end)
