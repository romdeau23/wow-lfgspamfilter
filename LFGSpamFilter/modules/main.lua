local _, addon = ...
local main, private = addon.module('main')
local reportingGroup = false

function main.init()
    private.initHooks()
    private.registerSlashCommands()
end

function main.quickReport(resultId)
    private.banGroupLeader(resultId)
    private.reportGroup(resultId)
end

function private.initHooks()
    hooksecurefunc('LFGListUtil_SortSearchResults', private.filter)
    hooksecurefunc(C_LFGList, 'ReportSearchResult', private.onReport)
end

-- TODO: remove in a future version
function private.registerSlashCommands()
    SLASH_LFG_SPAM_FILTER1 = '/lfgspamfilter'
    SLASH_LFG_SPAM_FILTER2 = '/lfgsf'
    SLASH_LFG_SPAM_FILTER3 = '/lsf'

    SlashCmdList.LFG_SPAM_FILTER = function ()
        addon.ui.message('LFGSpamFilter no longer uses slash commands. Use the new status button above the LFG filter instead.')
    end
end

function private.filter(results)
    -- do nothing if LFG search is not open
    if not addon.ui.isLfgSearchOpen() then
        return
    end

    -- check ignored categories
    if addon.config.isIgnoredCategory(addon.ui.getCurrentLfgCategory()) then
        addon.ui.updateStatusButton(false, 0)
        return
    end

    local accepted = {}
    local numAccepted = 0
    local numResults = #results

    -- filter results into another table
    for i = 1, numResults do
        local resultId = results[i]
        local info = C_LFGList.GetSearchResultInfo(resultId)

        if info then
            if private.accept(info) then
                numAccepted = numAccepted + 1
                accepted[numAccepted] = resultId
            end
        end
    end

    -- handle results
    local numFiltered = numResults - numAccepted

    if numFiltered > 0 then
        table.wipe(results)

        for i = 1, numAccepted do
            results[i] = accepted[i]
        end

        addon.config.addToStats('filtered', numFiltered)
    end

    addon.ui.updateStatusButton(true, numFiltered)
end

function private.accept(info)
    return (
            addon.config.db.maxAge == nil
            or info.age <= addon.config.db.maxAge
        )
        and (
            not addon.config.db.filterBanned
            or info.leaderName == nil
            or not addon.config.isBannedPlayer(private.normalizePlayerName(info.leaderName))
        )
        and (
            info.voiceChat == ''
            or not addon.config.db.noVoice
        )
end

function private.normalizePlayerName(name)
    local dashPos = string.find(name, '-', 1, true)

    if dashPos == nil then
        name = name .. '-' .. GetNormalizedRealmName()
    end

    return name
end

function private.banGroupLeader(resultId)
    local info = C_LFGList.GetSearchResultInfo(resultId)

    if info and info.leaderName then
        addon.config.banPlayer(private.normalizePlayerName(info.leaderName))
    end
end

function private.reportGroup(resultId)
    if addon.config.db.report then
        reportingGroup = true
        pcall(C_LFGList.ReportSearchResult, resultId, 'lfglistspam')
        reportingGroup = false
    end
end


function private.onReport(resultId, reason)
    -- ignore reports for other reasons
    if reason ~= 'lfglistspam' then
        return
    end

    -- count the report
    addon.config.addToStats('reports', 1)

    -- also ban the group if this is a report from the drop-down menu (not using the quick report)
    if not reportingGroup then
        private.banGroupLeader(resultId)
    end
end
