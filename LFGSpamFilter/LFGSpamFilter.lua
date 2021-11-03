local addonName, addon = ...
local modules = {}
local frame = CreateFrame('Frame')
LFGSpamFilterAddon = addon

function addon.module(name)
    addon[name] = {}
    table.insert(modules, name)

    return addon[name], {}
end

function addon.tryFinally(try, finally, ...)
    local status, err = pcall(try, ...)

    finally()

    if not status then
        error(err)
    end
end

frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', function (_, event, arg1)
    if event == 'ADDON_LOADED' and arg1 == addonName then
        frame:UnregisterEvent(event)

        for _, module in ipairs(modules) do
            addon[module].init()
        end
    end
end)
