local _, addon = ...
local ui, private = addon.module('ui')

function ui.init()
    hooksecurefunc('LFGListFrame_SetActivePanel', ui.hidePopups)
    LFGListFrame:HookScript('OnHide', ui.hidePopups)
end

function ui.message(text, ...)
    message(string.format('|cffffffff' .. text, ...), true)
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

function ui.updateLfgResults()
    if not ui.isLfgSearchOpen() then
        return
    end

    LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel)
end

function ui.hidePopups()
    LFGSpamFilterOptions:Hide()
    LFGSpamFilterQuickReportButton:Hide()
end
