LFGSpamFilter (WoW addon)
#########################

This small addon will help you combat spam in the LFG tool.

Features
********

- quick reporting
- filtering reported players
- filtering based on group age or filled out voice chat (usually spam)
- fixing the duplicate applications bug

**Please note that this filtering is not 100%. It should improve over time as you report more spam groups.**

**You should also disable voice-chat filtering if you tend to join groups based on that.**


How to use
**********

This addon adds two new UI elements to the LFG tool:

Status button
=============

The status button shows the current state of LFG filtering:

- grey eye: no groups filtered
- red eye with a number: some groups filtered
- closed eye: filtering disabled in current LFG category

Clicking on it will show the options pop-up. Right-clicking quickly toggles filtering for the current LFG category.

Quick-report button
===================

When hovering a group, a red "X" will appear on the left side. Clicking it reports the group for advertisement and also bans the group leader.


FAQ
***

Why not filter using the group title, etc.?
===========================================

Sadly, Blizzard has made it impossible for addons to read the content of group titles, descriptions and voice chat information. This limits the filtering to the other parameters.


Known issues
************

- errors related to calling ``GetPlaystyleString()`` - shouldn't happen if you have an authenticator on your account
