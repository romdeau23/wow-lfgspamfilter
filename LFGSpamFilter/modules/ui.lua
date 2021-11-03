local _, addon = ...
local ui, private = addon.module('ui')

function ui.init()
    private.initHooks()
    private.initStatusButton()
    private.initOptions()
end

function ui.message(text, ...)
    message(string.format('|cffffffff' .. text, ...), true)
end

function ui.updateStatusButton(active, numFiltered)
    private.maybeShowButtonTip()

    local usageHint = DISABLED_FONT_COLOR_CODE .. '(click for options, right-click to toggle)|r';

    if active then
        LFGSpamFilterStatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking0')

        if numFiltered > 0 then
            LFGSpamFilterStatusButton.Text:Show()
            LFGSpamFilterStatusButton.TextFrame:Show()
            LFGSpamFilterStatusButton.Text:SetText(tostring(math.min(99, numFiltered)))
            LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 0, 0)
            LFGSpamFilterStatusButton.Icon:SetDesaturated(nil)
            LFGSpamFilterStatusButton.tooltip = string.format(
                'LFGSpamFilter has filtered %d groups\n%s',
                numFiltered,
                usageHint
            )
        else
            LFGSpamFilterStatusButton.Text:Hide()
            LFGSpamFilterStatusButton.TextFrame:Hide()
            LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 1, 1)
            LFGSpamFilterStatusButton.Icon:SetDesaturated(1)
            LFGSpamFilterStatusButton.tooltip = string.format(
                'LFGSpamFilter has not filtered any groups\n%s',
                usageHint
            )
        end
    else
        LFGSpamFilterStatusButton.Text:Hide()
        LFGSpamFilterStatusButton.TextFrame:Hide()
        LFGSpamFilterStatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking4')
        LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 1, 1)
        LFGSpamFilterStatusButton.tooltip = string.format(
            'LFGSpamFilter is disabled for this category\n%s',
            usageHint
        )
    end
end

function ui.onStatusButtonClick(button)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

    if button == 'LeftButton' then
        if LFGSpamFilterOptions:IsVisible() then
            LFGSpamFilterOptions:Hide()
        else
            LFGSpamFilterOptions:Show()
        end
    else
        local category = ui.getCurrentLfgCategory()
        addon.config.setIgnoredCategory(category, not addon.config.isIgnoredCategory(category))
        private.hidePopups()
        private.updateLfgSearchResults()
    end
end

function ui.onQuickReportButtonClick()
    local resultId = LFGSpamFilterQuickReportButton._LFGSpamFilterResultId

    if resultId then
        addon.main.quickReport(resultId)
        private.updateLfgSearchResults()
    end
end

function ui.updateOptionsUi()
    LFGSpamFilterOptions.updating = true

    addon.tryFinally(
        private.doUpdateOptionsUi,
        function() LFGSpamFilterOptions.updating = false end
    )
end

function ui.onOptionNotify(key)
    local frame = LFGSpamFilterOptions[key]
    local handler = private.optionNotificationHandlers[key]

    assert(frame)
    assert(handler)

    if handler(frame) ~= false then
        ui.updateOptionsUi()
        private.updateLfgSearchResults()
    end
end

function ui.isLfgSearchOpen()
    return LFGListFrame.SearchPanel:IsShown()
end

function ui.getCurrentLfgCategory()
    local suffix = ''

    if bit.band(LFGListFrame.baseFilters, LE_LFG_LIST_FILTER_PVE) ~= 0 then
        suffix = '-pve'
    elseif bit.band(LFGListFrame.baseFilters, LE_LFG_LIST_FILTER_PVP) ~= 0 then
        suffix = '-pvp'
    end

    return LFG_LIST_CATEGORY_TEXTURES[LFGListFrame.SearchPanel.categoryID] .. suffix
end

function private.initHooks()
    hooksecurefunc('LFGListSearchEntry_Update', private.hookLfgSearchEntry)
    hooksecurefunc('LFGListSearchPanel_UpdateResults', private.onLfgSearchResultsUpdate)
    hooksecurefunc('LFGListFrame_SetActivePanel', private.hidePopups)
    LFGListFrame:HookScript('OnHide', private.hidePopups)
end

function private.initStatusButton()
    local statusButtonLeftOffset

    if select(4, GetAddOnInfo('PremadeGroupsFilter')) then
        statusButtonLeftOffset = -70
    else
        statusButtonLeftOffset = -5
    end

    LFGSpamFilterStatusButton.tooltip = ''
    LFGSpamFilterStatusButton:SetParent(LFGListFrame.SearchPanel)
    LFGSpamFilterStatusButton:SetPoint('RIGHT', LFGListFrame.SearchPanel.RefreshButton, 'LEFT', statusButtonLeftOffset, 0)
    LFGSpamFilterStatusButton:Show()
