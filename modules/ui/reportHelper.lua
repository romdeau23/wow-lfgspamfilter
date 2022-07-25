local _, addon = ...
local reportHelper, private = addon.module('ui', 'reportHelper')
local currentStep = 1
local steps = {
    -- reason dropdown - inappropriate communication
    function ()
        local majorCategory = Enum.ReportMajorCategory.InappropriateCommunication
        local expectedText = _G[C_ReportSystem.GetMajorCategoryString(majorCategory)]

        for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
            local button = _G['DropDownList1Button' ..i]

            if button and button.value == majorCategory and button:GetText() == expectedText then
                return button
            end
        end
    end,

    -- details - advertisement
    function ()
        for button in ReportFrame.MinorCategoryButtonPool:EnumerateActive() do
            if button.minorCategory == Enum.ReportMinorCategory.Advertisement then
                return button
            end
        end
    end,

    -- report button
    function ()
        if ReportFrame.ReportButton:IsEnabled() then
            return ReportFrame.ReportButton
        end
    end,
}

function reportHelper.init()
    LFGSpamFilterReportHelperButton:HookScript('OnClick', private.next)
    LFGSpamFilterReportHelperButton:HookScript('OnMouseDown', private.stopOnRightClick)
    ReportFrame:HookScript('OnHide', reportHelper.stop)
    hooksecurefunc('LFGListSearchPanel_UpdateResults', reportHelper.stop)
    addon.on('PLAYER_REGEN_DISABLED', reportHelper.stop)
end

function reportHelper.begin()
    currentStep = 1
    private.positionButton()
    private.updateButton()
    LFGSpamFilterReportHelperButton:Show()
    private.maybeShowButtonTip()
end

function reportHelper.stop()
    if reportHelper.isActive() then
        LFGSpamFilterReportHelperButton:Hide()
        ReportFrame:Hide()
    end
end

function reportHelper.isActive()
    return LFGSpamFilterReportHelperButton:IsShown()
end

function private.next()
    if currentStep < #steps then
        currentStep = currentStep + 1
        private.updateButton()
    else
        reportHelper.stop()
    end
end

function private.stopOnRightClick(_, button)
    if button == 'RightButton' then
        reportHelper.stop()
    end
end

function private.positionButton()
    local mouseX, mouseY = GetCursorPosition()
    local scale = LFGSpamFilterReportHelperButton:GetEffectiveScale()

    LFGSpamFilterReportHelperButton:ClearAllPoints()
    LFGSpamFilterReportHelperButton:SetPoint('CENTER', nil, 'BOTTOMLEFT', mouseX / scale, mouseY / scale)
end

function private.updateButton()
    local frameToClick = steps[currentStep]()

    if frameToClick then
        LFGSpamFilterReportHelperButton:SetAttribute('clickbutton', frameToClick)
        LFGSpamFilterReportHelperButton:SetText(string.format('%d/%d', currentStep - 1, #steps))
    else
        addon.ui.message(
            'Reporting failed'
            .. '\n\n(Make sure to not open other windows until the report is finished.)'
        )
        reportHelper.stop()
    end
end

function private.maybeShowButtonTip()
    if not addon.config.db.reportHelperTipShown then
        addon.config.db.reportHelperTipShown = true
        HelpTip:Show(
            LFGSpamFilterReportHelperButton,
            {
                text = 'Click this button 3 times to report the group for advertisement!'
                    .. '\n\nRight-click to dismiss. You can turn this off in options.',
                checkCVars = false,
                systemPriority = 999,
                buttonStyle = HelpTip.ButtonStyle.Close,
            }
        )
    end
end
