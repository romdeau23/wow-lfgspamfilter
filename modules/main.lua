---@class Addon
local addon = select(2, ...)
local main, private = addon.module(), {}
addon.main = main

local config = addon.config
local ui = addon.ui
local tempBan = addon.tempBan
local filterModes = addon.const.filterModes
local invertFilter = false

function main.init()
    hooksecurefunc('LFGListUtil_SortSearchResults', private.filter)
    hooksecurefunc(C_ReportSystem, 'SendReport', private.onReport)
end

---@param name string
---@param temporary boolean
function main.banPlayer(name, temporary)
    name = private.normalizePlayerName(name)

    if temporary then
        tempBan.ban(name)
    else
        config.banPlayer(name)
    end

    ui.updateLfgResults()

    if ui.options.isOpen() then
        ui.options.updateState()
    end
end

---@param enabled boolean
function main.setInvertFilter(enabled)
    invertFilter = enabled
end

---@return boolean
function main.isFilterInverted()
    return invertFilter
end

---@param frame table
function private.filter(frame)
    -- do nothing if LFG search is not open
    if not ui.isLfgSearchOpen() then
        return
    end

    -- check ignored categories
    if config.isIgnoredCategory(ui.getCurrentLfgCategory()) then
        ui.statusButton.updateInactive()
        return
    end

    -- filter results
    local numAccepted, numRejected = private.filterTable(frame.results, function (resultId)
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
    LFGListFrame.SearchPanel.totalResults = numAccepted
    ui.statusButton.updateActive(numAccepted, numRejected, invertFilter)

    -- hide start group button so it doesn't overlap the entries (blizz bug)
    if numAccepted > 0 then
        LFGListFrame.SearchPanel.ScrollBox.StartGroupButton:SetShown(false)
    end
end

---@generic T
---@param tbl T[]
---@param callback fun(T):boolean
---@return integer numAccepted
---@return integer numRejected
function private.filterTable(tbl, callback)
    local output = {}
    local tblCount = #tbl
    local numAccepted = 0

    for i = 1, tblCount do
        local item = tbl[i]

        if callback(item) then
            numAccepted = numAccepted + 1
            output[numAccepted] = item
        end
    end

    local numRejected = tblCount - numAccepted

    if numRejected > 0 then
        table.wipe(tbl)

        for i = 1, numAccepted do
            tbl[i] = output[i]
        end
    end

    return numAccepted, numRejected
end

---@param info LfgSearchResultData
---@return boolean
function private.accept(info)
    if config.db.maxAge and info.age > config.db.maxAge then
        return false -- max age exceeded
    end

    if config.db.filterMode == filterModes.Default then
        if (info.leaderOverallDungeonScore or 0) == 0 and info.voiceChat ~= '' then
            return false -- no score + filled out voice chat
        end
    elseif config.db.filterMode == filterModes.RequireNoVoice then
        if info.voiceChat ~= '' then
            return false -- voice chat filled
        end
    elseif  config.db.filterMode == filterModes.RequireScore then
        if (info.leaderOverallDungeonScore or 0) == 0 then
            return false -- no score
        end
    end

    if info.leaderName then
        local leaderName = private.normalizePlayerName(info.leaderName)

        if config.db.filterBanned and config.isBannedPlayer(leaderName) then
            return false -- banned player
        end

        if tempBan.isBanned(leaderName) then
            return false -- temp banned player
        end
    end

    if config.db.noCarry and info.generalPlaystyle == Enum.LFGEntryGeneralPlaystyle.Expert then
        return false -- "carry offered"
    end

    -- all ok
    return true
end

---@param name string
---@return string
function private.normalizePlayerName(name)
    local dashPos = string.find(name, '-', 1, true)

    if not dashPos then
        name = name .. '-' .. GetNormalizedRealmName()
    end

    return name
end

---@param reportInfo table see ReportInfoMixin
---@param reportPlayerLocation unknown unused
function private.onReport(reportInfo, reportPlayerLocation)
    if
        reportInfo.reportType == Enum.ReportType.GroupFinderPosting
        and reportInfo.groupFinderSearchResultID
        and reportInfo.minorCategoryFlags
        and bit.band(reportInfo.minorCategoryFlags, Enum.ReportMinorCategory.Advertisement) ~= 0
        and ReportFrame.playerName
    then
        main.banPlayer(ReportFrame.playerName, false)
    end
end
