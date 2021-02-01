local addonName, LFGSpamFilter = ...

LFGSpamFilterAddon = LFGSpamFilter

LFGSpamFilter.frame = CreateFrame('Frame')
LFGSpamFilter.ready = false
LFGSpamFilter.splash = false
LFGSpamFilter.reportingGroup = false
LFGSpamFilter.configVersion = 3
LFGSpamFilter.eventHandlers = {
    ADDON_LOADED = 'onAddonLoaded',
    LFG_LIST_SEARCH_RESULT_UPDATED = 'onSearchResultUpdated',
}
LFGSpamFilter.hookCache = {
    onButtonEnter = function (button) LFGSpamFilter:onButtonEnter(button) end,
    onButtonLeave = function () LFGSpamFilter:onButtonLeave() end,
}
LFGSpamFilter.commands = {
    [''] = {
        method = 'runHelpCommand',
    },
    info = {
        help = 'show configuration and stats',
        method = 'runInfoCommand',
    },
    toggle = {
        usage = '[on|off]',
        help = 'enable or disable filtering',
        method = 'runToggleCommand',
        acceptsArgument = true,
    },
    report = {
        usage = 'on|off',
        help = 'enable or disable spam reporting',
        method = 'runReportCommand',
        acceptsArgument = true,
    },
    blacklist = {
        usage = 'on|off',
        help = 'enable or disable blacklist-based filtering',
        method = 'runBlacklistCommand',
        acceptsArgument = true,
    },
    ['max-age'] = {
        usage = '<hours>',
        help = 'filter groups older than this (0 to disable)',
        method = 'runMaxAgeCommand',
        acceptsArgument = true,
    },
    ['no-voice'] = {
        usage = 'on|off',
        help = 'filter groups with voice info',
        method = 'runNoVoiceCommand',
        acceptsArgument = true,
    },
    button = {
        usage = 'on|off',
        help = 'enable or disable the quick-report button',
        method = 'runButtonCommand',
        acceptsArgument = true,
    },
    undo = {
        help = 'undo the last ban',
        method = 'runUndoCommand',
    },
    ['clear-blacklist'] = {
        help = 'clear the blacklist',
        method = 'runClearBlacklistCommand',
    },
    ['factory-reset'] = {
        help = 'reset all options and data',
        method = 'runFactoryResetCommand',
    },
}
LFGSpamFilter.commandList = {
    'info',
    'toggle',
    'report',
    'blacklist',
    'max-age',
    'no-voice',
    'button',
    'undo',
    'clear-blacklist',
    'factory-reset',
}

function LFGSpamFilter:say(msg, ...)
    print(string.format(
        '|cffffd700<%s>|r ' .. msg,
        addonName,
        ...
    ))
end

function LFGSpamFilter:error(msg, ...)
    self:say('|cffff0000' .. msg .. '|r', ...)
end

function LFGSpamFilter:registerEvents()
    for event, _ in pairs(self.eventHandlers) do
        self.frame:RegisterEvent(event)
    end

    self.frame:SetScript('OnEvent', function (frame, event, ...)
        if self[self.eventHandlers[event]](self, ...) then
            frame:UnregisterEvent(event)
        end
    end)
end

function LFGSpamFilter:onAddonLoaded(loadedAddonName)
    if loadedAddonName == addonName then
        self:initConfiguration()
        self:initSlashCommand()
        self:initHooks()
        self:maintenance()
        self.ready = true

        return true
    end
end

function LFGSpamFilter:initConfiguration()
    if LFGSpamFilterAddonConfig == nil or not pcall(self.migrateConfiguration, self) then
        self:setDefaultConfiguration()
    end
end

function LFGSpamFilter:setDefaultConfiguration()
    LFGSpamFilterAddonConfig = {
        version = self.configVersion,
        enabled = true,
        report = true,
        button = true,
        blacklist = {},
        blacklistEnabled = true,
        lastBan = nil,
        stats = {
            reports = 0,
            filtered = 0,
        },
        maxAge = 4 * 3600,
        noVoice = true,
        lastMaintenance = time(),
    }
end

function LFGSpamFilter:migrateConfiguration()
    for from = LFGSpamFilterAddonConfig.version, self.configVersion - 1 do
        if from == 1 then
            LFGSpamFilterAddonConfig.blacklistEnabled = true
        elseif from == 2 then
            LFGSpamFilterAddonConfig.button = true

            -- fix missing default state
            if LFGSpamFilterAddonConfig.blacklistEnabled ~= false then
                LFGSpamFilterAddonConfig.blacklistEnabled = true
            end
        end
    end

    LFGSpamFilterAddonConfig.version = self.configVersion
end

