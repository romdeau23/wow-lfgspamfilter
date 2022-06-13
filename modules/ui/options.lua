local _, addon = ...
local options, private = addon.module('ui', 'options')

function options.load()
    -- banned players heading
    LFGSpamFilterOptions.BannedPlayersHeading:SetText(string.format(
        'Banned players (%d)',
        addon.config.db.numberOfBannedPlayers
    ))

    -- filter category
    LFGSpamFilterOptions.FilterCategory:SetChecked(
        not addon.config.isIgnoredCategory(addon.ui.getCurrentLfgCategory())
    )

    -- no voice
    LFGSpamFilterOptions.NoVoice:SetChecked(addon.config.db.noVoice)

    -- max age
    if addon.config.db.maxAge then
        LFGSpamFilterOptions.MaxAge:SetText(tostring(addon.config.db.maxAge / 3600))
    else
        LFGSpamFilterOptions.MaxAge:SetText('')
    end

    -- ban button
    LFGSpamFilterOptions.BanButton:SetChecked(addon.config.db.banButton)

    -- report helper
    LFGSpamFilterOptions.ReportHelper:SetChecked(addon.config.db.reportHelper)
    LFGSpamFilterOptions.ReportHelper:SetEnabled(addon.config.db.banButton)

    -- filter applications
    LFGSpamFilterOptions.FilterApplications:SetChecked(addon.config.db.filterApplications)

    -- filter banned
    LFGSpamFilterOptions.FilterBanned:SetChecked(addon.config.db.filterBanned)
end

function options.apply()
    -- filter category
    local filterCategory = LFGSpamFilterOptions.FilterCategory:GetChecked()
    addon.config.setIgnoredCategory(addon.ui.getCurrentLfgCategory(), not filterCategory)

    -- no voice
    addon.config.db.noVoice = LFGSpamFilterOptions.NoVoice:GetChecked()

    -- max age
    local maxAgeInput = tonumber(LFGSpamFilterOptions.MaxAge:GetText())

    if maxAgeInput and maxAgeInput >= 0 then
        addon.config.db.maxAge = maxAgeInput * 3600
    else
        addon.config.db.maxAge = nil
    end

    -- ban button
    addon.config.db.banButton = LFGSpamFilterOptions.BanButton:GetChecked()

    -- report helper
    addon.config.db.reportHelper = LFGSpamFilterOptions.ReportHelper:GetChecked()

    -- filter applications
    addon.config.db.filterApplications = LFGSpamFilterOptions.FilterApplications:GetChecked()

    -- filter banned
    addon.config.db.filterBanned = LFGSpamFilterOptions.FilterBanned:GetChecked()

    -- update results with new options
    addon.ui.updateLfgResults()
end

function options.onUnbanAllClick()
    local num = addon.config.db.numberOfBannedPlayers

    if num > 0 then
        addon.config.unbanAllPlayers()
        addon.ui.message('Unbanned %d players\n\n(recently reported groups will not be visible)', num)
    else
        addon.ui.message('There\'s noone to unban')
        return false
    end
end

function options.onUnbanLastClick()
    local name = addon.config.db.lastBan

    if name and addon.config.isBannedPlayer(name) then
        addon.config.unbanPlayer(name)
        addon.ui.message('Unbanned %s\n\n(recently reported group will not be visible)', name)
    else
        addon.ui.message('There\'s noone to unban')
        return false
    end
end
