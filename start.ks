@LazyGlobal off.
switch to 1. SAS off.
clearscreen. clearvecdraws().

// better safe than sorry
set ship:control:pilotmainthrottle to 0.

set terminal:width to 60.
set terminal:height to 35.
set terminal:charheight to 18.

// import missionScript and its dependencies
// (globals.ks will be imported from missionScript.ks)
parameter missionScript is "template".

import("missions/" + missionScript, false).
MISSION_SCRIPT["import"]().

if (not addons:available("RT")) {
	simulateDelay().	// definition is at the bottom of the file
}

MISSION_SCRIPT["execute"]().	// execute mission script

clearvecdraws().

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// important global function import()

global function import {
	parameter filePath.
	parameter isLib is true.
	
	if (isLib) {
		set filePath to "lib/" + filePath.
	}
	runoncepath("0:/" + filePath + ".ks").
}

local function simulateDelay {
	local speedOfLight is 1e8.	// scaled down for obvious reasons
	local dist is (Body("Kerbin"):position - ship:position):mag.

	import("misc/smartWarp").
	smartWarp(dist / speedOfLight, "signal delay").
}