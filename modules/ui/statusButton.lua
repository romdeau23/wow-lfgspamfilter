local _, addon = ...
local statusButton, private = addon.module('ui', 'statusButton')
local usageHint = DISABLED_FONT_COLOR_CODE .. '(left click for options, right to toggle, middle to invert)|r'

function statusButton.init()
    local statusButtonLeftOffset = 0

    if addon.interop.isAddonEnabled('PremadeGroupsFilter') then
        statusButtonLeftOffset = statusButtonLeftOffset - 65
    end

    if addon.interop.isAddonEnabled('WorldQuestTracker') then
        statusButtonLeftOffset = statusButtonLeftOffset - 75
    end

    LFGSpamFilter_StatusButton.tooltip = ''
    LFGSpamFilter_StatusButton:SetParent(LFGListFrame.SearchPanel)
    LFGSpamFilter_StatusButton:SetPoint('TOPRIGHT', LFGListFrame.SearchPanel, 'TOPRIGHT', -44 + statusButtonLeftOffset, -25)
    LFGSpamFilter_StatusButton:Show()
end

function statusButton.updateActive(acceptedCount, rejectedCount, isInverted)
    private.maybeShowButtonTip()

    if isInverted then
        LFGSpamFilter_StatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking2')
        LFGSpamFilter_StatusButton.Text:Show()
        LFGSpamFilter_StatusButton.TextFrame:Show()
        LFGSpamFilter_StatusButton.Text:SetText(string.format('%s%d|r', RED_FONT_COLOR_CODE, math.min(99, acceptedCount)))
        LFGSpamFilter_StatusButton.Icon:SetVertexColor(1, 1, 1)
        LFGSpamFilter_StatusButton.Icon:SetDesaturated(nil)

        if acceptedCount > 0 then
            LFGSpamFilter_StatusButton.tooltip = string.format(
                'LFGSpamFilter would filter %d groups\n%s',
                acceptedCount,
                usageHint
            )
        else
            LFGSpamFilter_StatusButton.tooltip = string.format(
                'LFGSpamFilter would not filter any groups\n%s',
                usageHint
            )
        end
    elseif rejectedCount > 0 then
        LFGSpamFilter_StatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking0')
        LFGSpamFilter_StatusButton.Text:Show()
        LFGSpamFilter_StatusButton.TextFrame:Show()
        LFGSpamFilter_StatusButton.Text:SetText(tostring(math.min(99, rejectedCount)))
        LFGSpamFilter_StatusButton.Icon:SetVertexColor(1, 0, 0)
        LFGSpamFilter_StatusButton.Icon:SetDesaturated(nil)
        LFGSpamFilter_StatusButton.tooltip = string.format(
            'LFGSpamFilter has filtered %d groups\n%s',
            rejectedCount,
            usageHint
        )
    else
        LFGSpamFilter_StatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking0')
        LFGSpamFilter_StatusButton.Text:Hide()
        LFGSpamFilter_StatusButton.TextFrame:Hide()
        LFGSpamFilter_StatusButton.Icon:SetVertexColor(1, 1, 1)
        LFGSpamFilter_StatusButton.Icon:SetDesaturated(1)
        LFGSpamFilter_StatusButton.tooltip = string.format(
            'LFGSpamFilter has not filtered any groups\n%s',
            usageHint
        )
    end
end

function statusButton.updateInactive()
    LFGSpamFilter_StatusButton.Text:Hide()
    LFGSpamFilter_StatusButton.TextFrame:Hide()
    LFGSpamFilter_StatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking4')
    LFGSpamFilter_StatusButton.Icon:SetVertexColor(1, 1, 1)
    LFGSpamFilter_StatusButton.tooltip = string.format(
        'LFGSpamFilter is disabled for this category\n%s',
        usageHint
    )
end

function statusButton.onClick(button)
    if button == 'LeftButton' then
        -- toggle options on left click
        addon.ui.options.toggle()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    elseif button == 'RightButton' then
        -- toggle category on right click
        local category = addon.ui.getCurrentLfgCategory()
        addon.config.setIgnoredCategory(category, not addon.config.isIgnoredCategory(category))
        addon.main.setInvertFilter(false)
        addon.ui.hidePopups()
        addon.ui.updateLfgResults()
    elseif button == 'MiddleButton' then
        -- toggle inverted filtering on middle click
        if not addon.config.isIgnoredCategory(addon.ui.getCurrentLfgCategory()) then
            addon.main.setInvertFilter(not addon.main.isFilterInverted())
            addon.ui.hidePopups()
            addon.ui.updateLfgResults()
        end
    end
end

function private.maybeShowButtonTip()
    if not addon.config.db.buttonTipShown and LFGSpamFilter_StatusButton:IsVisible() then
        addon.config.db.buttonTipShown = true
        HelpTip:Show(
            LFGSpamFilter_StatusButton,
            {
                text = 'This is the LFGSpamFilter status button.\n\n'
                    .. 'Click on it for options.\n'
                    .. 'Right-click to toggle filtering.\n'
                    .. 'Middle-click to invert filtering.',
                checkCVars = false,
                systemPriority = 999,
                buttonStyle = HelpTip.ButtonStyle.Close,
            }
        )
    end
end