end

function private.initOptions()
    LFGSpamFilterOptions:SetParent(UIFrame)
end

function private.maybeShowButtonTip()
    if not addon.config.db.buttonTipShown and LFGSpamFilterStatusButton:IsVisible() then
        addon.config.db.buttonTipShown = true
        HelpTip:Show(
            LFGSpamFilterStatusButton,
            {
                text = 'This is the LFGSpamFilter status button.'
                    .. '\n\nClick on it for options.\nRight-click to toggle filtering.',
                checkCVars = false,
                systemPriority = 999,
                buttonStyle = HelpTip.ButtonStyle.Close,
            }
        )
    end
end

function private.hidePopups()
    LFGSpamFilterOptions:Hide()
    LFGSpamFilterQuickReportButton:Hide()
end

function private.doUpdateOptionsUi()
    -- BannedPlayersHeading
    LFGSpamFilterOptions.BannedPlayersHeading:SetText(string.format(
        'Banned players (%d)',
        addon.config.db.numberOfBannedPlayers
    ))

    -- FilterCategory
    LFGSpamFilterOptions.FilterCategory:SetChecked(
        not addon.config.isIgnoredCategory(ui.getCurrentLfgCategory())
    )

    -- NoVoice
    LFGSpamFilterOptions.NoVoice:SetChecked(addon.config.db.noVoice)

    -- MaxAge
    if addon.config.db.maxAge ~= nil then
        LFGSpamFilterOptions.MaxAge:SetText(tostring(addon.config.db.maxAge / 3600))
    else
        LFGSpamFilterOptions.MaxAge:SetText('')
    end

    -- Report
    LFGSpamFilterOptions.Report:SetChecked(addon.config.db.report)

    -- QuickReport
    LFGSpamFilterOptions.QuickReport:SetChecked(addon.config.db.quickReport)

    -- FilterBanned
    LFGSpamFilterOptions.FilterBanned:SetChecked(addon.config.db.filterBanned)
end

private.optionNotificationHandlers = {
    FilterCategory = function (frame)
        addon.config.setIgnoredCategory(ui.getCurrentLfgCategory(), not frame:GetChecked())
    end,

    NoVoice = function (frame)
        addon.config.db.noVoice = frame:GetChecked()
    end,

    MaxAge = function (frame)
        local input = tonumber(frame:GetText())

        if input ~= nil and input >= 0 then
            addon.config.db.maxAge = input * 3600
        else
            addon.config.db.maxAge = nil
        end
    end,

    Report = function (frame)
        addon.config.db.report = frame:GetChecked()
    end,

    QuickReport = function (frame)
        addon.config.db.quickReport = frame:GetChecked()
    end,

    FilterBanned = function (frame)
        addon.config.db.filterBanned = frame:GetChecked()
    end,

    UnbanAll = function ()
        local num = addon.config.db.numberOfBannedPlayers

        if num > 0 then
            addon.config.unbanAllPlayers()
            ui.message('Unbanned %d players\n\n(recently reported groups will not be visible)', num)
        else
            ui.message('There\'s noone to unban')
            return false
        end
    end,

    UnbanLast = function ()
        local name = addon.config.db.lastBan

        if name and addon.config.isBannedPlayer(name) then
            addon.config.unbanPlayer(name)
            ui.message('Unbanned %s\n\n(recently reported group will not be visible)', name)
        else
            ui.message('There\'s noone to unban')
            return false
        end
    end,
}

function private.updateLfgSearchResults()
    if not ui.isLfgSearchOpen() then
        return
    end

    LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel)
end

function private.hookLfgSearchEntry(entry)
    if not entry._LFGSpamFilterHooked then
        entry:HookScript('OnEnter', private.onLfgSearchEntryEnter)
        entry:HookScript('OnLeave', private.onLfgSearchEntryLeave)
        entry._LFGSpamFilterHooked = true
    end
end

function private.onLfgSearchEntryEnter(entry)
    if addon.config.db.quickReport then
        LFGSpamFilterQuickReportButton._LFGSpamFilterResultId = entry.resultID
        LFGSpamFilterQuickReportButton:ClearAllPoints()
        LFGSpamFilterQuickReportButton:SetPoint('LEFT', entry, 'LEFT', -25, 0)
        LFGSpamFilterQuickReportButton:Show()
    end
end

function private.onLfgSearchEntryLeave()
    if addon.config.db.quickReport and not MouseIsOver(LFGSpamFilterQuickReportButton) then
        LFGSpamFilterQuickReportButton:Hide()
    end
end

function private.onLfgSearchResultsUpdate()
    -- hide the quick report button when results are updated (as the groups might change order etc.)
    LFGSpamFilterQuickReportButton:Hide()
end
