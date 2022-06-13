local _, addon = ...
local config, private = addon.module('config')
local latestVersion = 8

function config.init()
    if LFGSpamFilterAddonConfig then
        -- load and migrate existing config
        config.db = LFGSpamFilterAddonConfig

        if not pcall(private.migrateConfiguration) then
            config.db = private.getDefaultConfig() -- reset on error
        end
    else
        -- set default config
        LFGSpamFilterAddonConfig = private.getDefaultConfig()
        config.db = LFGSpamFilterAddonConfig
    end

    private.maintenance()
end

function config.isIgnoredCategory(category)
    return config.db.ignoredCategories[category] ~= nil
end

function config.setIgnoredCategory(category, isIgnored)
    if isIgnored then
        config.db.ignoredCategories[category] = true
    else
        config.db.ignoredCategories[category] = nil
    end
end

function config.banPlayer(name)
    if not config.isBannedPlayer(name) then
        config.db.bannedPlayers[name] = time()
        config.db.numberOfBannedPlayers = config.db.numberOfBannedPlayers + 1
        config.db.lastBan = name
    end
end

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

function config.isBannedPlayer(name)
    if config.db.bannedPlayers[name] then
        -- update last seen time
        config.db.bannedPlayers[name] = time()

        return true
    end

    return false
end

function private.getDefaultConfig()
    return {
        version = latestVersion,
        banButton = true,
        ignoredCategories = {},
        bannedPlayers = {},
        numberOfBannedPlayers = 0,
        filterBanned = true,
        filterApplications = true,
        lastBan = nil,
        noVoice = false,
        maxAge = 4 * 3600,
        lastMaintenance = time(),
        buttonTipShown = false,
        reportHelper = true,
        reportHelperTipShown = false,
    }
end

function private.migrateConfiguration()
    for to = config.db.version + 1, latestVersion do
        private.migrations[to]()
    end

    config.db.version = latestVersion
end

private.migrations = {
    [2] = function ()
        config.db.blacklistEnabled = true
    end,

    [3] = function ()
        config.db.button = true

        if config.db.blacklistEnabled ~= false then
            config.db.blacklistEnabled = true
        end
    end,

    [4] = function ()
        config.db.splash = true
    end,

    [5] = function ()
        config.db.enabled = nil
        config.db.splash = nil
        config.db.quickReport = config.db.button
        config.db.button = nil
        config.db.ignoredCategories = {}
        config.db.buttonTipShown = false

        if config.db.maxAge == 0 then
            config.db.maxAge = nil
        end

        if config.db.lastBan then
            config.db.lastBan = config.db.lastBan.player
        end

        config.db.bannedPlayers = {}
        config.db.numberOfBannedPlayers = 0
        config.db.filterBanned = config.db.blacklistEnabled

        for normalizedName, lastSeen in pairs(config.db.blacklist) do
            local name, realm = strsplit('-', normalizedName, 2)
            realm = realm:gsub('[%- ]', '')
            normalizedName = name .. '-' .. realm

            if config.db.bannedPlayers[normalizedName] == nil then
                config.db.bannedPlayers[normalizedName] = lastSeen
                config.db.numberOfBannedPlayers = config.db.numberOfBannedPlayers + 1
            end
        end

        config.db.blacklist = nil
        config.db.blacklistEnabled = nil
    end,

    [6] = function ()
        config.db.stats = nil
        config.db.filterApplications = true
    end,

    [7] = function ()
        config.db.banButton = config.db.quickReport
        config.db.quickReport = nil
        config.db.report = nil
        config.db.noVoice = false
    end,

    [8] = function ()
        config.db.reportHelper = true
        config.db.reportHelperTipShown = false
    end,
}

function private.maintenance()
    -- run maintenance once a week
    if time() - config.db.lastMaintenance > 604800 then
        private.cleanupBannedPlayers(31536000) -- remove banned players not seen for over a year
        config.db.lastMaintenance = time()
    end
end

function private.cleanupBannedPlayers(threshold)
    local now = time()

    for name, lastSeen in pairs(config.db.bannedPlayers) do
        if now - lastSeen >= threshold then
            config.db.bannedPlayers[name] = nil
        end
    end
end
