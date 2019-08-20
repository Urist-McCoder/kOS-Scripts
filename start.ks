@LazyGlobal off.
switch to 1. SAS off.
clearscreen. clearvecdraws().

// better safe than sorry
set ship:control:pilotmainthrottle to 0.

// terminal appearance
set terminal:width to 60.
set terminal:height to 35.
set terminal:charheight to 12.

// import missionScript and its dependencies
parameter missionScript is "template".

runOncePath("0:/lib/globals").
runOncePath("0:/missions/" + missionScript).
MISSION_SCRIPT["import"]().

if (not addons:available("RT")) {
	// simulate delay
	local speedOfLight is 1e7.	// scaled down
	local dist is (Body("Kerbin"):position - ship:position):mag.

	runOncePath("0:/lib/misc/smartWarp").
	smartWarp(dist / speedOfLight, "signal delay").
}

MISSION_SCRIPT["execute"]().	// execute mission script

clearvecdraws().