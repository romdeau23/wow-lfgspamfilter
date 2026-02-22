---@class Addon
local addon = select(2, ...)
local tempBan = addon.module()
addon.tempBan = tempBan

---@type table<string, true>
local banned = {}
local count = 0

---@param name string
---@return boolean
function tempBan.isBanned(name)
    return banned[name] ~= nil
end

---@return integer
function tempBan.getCount()
    return count
end

---@param name string
function tempBan.ban(name)
    if not tempBan.isBanned(name) then
        banned[name] = true
        count = count + 1
    end
end

function tempBan.clear()
    banned = {}
    count = 0
end
