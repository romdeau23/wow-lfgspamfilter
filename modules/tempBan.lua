local _, addon = ...
local tempBan, private = addon.module('tempBan')
local banned = {}
local count = 0

function tempBan.isBanned(name)
    return banned[name] ~= nil
end

function tempBan.getCount()
    return count
end

function tempBan.ban(name)
    if not tempBan.isBanned(name) then
        banned[name] = true
        count = count + 1
        addon.ui.updateLfgResults()

        if addon.ui.options.isOpen() then
            addon.ui.options.updateState()
        end
    end
end

function tempBan.clear()
    banned = {}
    count = 0
end
