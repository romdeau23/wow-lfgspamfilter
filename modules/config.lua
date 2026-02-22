---@class Addon
local addon = select(2, ...)
local config, private = addon.module(), {}
addon.config = config

---@type ConfigModule.Config
local DEFAULT_CONFIG = {
    banButton = true,
    ignoredCategories = {},
    bannedPlayers = {},
    numberOfBannedPlayers = 0,
    filterBanned = true,
    lastBan = nil,
    maxAge = 4 * 3600,
    lastMaintenance = time(),
    buttonTipShown = false,
    openReportWindow = true,
    filterMode = addon.const.filterModes.Default,
    noCarry = true,
}

---@class (exact) ConfigModule.Config
---@field banButton boolean
---@field ignoredCategories table<number, true>
---@field bannedPlayers table<string, integer>
---@field numberOfBannedPlayers integer
---@field filterBanned boolean
---@field lastBan string?
---@field maxAge integer
---@field lastMaintenance integer
---@field buttonTipShown boolean
---@field openReportWindow boolean
---@field filterMode FilterMode
---@field noCarry boolean

function config.init()
    ---@type ConfigModule.Config
    config.db = addon.loadSavedVar(
        'LFGSpamFilterAddonConfig',
        12,
        DEFAULT_CONFIG,
        private.migrations
    )

    private.maintenance()
end

---@param category string
---@return boolean
function config.isIgnoredCategory(category)
    return config.db.ignoredCategories[category] ~= nil
end

---@param category string
---@param isIgnored boolean
function config.setIgnoredCategory(category, isIgnored)
    if isIgnored then
        config.db.ignoredCategories[category] = true
    else
        config.db.ignoredCategories[category] = nil
    end
end

---@param name string
function config.banPlayer(name)
    if not config.isBannedPlayer(name) then
        config.db.bannedPlayers[name] = time()
        config.db.numberOfBannedPlayers = config.db.numberOfBannedPlayers + 1
        config.db.lastBan = name
    end
end

---@param name string
function config.unbanPlayer(name)
    if config.isBannedPlayer(name) then
        config.db.bannedPlayers[name] = nil
        config.db.numberOfBannedPlayers = config.db.numberOfBannedPlayers - 1
    end
end

function config.unbanAllPlayers()
    table.wipe(config.db.bannedPlayers)
    config.db.numberOfBannedPlayers = 0
end

---@param name string
---@return boolean
function config.isBannedPlayer(name)
    if config.db.bannedPlayers[name] then
        -- update last seen time
        config.db.bannedPlayers[name] = time()

        return true
    end

    return false
end

function private.maintenance()
    -- run maintenance once a week
    if time() - config.db.lastMaintenance > 604800 then
        private.cleanupBannedPlayers(31536000) -- remove banned players not seen for over a year
        config.db.lastMaintenance = time()
    end
end

---@param threshold integer
function private.cleanupBannedPlayers(threshold)
    local now = time()
    local newCount = 0

    for name, lastSeen in pairs(config.db.bannedPlayers) do
        if now - lastSeen >= threshold then
            config.db.bannedPlayers[name] = nil
        else
            newCount = newCount + 1
        end
    end

    config.db.numberOfBannedPlayers = newCount
end


private.migrations = {
    [2] = function (data)
        data.blacklistEnabled = true
    end,

    [3] = function (data)
        data.button = true

        if data.blacklistEnabled ~= false then
            data.blacklistEnabled = true
        end
    end,

    [4] = function (data)
        data.splash = true
    end,

    [5] = function (data)
        data.enabled = nil
        data.splash = nil
        data.quickReport = data.button
        data.button = nil
        data.ignoredCategories = {}
        data.buttonTipShown = false

        if data.maxAge == 0 then
            data.maxAge = nil
        end

        if data.lastBan then
            data.lastBan = data.lastBan.player
        end

        data.bannedPlayers = {}
        data.numberOfBannedPlayers = 0
        data.filterBanned = data.blacklistEnabled

        for normalizedName, lastSeen in pairs(data.blacklist) do
            local name, realm = strsplit('-', normalizedName, 2)
            realm = realm:gsub('[%- ]', '')
            normalizedName = name .. '-' .. realm

            if not data.bannedPlayers[normalizedName] then
                data.bannedPlayers[normalizedName] = lastSeen
                data.numberOfBannedPlayers = data.numberOfBannedPlayers + 1
            end
        end

        data.blacklist = nil
        data.blacklistEnabled = nil
    end,

    [6] = function (data)
        data.stats = nil
        data.filterApplications = true
    end,

    [7] = function (data)
        data.banButton = data.quickReport
        data.quickReport = nil
        data.report = nil
        data.noVoice = false
    end,

    [8] = function (data)
        data.reportHelper = true
        data.reportHelperTipShown = false
    end,

    [9] = function (data)
        data.filterApplications = nil
        data.lastMaintenance = 0
        data.buttonTipShown = false
    end,

    [10] = function (data)
        data.openReportWindow = data.reportHelper
        data.reportHelper = nil
        data.reportHelperTipShown = nil
    end,

    [11] = function (data)
        data.filterMode = addon.const.filterModes.Default
        data.noVoice = nil
    end,

    [12] = function (data)
        data.noCarry = true
    end,
}
