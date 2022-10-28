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

    LFGSpamFilterStatusButton.tooltip = ''
    LFGSpamFilterStatusButton:SetParent(LFGListFrame.SearchPanel)
    LFGSpamFilterStatusButton:SetPoint('TOPRIGHT', LFGListFrame.SearchPanel, 'TOPRIGHT', -44 + statusButtonLeftOffset, -25)
    LFGSpamFilterStatusButton:Show()
end

function statusButton.updateActive(acceptedCount, rejectedCount, isInverted)
    private.maybeShowButtonTip()

    if isInverted then
        LFGSpamFilterStatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking2')
        LFGSpamFilterStatusButton.Text:Show()
        LFGSpamFilterStatusButton.TextFrame:Show()
        LFGSpamFilterStatusButton.Text:SetText(string.format('|cffff0000%d|r', acceptedCount))
        LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 1, 1)
        LFGSpamFilterStatusButton.Icon:SetDesaturated(nil)

        if acceptedCount > 0 then
            LFGSpamFilterStatusButton.tooltip = string.format(
                'LFGSpamFilter would filter %d groups\n%s',
                acceptedCount,
                usageHint
            )
        else
            LFGSpamFilterStatusButton.tooltip = string.format(
                'LFGSpamFilter would not filter any groups\n%s',
                usageHint
            )
        end
    elseif rejectedCount > 0 then
        LFGSpamFilterStatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking0')
        LFGSpamFilterStatusButton.Text:Show()
        LFGSpamFilterStatusButton.TextFrame:Show()
        LFGSpamFilterStatusButton.Text:SetText(tostring(math.min(99, rejectedCount)))
        LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 0, 0)
        LFGSpamFilterStatusButton.Icon:SetDesaturated(nil)
        LFGSpamFilterStatusButton.tooltip = string.format(
            'LFGSpamFilter has filtered %d groups\n%s',
            rejectedCount,
            usageHint
        )
    else
        LFGSpamFilterStatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking0')
        LFGSpamFilterStatusButton.Text:Hide()
        LFGSpamFilterStatusButton.TextFrame:Hide()
        LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 1, 1)
        LFGSpamFilterStatusButton.Icon:SetDesaturated(1)
        LFGSpamFilterStatusButton.tooltip = string.format(
            'LFGSpamFilter has not filtered any groups\n%s',
            usageHint
        )
    end
end

function statusButton.updateInactive()
    LFGSpamFilterStatusButton.Text:Hide()
    LFGSpamFilterStatusButton.TextFrame:Hide()
    LFGSpamFilterStatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking4')
    LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 1, 1)
    LFGSpamFilterStatusButton.tooltip = string.format(
        'LFGSpamFilter is disabled for this category\n%s',
        usageHint
    )
end

function statusButton.onClick(button)
    if button == 'LeftButton' then
        -- toggle options on left click
        if LFGSpamFilterOptions:IsVisible() then
            LFGSpamFilterOptions:Hide()
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            LFGSpamFilterOptions:Show()
        end
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
    if not addon.config.db.buttonTipShown and LFGSpamFilterStatusButton:IsVisible() then
        addon.config.db.buttonTipShown = true
        HelpTip:Show(
            LFGSpamFilterStatusButton,
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
