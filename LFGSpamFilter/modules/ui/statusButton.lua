local _, addon = ...
local statusButton, private = addon.module('ui', 'statusButton')

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

function statusButton.update(active, numFiltered)
    private.maybeShowButtonTip()

    local usageHint = DISABLED_FONT_COLOR_CODE .. '(click for options, right-click to toggle)|r';

    if active then
        LFGSpamFilterStatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking0')

        if numFiltered > 0 then
            LFGSpamFilterStatusButton.Text:Show()
            LFGSpamFilterStatusButton.TextFrame:Show()
            LFGSpamFilterStatusButton.Text:SetText(tostring(math.min(99, numFiltered)))
            LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 0, 0)
            LFGSpamFilterStatusButton.Icon:SetDesaturated(nil)
            LFGSpamFilterStatusButton.tooltip = string.format(
                'LFGSpamFilter has filtered %d groups\n%s',
                numFiltered,
                usageHint
            )
        else
            LFGSpamFilterStatusButton.Text:Hide()
            LFGSpamFilterStatusButton.TextFrame:Hide()
            LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 1, 1)
            LFGSpamFilterStatusButton.Icon:SetDesaturated(1)
            LFGSpamFilterStatusButton.tooltip = string.format(
                'LFGSpamFilter has not filtered any groups\n%s',
                usageHint
            )
        end
    else
        LFGSpamFilterStatusButton.Text:Hide()
        LFGSpamFilterStatusButton.TextFrame:Hide()
        LFGSpamFilterStatusButton.Icon:SetTexture('Interface\\LFGFRAME\\BattlenetWorking4')
        LFGSpamFilterStatusButton.Icon:SetVertexColor(1, 1, 1)
        LFGSpamFilterStatusButton.tooltip = string.format(
            'LFGSpamFilter is disabled for this category\n%s',
            usageHint
        )
    end
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
    else
        -- toggle category on right click
        local category = addon.ui.getCurrentLfgCategory()
        addon.config.setIgnoredCategory(category, not addon.config.isIgnoredCategory(category))
        addon.ui.hidePopups()
        addon.ui.updateLfgResults()
    end
end

function private.maybeShowButtonTip()
    if not addon.config.db.buttonTipShown and LFGSpamFilterStatusButton:IsVisible() then
        addon.config.db.buttonTipShown = true
        HelpTip:Show(
            LFGSpamFilterStatusButton,
            {
                text = 'This is the LFGSpamFilter status button.'
                    .. '\n\nClick on it for options.\nRight-click to toggle filtering.',
                checkCVars = false,
                systemPriority = 999,
                buttonStyle = HelpTip.ButtonStyle.Close,
            }
        )
    end
end
