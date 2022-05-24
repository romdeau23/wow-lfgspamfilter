local _, addon = ...
local interop, private = addon.module('interop')
local getPlaystyleStringFixed = false
local getPlaystyleStringPrefixMap = {
    isMythicPlusActivity = 'GROUP_FINDER_PVE_PLAYSTYLE',
    isRatedPvpActivity = 'GROUP_FINDER_PVP_PLAYSTYLE',
    isCurrentRaidActivity = 'GROUP_FINDER_PVE_RAID_PLAYSTYLE',
    isMythicActivity = 'GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE',
}

function interop.isAddonEnabled(name)
    return select(4, GetAddOnInfo(name)) == true
end

-- C_LFGList.GetPlaystyleString() is currently protected for whatever reason
-- and needs to be replaced to fix missing playstyle titles
function interop.fixGetPlaystyleString()
    if getPlaystyleStringFixed then
        return
    end

    if
        -- if not already overriden by other addons
        issecurevariable(C_LFGList, 'GetPlaystyleString')

        -- and the player has an authenticator
        -- (can't create groups with tainted GetPlaystyleString() without an authenticator)
        and C_LFGList.IsPlayerAuthenticatedForLFG(695) -- De Other Side
    then
        C_LFGList.GetPlaystyleString = private.getPlaystyleStringOverride

        -- prevent taint error in group creation
        -- (also disables the title pre-filling functionality so it's a trade-off)
        LFGListEntryCreation_SetTitleFromActivityInfo = function() end
    end

    getPlaystyleStringFixed = true
end

function private.getPlaystyleStringOverride(playstyle, activityInfo)
    if
        playstyle
        and playstyle ~= 0
        and activityInfo
        and C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown
    then
        local prefix = private.getPlaystyleStringPrefix(activityInfo)

        if prefix then
            return _G[prefix .. tostring(playstyle)]
        end
    end
end

function private.getPlaystyleStringPrefix(activityInfo)
    for prop, prefix in pairs(getPlaystyleStringPrefixMap) do
        if activityInfo[prop] then
            return prefix
        end
    end
end