function LFGSpamFilter:initSlashCommand()
    SLASH_LFG_SPAM_FILTER1 = '/lfgspamfilter'
    SLASH_LFG_SPAM_FILTER2 = '/lfgsf'
    SLASH_LFG_SPAM_FILTER3 = '/lsf'

    SlashCmdList.LFG_SPAM_FILTER = function(input)
        input = strtrim(input)

        local sepStart, sepEnd = string.find(input, '%s+')
        local command, argument

        if sepStart then
            command = string.sub(input, 1, sepStart - 1)
            argument = string.sub(input, sepEnd + 1)
        else
            command = input
        end

        self:runSlashCommand(command, argument)
    end
end

function LFGSpamFilter:runSlashCommand(name, argument)
    local command = self.commands[name]

    if not command then
        self:error('Unknown command "%s"', name)
        return
    end

    if argument and not command.acceptsArgument then
        self:error('Command "%s" does not accept an argument', name)
        return
    end

    local success, result = pcall(self[command.method], self, argument)

    if not success then
        self:error('%s: %s', name, result)
    end
end

function LFGSpamFilter:runHelpCommand()
    self:say('command list:')

    for _, name in ipairs(self.commandList) do
        local command = self.commands[name]
        local line = '|cff47bbff/lsf ' .. name .. '|r'

        if command.usage then
            line = line .. ' |cffffd700' .. command.usage .. '|r'
        end

        if command.help then
            line = line .. ' ' .. command.help
        end

        print(line)
    end
end

function LFGSpamFilter:runInfoCommand()
    self:say('configuration:')
    print('|cff47bbfffiltering:|r', self:formatBool(LFGSpamFilterAddonConfig.enabled))
    print('|cff47bbffreporting:|r', self:formatBool(LFGSpamFilterAddonConfig.report))
    print('|cff47bbffblacklist:|r', self:formatBool(LFGSpamFilterAddonConfig.blacklistEnabled))
    if LFGSpamFilterAddonConfig.maxAge > 0 then print('|cff47bbffmax age:|r', string.format('|cff00ff00%.2f hours|r', LFGSpamFilterAddonConfig.maxAge / 3600))
    else print('|cff47bbffmax age:|r', self:formatBool(false)) end
    print('|cff47bbffno voice:|r', self:formatBool(LFGSpamFilterAddonConfig.noVoice))
    print('|cff47bbffbutton:|r', self:formatBool(LFGSpamFilterAddonConfig.button))
    self:say('statistics:')
    print('|cff47bbffreports:|r', LFGSpamFilterAddonConfig.stats.reports)
    print('|cff47bbfffilter hits:|r', LFGSpamFilterAddonConfig.stats.filtered)
    print('|cff47bbffblacklisted players:|r', self:getBlacklistSize())
end

function LFGSpamFilter:runToggleCommand(argument)
    if argument == nil then
        LFGSpamFilterAddonConfig.enabled = not LFGSpamFilterAddonConfig.enabled
    else
        LFGSpamFilterAddonConfig.enabled = self:parseBoolCommandArgument(argument)
    end

    self:say('filtering is now %s', self:formatBool(LFGSpamFilterAddonConfig.enabled))
end

function LFGSpamFilter:runReportCommand(argument)
    LFGSpamFilterAddonConfig.report = self:parseBoolCommandArgument(argument)
    self:say('reporting is now %s', self:formatBool(LFGSpamFilterAddonConfig.report))
end

function LFGSpamFilter:runBlacklistCommand(argument)
    LFGSpamFilterAddonConfig.blacklistEnabled = self:parseBoolCommandArgument(argument)
    self:say('blacklist usage is now %s', self:formatBool(LFGSpamFilterAddonConfig.blacklistEnabled))
end

function LFGSpamFilter:runMaxAgeCommand(argument)
    argument = tonumber(argument)

    if argument == nil then
        error('invalid argument, provide a number of hours', 0)
    end

    argument = math.max(0, argument)

    LFGSpamFilterAddonConfig.maxAge = argument * 3600

    if LFGSpamFilterAddonConfig.maxAge == 0 then
        self:say('group age filtering has been |cffff0000disabled|r')
    else
        self:say('max group age has been set to |cff00ff00%.2f hours|r', LFGSpamFilterAddonConfig.maxAge / 3600)
    end
end

function LFGSpamFilter:runNoVoiceCommand(argument)
    LFGSpamFilterAddonConfig.noVoice = self:parseBoolCommandArgument(argument)
    self:say('voice chat filtering is now %s', self:formatBool(LFGSpamFilterAddonConfig.noVoice))
end

function LFGSpamFilter:runButtonCommand(argument)
    LFGSpamFilterAddonConfig.button = self:parseBoolCommandArgument(argument)
    LFGSpamFilterBanButton:Hide()
    self:say('quick report button is now %s', self:formatBool(LFGSpamFilterAddonConfig.button))
