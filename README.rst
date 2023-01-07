LFGSpamFilter (WoW addon)
#########################

This small addon will help you combat spam in the LFG tool.


Features
********

- filtering previously banned or reported players
- filtering based on group age or filled out voice chat
- quickly filling out advertisement reports
- temporary player bans

**Please note that this filtering is not 100%. It should improve over time as you report more spam groups.**


How to use
**********

This addon adds several new UI elements to the LFG tool:


Status button
=============

The status button shows the current state of LFG filtering:

- grey eye: no groups filtered
- red eye with a number: some groups filtered
- closed eye: filtering disabled in current LFG category
- squinting eye with red number: filtering is currently inverted (showing only groups that would be filtered)

The button has different mouse button interactions:

- left click shows options
- right click quickly toggles filtering for the current LFG category
- middle click temporarily inverts the filtering


Ban button
==========

When hovering a group, a red "X" will appear on the left side.

* left click reports and bans the group leader
* right click bans the group leader temporarily

  * temporary bans expire after you relog (and the player is not reported)
  * you can also clear temporary bans in options


Report helper
=============

After you ban a group a new button will appear at your mouse position. Clicking this button 3 times reports
the group for advertisement. This can be disabled in options.

Note: This functionality is not available while in combat.


FAQ
***

Why not filter using the group title, etc.?
===========================================

Sadly, Blizzard has made it impossible for addons to read the content of group titles, descriptions
and voice chat information. This limits the filtering to the other parameters and banning players by name.


Why are multiple clicks required to report a group?
===================================================

The report system update in 9.2.5 has made it impossible for addons to send reports directly.

If you don't want to report groups this way you can disable the "report helper" in options.


Known issues
************

- "Report Advertisement" context menu option doesn't always work - this is caused by UI taint from group filtering
  and is not fixable at the moment, use the "Report Group" option or the ban button provided by this addon instead
- errors related to calling ``GetPlaystyleString()`` - shouldn't happen if you have an authenticator on your account
