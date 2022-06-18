local _, addon = ...
local banButton, private = addon.module('ui', 'banButton')
local hookedEntries = {}

function banButton.init()
    hooksecurefunc('LFGListSearchEntry_Update', private.onLfgSearchEntryUpdate)
    hooksecurefunc('LFGListSearchPanel_UpdateResults', private.onLfgSearchResultsUpdate)
end

function banButton.onClick()
    local resultId = LFGSpamFilterBanButton.resultId

    if resultId then
        local info = C_LFGList.GetSearchResultInfo(resultId)

        if info and info.leaderName then
            if addon.config.db.reportHelper and not InCombatLockdown() then
                LFGList_ReportListing(resultId, info.leaderName)
                addon.ui.reportHelper.begin()
            else
                addon.main.banPlayer(info.leaderName)
                addon.ui.updateLfgResults()
            end
        end
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function private.onLfgSearchEntryUpdate(entry)
    if hookedEntries[entry:GetName()] == nil then
        entry:HookScript('OnEnter', private.onLfgSearchEntryEnter)
        entry:HookScript('OnLeave', private.onLfgSearchEntryLeave)
        hookedEntries[entry:GetName()] = true
    end
end

function private.onLfgSearchEntryEnter(entry)
    if addon.config.db.banButton and not addon.ui.reportHelper.isActive() then
        LFGSpamFilterBanButton.resultId = entry.resultID
        LFGSpamFilterBanButton:ClearAllPoints()
        LFGSpamFilterBanButton:SetPoint('LEFT', entry, 'LEFT', -25, 0)
        LFGSpamFilterBanButton:Show()
    end
end

function private.onLfgSearchEntryLeave()
    if addon.config.db.banButton and not MouseIsOver(LFGSpamFilterBanButton) then
        LFGSpamFilterBanButton:Hide()
    end
end

function private.onLfgSearchResultsUpdate()
    -- hide the ban button when results are updated (as the groups might change order etc.)
    LFGSpamFilterBanButton:Hide()
end
