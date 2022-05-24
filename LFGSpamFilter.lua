local addonName, addon = ...
local modules = {}
local frame = CreateFrame('Frame')
LFGSpamFilterAddon = addon

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

frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', function (_, event, arg1)
    if event == 'ADDON_LOADED' and arg1 == addonName then
        frame:UnregisterEvent(event)

        for _, module in ipairs(modules) do
            if module.init then
                module.init()
            end
        end
    end
end)
