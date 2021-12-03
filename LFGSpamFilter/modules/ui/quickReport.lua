local _, addon = ...
local quickReport, private = addon.module('ui', 'quickReport')
local hookedEntries = {}

function quickReport.init()
    hooksecurefunc('LFGListSearchEntry_Update', private.onLfgSearchEntryUpdate)
    hooksecurefunc('LFGListSearchPanel_UpdateResults', private.onLfgSearchResultsUpdate)
end

function quickReport.onClick()
    local resultId = LFGSpamFilterQuickReportButton.resultId

    if resultId then
        addon.main.quickReport(resultId)
        addon.ui.updateLfgResults()
    end
end

function private.onLfgSearchEntryUpdate(entry)
    if hookedEntries[entry:GetName()] == nil then
        entry:HookScript('OnEnter', private.onLfgSearchEntryEnter)
        entry:HookScript('OnLeave', private.onLfgSearchEntryLeave)
        hookedEntries[entry:GetName()] = true
    end
end

function private.onLfgSearchEntryEnter(entry)
    if addon.config.db.quickReport then
        LFGSpamFilterQuickReportButton.resultId = entry.resultID
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