end

function LFGSpamFilter:runUndoCommand()
    if not LFGSpamFilterAddonConfig.lastBan then
        self:say('nothing to undo')
        return
    end

    self:unbanGroup(LFGSpamFilterAddonConfig.lastBan.id)
    self:removeGroupFromFilter(LFGSpamFilterAddonConfig.lastBan.id)

    if LFGSpamFilterAddonConfig.lastBan.player then
        self:removeFromBlacklist(LFGSpamFilterAddonConfig.lastBan.player)
    end

    LFGSpamFilterAddonConfig.lastBan = nil
    self:updateLfgList()
    self:say('undid last ban')
end

function LFGSpamFilter:runClearBlacklistCommand()
    local numBlacklisted = self:getBlacklistSize()
    self:clearBlacklist()
    self:say('removed %d players from blacklist', numBlacklisted)
end

function LFGSpamFilter:runFactoryResetCommand()
    self:setDefaultConfiguration()
    self:updateLfgList()
    self:say('all options and data have been reset')
end

function LFGSpamFilter:parseBoolCommandArgument(argument)
    if argument == 'on' or argument == '1' then
        return true
    elseif argument == 'off' or argument == '0' then
        return false
    elseif argument == nil then
        error('missing argument, use on, off, 1 or 0', 0)
    else
        error('invalid argument, use on, off, 1 or 0', 0)
    end
end

function LFGSpamFilter:formatBool(value)
    if value then
        return '|cff00ff00enabled|r'
    else
        return '|cffff0000disabled|r'
    end
end

function LFGSpamFilter:initHooks()
    hooksecurefunc('LFGListUtil_SortSearchResults', function (results) self:filter(results) end)
    hooksecurefunc('LFGListSearchEntry_Update', function (button) self:updateButton(button) end)
    hooksecurefunc(C_LFGList, 'ReportSearchResult', function (id, reason) self:postReportGroup(id, reason) end)
    LFGListFrame:HookScript('OnHide', function () self:onLfgListHide() end)
end

function LFGSpamFilter:maintenance()
    -- run maintenance once a week
    if time() - LFGSpamFilterAddonConfig.lastMaintenance > 604800 then
        self:cleanupBlacklist(7776000) -- remove blacklisted players not seen for over 3 months
        LFGSpamFilterAddonConfig.lastMaintenance = time()
    end
end

function LFGSpamFilter:doSplash()
    self:say(
        '|cff808080(v%s by %s)|r |cff47bbff/lsf for help|r',
        GetAddOnMetadata(addonName, 'Version'),
        GetAddOnMetadata(addonName, 'Author')
    )
    self.splash = true
end

function LFGSpamFilter:filter(results)
    if not LFGSpamFilterAddonConfig.enabled or not self:isLfgListOpen() then
        return
    end

    if not self.splash then
        self:doSplash()
    end

    local accepted = {}
    local numAccepted = 0
    local numResults = #results

    -- filter results into another table
    for i = 1, numResults do
        local id = results[i]
        local info = C_LFGList.GetSearchResultInfo(id)

        if info then
            if self:accept(info) then
                numAccepted = numAccepted + 1
                accepted[numAccepted] = id
            else
                LFGSpamFilterAddonConfig.stats.filtered = LFGSpamFilterAddonConfig.stats.filtered + 1
            end
        end
    end

    -- replace the results table if any groups were filtered out
    if numAccepted ~= numResults then
        table.wipe(results)

        for i = 1, numAccepted do
            results[i] = accepted[i]
        end
    end
end

function LFGSpamFilter:accept(info)
    return (
            info.age <= LFGSpamFilterAddonConfig.maxAge
            or LFGSpamFilterAddonConfig.maxAge == 0
        )
        and (
            not LFGSpamFilterAddonConfig.blacklistEnabled
            or info.leaderName == nil
            or not self:isBlacklisted(self:normalizePlayerName(info.leaderName))
        )
        and (
            info.voiceChat == ''
            or not LFGSpamFilterAddonConfig.noVoice
        )
end

function LFGSpamFilter:onSearchResultUpdated(id)
    if self.ready and self:isLfgListOpen() then
        local info = C_LFGList.GetSearchResultInfo(id)

        if info and not self:accept(info) then
            self:updateLfgList()
        end
    end
end

function LFGSpamFilter:updateButton(button)
    if not button._LFGSpamFilterHooked then
        button:HookScript('OnEnter', self.hookCache.onButtonEnter)
        button:HookScript('OnLeave', self.hookCache.onButtonLeave)
        button._LFGSpamFilterHooked = true
    end
