Glitter Hugs 0.3.1
Standalone addon for World of Warcraft: Forever 1.60.x (Interface 16001)

INSTALL
Extract the GlitterHugs folder into:
World of Warcraft/_forever_/Interface/AddOns/

The result should be Interface/AddOns/GlitterHugs/GlitterHugs.toc.
Enable Glitter Hugs in the game's AddOns list and enter the world.
If you installed it while the game was running, restart the game.

PLAY
Click the gem to select a nearby friendly player and give them a hug.
This replaces your current target. If no friendly player is found, no hug is sent.
You can also select a player yourself and type /hug. Repeat hugs count.
Drag the counter text to move the badge. Use /gh resetpos to put it back.

The counter is shared across your characters in this installation and resets
at midnight in your computer's local time. The addon recognizes the English
hug message. It counts confirmed targeted hugs, including full roleplay names.

SETTINGS
Right-click the heart on the minimap, type /gh, or open Settings > AddOns >
Glitter Hugs. Use the page to show or hide the badge or minimap button,
turn the sparkle on or off, lock the badge in place, or reset its position.
Drag the minimap heart to move it along the edge of your map.

DAILY HUG LOG
Left-click the minimap heart or type /gh history to open the log. It shows a
bar and an exact hug count for each day. Earlier and Later browse seven days
at a time. Drag the title bar to move the window. Its position is saved
across reloads. The addon records daily totals and keeps
the last daily count saved by an earlier version. Dates from before tracking
began show a dash.

OPTIONAL ACTION BAR MACRO
Paste these lines into a new macro:

/cleartarget
/targetfriendplayer
/stopmacro [noexists][nohelp]
/hug
