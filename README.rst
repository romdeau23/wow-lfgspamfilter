LFGSpamFilter (WoW addon)
#########################

This small addon will help you combat spam in the LFG tool.


Features
********

- filtering previously banned or reported players
- filtering based on group age or filled out voice chat
- quickly filling out advertisement reports
- fixing the duplicate applications bug

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

Clicking on it will show the options pop-up. Right-clicking quickly toggles filtering for the current LFG category.


Ban button
==========

When hovering a group, a red "X" will appear on the left side. Clicking it bans the group leader
from appearing in your seach results. Reporting the group has the same effect.


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

- errors related to calling ``GetPlaystyleString()`` - shouldn't happen if you have an authenticator on your account