end

function LFGSpamFilter:onButtonEnter(button)
    if LFGSpamFilterAddonConfig.button then
        LFGSpamFilterBanButton._LFGSpamFilterId = button.resultID
        LFGSpamFilterBanButton:ClearAllPoints()
        LFGSpamFilterBanButton:SetPoint('LEFT', button, 'LEFT', -25, 0)
        LFGSpamFilterBanButton:Show()
    end
end

function LFGSpamFilter:onButtonLeave()
    if LFGSpamFilterAddonConfig.button and not MouseIsOver(LFGSpamFilterBanButton) then
        LFGSpamFilterBanButton:Hide()
    end
end

function LFGSpamFilter:onBanButtonClick()
    local id = LFGSpamFilterBanButton._LFGSpamFilterId

    if id then
        self:banGroup(id)
        self:reportGroup(id)
        self:addGroupToFilter(id)
        self:updateLfgList()
    end
end

function LFGSpamFilter:onLfgListHide()
    LFGSpamFilterBanButton:Hide()
end

function LFGSpamFilter:isLfgListOpen()
    return LFGListFrame.SearchPanel:IsShown()
end

function LFGSpamFilter:updateLfgList()
    if not self:isLfgListOpen() then
        return
    end

    LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel)
    LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel)
end

function LFGSpamFilter:normalizePlayerName(name)
    local dashPos = string.find(name, '-', 1, true)

    if dashPos == nil then
        name = name .. '-' .. GetRealmName()
    end

    return name
end

function LFGSpamFilter:banGroup(id)
    local info = C_LFGList.GetSearchResultInfo(id)

    -- remember last ban
    LFGSpamFilterAddonConfig.lastBan = {id = id, player = nil}

    -- blacklist the leader
    if info and info.leaderName then
        local normalizedName = self:normalizePlayerName(info.leaderName)

        self:blacklistPlayer(normalizedName)
        LFGSpamFilterAddonConfig.lastBan.player = normalizedName
    end
end

function LFGSpamFilter:unbanGroup(id)
    local info = C_LFGList.GetSearchResultInfo(id)

    if info and info.leaderName then
        self:removeFromBlacklist(self:normalizePlayerName(info.leaderName))
    end
end

function LFGSpamFilter:addGroupToFilter(id)
    LFGListSearchPanel_AddFilteredID(LFGListFrame.SearchPanel, id)
end

function LFGSpamFilter:removeGroupFromFilter(id)
    if LFGListFrame.SearchPanel.filteredIDs then
        for i, filteredId in ipairs(LFGListFrame.SearchPanel.filteredIDs) do
            if filteredId == id then
                table.remove(LFGListFrame.SearchPanel.filteredIDs, i)
                break
            end
        end
    end
end

function LFGSpamFilter:reportGroup(id)
    if LFGSpamFilterAddonConfig.report then
        self.reportingGroup = true
        pcall(C_LFGList.ReportSearchResult, id, 'lfglistspam')
        self.reportingGroup = true
    end
end

function LFGSpamFilter:postReportGroup(id, reason)
    -- ignore reports for other reasons
    if reason ~= 'lfglistspam' then
        return
    end

    -- count the report
    LFGSpamFilterAddonConfig.stats.reports = LFGSpamFilterAddonConfig.stats.reports + 1

    -- also ban the group if this is a report from the drop-down menu (not using the ban button)
    if not self.reportingGroup then
        self:banGroup(id)
    end
end

function LFGSpamFilter:blacklistPlayer(normalizedName)
    LFGSpamFilterAddonConfig.blacklist[normalizedName] = time()
end

function LFGSpamFilter:removeFromBlacklist(normalizedName)
    LFGSpamFilterAddonConfig.blacklist[normalizedName] = nil
end

function LFGSpamFilter:isBlacklisted(normalizedName)
    if LFGSpamFilterAddonConfig.blacklist[normalizedName] then
        -- update last seen time
        LFGSpamFilterAddonConfig.blacklist[normalizedName] = time()

        return true
    end

    return false
end

function LFGSpamFilter:clearBlacklist()
    table.wipe(LFGSpamFilterAddonConfig.blacklist)
end

function LFGSpamFilter:cleanupBlacklist(threshold)
    local now = time()

    for name, lastSeen in pairs(LFGSpamFilterAddonConfig.blacklist) do
        if now - lastSeen >= threshold then
            LFGSpamFilterAddonConfig.blacklist[name] = nil
        end
    end
end

function LFGSpamFilter:getBlacklistSize()
    local size = 0

    for _ in pairs(LFGSpamFilterAddonConfig.blacklist) do
        size = size + 1
    end

    return size
end

-- register events
LFGSpamFilter:registerEvents()
