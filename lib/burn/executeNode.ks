@LazyGlobal off.

runOncePath("0:/lib/burn/burn").
runOncePath("0:/lib/misc/logger").


global function executeNode {
	parameter warpStop is 10.
	parameter margin is 0.05.
	parameter forceBurn is false.
	
	logger("executing maneuver node").
	
	local settings is burnSettings().
	set settings["forceBurn"] to forceBurn.
	set settings["warpStop"] to warpStop.
	set settings["dV"] to nextNode:deltaV:mag.
	set settings["message"] to "executing maneuver node".
	
	local ut is time:seconds + nextNode:ETA.
	local done is burn(burnVec@, stopPr@:bind(margin), thrFunction@, ut).
	
	if (done) {
		remove nextNode.
		wait 0.
	}
	
	return done.
}

local function burnVec {
	return nextNode:deltaV.
}

local function stopPr {
	parameter margin.
	
	return nextNode:deltaV:mag <= margin.
}

local function thrFunction {
	local thr is ship:availablethrust.
	if (thr > 0) {
		return 5 * nextNode:deltaV:mag * ship:mass / thr.
	} else {
		return 0.
	}
}