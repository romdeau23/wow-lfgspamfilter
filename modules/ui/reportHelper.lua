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
    LFGSpamFilter_ReportHelperButton:SetScript('PostClick', private.postButtonClick)
    ReportFrame:HookScript('OnHide', reportHelper.stop)
    hooksecurefunc('LFGListSearchPanel_UpdateResults', reportHelper.stop)
    addon.on('PLAYER_REGEN_DISABLED', reportHelper.stop)
end

function reportHelper.begin()
    currentStep = 1
    private.positionButton()
    private.updateButton()
    LFGSpamFilter_ReportHelperButton:Show()
    private.maybeShowButtonTip()
end

function reportHelper.stop()
    if reportHelper.isActive() then
        LFGSpamFilter_ReportHelperButton:Hide()
        ReportFrame:Hide()
    end
end

function reportHelper.isActive()
    return LFGSpamFilter_ReportHelperButton:IsShown()
end

function private.next()
    if currentStep < #steps then
        currentStep = currentStep + 1
        private.updateButton()
    else
        reportHelper.stop()
    end
end

function private.postButtonClick(_, button, isDown)
    if isDown ~= GetCVarBool('ActionButtonUseKeyDown') then
        -- secure buttons activate the click at different times depending on the CVar
        -- ignore the cases when it wouldn't activate
        return
    end

    if button == 'LeftButton' then
        private.next()
    elseif button == 'RightButton' then
        reportHelper.stop()
    end
end

function private.onButtonClick(_, button)
    if button == 'LeftButton' then
        private.next()
    elseif button == 'RightButton' then
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
    local scale = LFGSpamFilter_ReportHelperButton:GetEffectiveScale()

    LFGSpamFilter_ReportHelperButton:ClearAllPoints()
    LFGSpamFilter_ReportHelperButton:SetPoint('CENTER', nil, 'BOTTOMLEFT', mouseX / scale, mouseY / scale)
end

function private.updateButton()
    local frameToClick = steps[currentStep]()

    if frameToClick then
        LFGSpamFilter_ReportHelperButton:SetAttribute('clickbutton1', frameToClick)
        LFGSpamFilter_ReportHelperButton:SetText(string.format('%d/%d', currentStep - 1, #steps))
    else
        addon.ui.message(
            'Reporting failed (#%d)'
            .. '\n\n(Make sure to not do anything else until the report is finished.)',
            currentStep
        )
        reportHelper.stop()
    end
end

function private.maybeShowButtonTip()
    if not addon.config.db.reportHelperTipShown then
        addon.config.db.reportHelperTipShown = true
        HelpTip:Show(
            LFGSpamFilter_ReportHelperButton,
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
