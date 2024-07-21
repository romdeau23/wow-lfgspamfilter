local _, addon = ...
local banButton, private = addon.module('ui', 'banButton')
local hookedEntries = {}

function banButton.init()
    hooksecurefunc('LFGListSearchEntry_Update', private.onLfgSearchEntryUpdate)
    hooksecurefunc('LFGListSearchPanel_UpdateResults', private.onLfgSearchResultsUpdate)
end

function banButton.hide()
    LFGSpamFilter_BanButton:Hide()
end

function banButton.onClick(button)
    local resultId = LFGSpamFilter_BanButton.resultId

    if resultId then
        local info = C_LFGList.GetSearchResultInfo(resultId)

        if info and info.leaderName then
            if button == 'LeftButton' then
                -- report/ban
                if addon.config.db.openReportWindow and not InCombatLockdown() then
                    LFGList_ReportListing(resultId, info.leaderName)
                else
                    addon.main.banPlayer(info.leaderName, false)
                end
            elseif button == 'RightButton' then
                -- temporary ban
                addon.main.banPlayer(info.leaderName, true)
            end
        end
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function private.onLfgSearchEntryUpdate(entry)
    if hookedEntries[entry] == nil then
        entry:HookScript('OnEnter', private.onLfgSearchEntryEnter)
        entry:HookScript('OnLeave', private.onLfgSearchEntryLeave)
        hookedEntries[entry] = true
    end
end

function private.onLfgSearchEntryEnter(entry)
    if addon.config.db.banButton and not ReportFrame:IsShown() then
        LFGSpamFilter_BanButton.resultId = entry.resultID
        LFGSpamFilter_BanButton:ClearAllPoints()
        LFGSpamFilter_BanButton:SetPoint('LEFT', entry, 'LEFT', -23, 0)
        LFGSpamFilter_BanButton:Show()
    end
end

function private.onLfgSearchEntryLeave()
    if addon.config.db.banButton and not MouseIsOver(LFGSpamFilter_BanButton, 5, -5, 5, 5) then
        banButton.hide()
    end
end

function private.onLfgSearchResultsUpdate()
    -- hide the ban button when results are updated (as the groups might change order etc.)
    banButton.hide()
end
