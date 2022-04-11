local _, addon = ...
local main, private = addon.module('main')
local reportingGroup = false

function main.init()
    hooksecurefunc('LFGListUtil_SortSearchResults', private.filter)
    hooksecurefunc(C_LFGList, 'ReportSearchResult', private.onReport)
end

function main.quickReport(resultId)
    private.banGroupLeader(resultId)
    private.reportGroup(resultId)
end

function private.filter(results)
    -- do nothing if LFG search is not open
    if not addon.ui.isLfgSearchOpen() then
        return
    end

    -- fix GetPlaystyleString() before tainting the result table
    addon.interop.fixGetPlaystyleString()

    -- filter applications to remove duplicate results (UI bug)
    if addon.config.db.filterApplications then
        local applicationMap = {}

        for _, resultId in ipairs(LFGListFrame.SearchPanel.applications) do
            applicationMap[resultId] = true
        end

        private.filterTable(results, function (resultId)
            return applicationMap[resultId] == nil
        end)
    end

    -- check ignored categories
    if addon.config.isIgnoredCategory(addon.ui.getCurrentLfgCategory()) then
        addon.ui.statusButton.update(false, 0)
        return
    end

    -- filter results
    local newCount, filteredCount = private.filterTable(results, function (resultId)
        local info = C_LFGList.GetSearchResultInfo(resultId)

        return info and private.accept(info)
    end)

    -- handle results
    LFGListFrame.SearchPanel.totalResults = newCount
    addon.ui.statusButton.update(true, filteredCount)
end

function private.filterTable(input, callback)
    local output = {}
    local inputCount = #input
    local outputCount = 0

    for i = 1, inputCount do
        local item = input[i]

        if callback(item) then
            outputCount = outputCount + 1
            output[outputCount] = item
        end
    end

    local filteredCount = inputCount - outputCount

    if filteredCount > 0 then
        table.wipe(input)

        for i = 1, outputCount do
            input[i] = output[i]
        end
    end

    return outputCount, filteredCount
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

    -- also ban the group if this is a report from the drop-down menu (not using the quick report)
    if not reportingGroup then
        private.banGroupLeader(resultId)
    end
end
