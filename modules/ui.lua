---@class Addon
local addon = select(2, ...)
local ui, private = addon.module(), {}
addon.ui = ui

function ui.init()
    hooksecurefunc('LFGListFrame_SetActivePanel', private.resetUiState)
    LFGListFrame:HookScript('OnHide', private.resetUiState)
end

---@param text string
---@param ... any
function ui.message(text, ...)
    SetBasicMessageDialogText(string.format(WHITE_FONT_COLOR_CODE .. text, ...), true)
end

---@param text string
---@param ... any
function ui.errorMessage(text, ...)
    SetBasicMessageDialogText(string.format(text, ...), true)
end

---@return boolean
function ui.isLfgSearchOpen()
    return LFGListFrame.SearchPanel:IsShown()
end

---@return string
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
end

function private.resetUiState()
    ui.hidePopups()
    addon.main.setInvertFilter(false)
end
