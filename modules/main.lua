local _, addon = ...
local main, private = addon.module('main')

function main.init()
    hooksecurefunc('LFGListUtil_SortSearchResults', private.filter)
    hooksecurefunc(C_ReportSystem, 'SendReport', private.onReport)
end

function main.banPlayer(name)
    addon.config.banPlayer(private.normalizePlayerName(name))
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

function private.onReport(reportInfo, reportPlayerLocation)
    if
        reportInfo.reportType == Enum.ReportType.GroupFinderPosting
        and reportInfo.groupFinderSearchResultID
        and reportInfo.minorCategoryFlags
        and bit.band(reportInfo.minorCategoryFlags, Enum.ReportMinorCategory.Advertisement) ~= 0
        and ReportFrame.playerName
    then
        main.banPlayer(ReportFrame.playerName)
        addon.ui.updateLfgResults()
    end
end
