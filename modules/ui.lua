local _, addon = ...
local ui, private = addon.module('ui')

function ui.init()
    hooksecurefunc('LFGListFrame_SetActivePanel', private.resetUiState)
    LFGListFrame:HookScript('OnHide', private.resetUiState)
end

function ui.message(text, ...)
    message(string.format(WHITE_FONT_COLOR_CODE .. text, ...), true)
end

function ui.errorMessage(text, ...)
    message(string.format(text, ...), true)
end

function ui.isLfgSearchOpen()
    return LFGListFrame.SearchPanel:IsShown()
end

function ui.getCurrentLfgCategory()
    local suffix = ''

    if bit.band(LFGListFrame.baseFilters, Enum.LFGListFilter.PvE) ~= 0 then
        suffix = '-pve'
    elseif bit.band(LFGListFrame.baseFilters, Enum.LFGListFilter.PvP) ~= 0 then
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
    addon.ui.options.toggle(false)
    addon.ui.banButton.hide()
    addon.ui.reportHelper.stop()
end

function private.resetUiState()
    ui.hidePopups()
    addon.main.setInvertFilter(false)
end
