local _, addon = ...
local main, private = addon.module('main')
local invertFilter = false

function main.init()
    hooksecurefunc('LFGListUtil_SortSearchResults', private.filter)
    hooksecurefunc(C_ReportSystem, 'SendReport', private.onReport)
end

function main.banPlayer(name)
    addon.config.banPlayer(private.normalizePlayerName(name))
    addon.ui.updateLfgResults()

    if addon.ui.options.isOpen() then
        addon.ui.options.updateState()
    end
end

function main.setInvertFilter(enabled)
    invertFilter = enabled
end

function main.isFilterInverted()
    return invertFilter
end

function private.filter(results)
    -- do nothing if LFG search is not open
    if not addon.ui.isLfgSearchOpen() then
        return
    end

    -- fix GetPlaystyleString() before tainting the result table
    addon.interop.fixGetPlaystyleString()

    -- check ignored categories
    if addon.config.isIgnoredCategory(addon.ui.getCurrentLfgCategory()) then
        addon.ui.statusButton.updateInactive()
        return
    end

    -- filter results
    local acceptedCount, rejectedCount = private.filterTable(results, function (resultId)
        local info = C_LFGList.GetSearchResultInfo(resultId)

        if info then
            local accepted = private.accept(info)

            if invertFilter then
                accepted = not accepted
            end

            return accepted
        end

        return false
    end)

    -- handle results
    LFGListFrame.SearchPanel.totalResults = acceptedCount
    addon.ui.statusButton.updateActive(acceptedCount, rejectedCount, invertFilter)

    -- hide start group button so it doesn't overlap the entries (blizz bug)
    if acceptedCount > 0 then
        LFGListFrame.SearchPanel.ScrollBox.StartGroupButton:SetShown(false)
    end
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
    end
end
