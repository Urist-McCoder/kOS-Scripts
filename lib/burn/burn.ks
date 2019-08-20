@LazyGlobal off.

runOncePath("0:/lib/ship/burnTime").
runOncePath("0:/lib/misc/logger").
runOncePath("0:/lib/misc/smartStage").
runOncePath("0:/lib/misc/smartWarp").

local defWarpStop is 10.
local settings is Lexicon().
burnSettings().

global function burnSettings {
	local settings0 is Lexicon().
	
	set settings0["stopParam"] to false.
	set settings0["warpStop"] to defWarpStop.
	set settings0["forceBurn"] to false.
	set settings0["dV"] to -1.
	set settings0["message"] to "performing maneuver".
	
	set settings to settings0.	
	return settings.
}

global function burn {
	parameter burnVecFunction.
	parameter stopPredicate.
	parameter throttleFunction.
	parameter burnUT.
	
	local warpStop is settings["warpStop"].
	local estimatedDeltaV is settings["dV"].
	
	if (estimatedDeltaV <> -1) {
		set burnUT to burnUT - burnTime(estimatedDeltaV / 2).
	}
	if (not settings["forceBurn"] and burnUT - warpStop < time:seconds) {
		logger("cannot perform maneuver: too late").
		return false.
	}
	
	lock steering to burnVecFunction().
	smartWarp(burnUT - time:seconds, settings["message"], warpStop).
	
	local t0 is time:seconds.
	local lock burnT to time:seconds - t0.
	
	local stopPred is {
		if (settings["stopParam"]) {
			return stopPredicate(burnT).
		} else {
			return stopPredicate().
		}
	}.
	
	until (stopPred()) {
		if (vang(steering, ship:facing:forevector) < 5) {
			local th is min(1, max(0.01, throttleFunction())).
			lock throttle to th.
		} else {
			lock throttle to 0.
		}
		
		smartStage().
		wait 0.
	}
	
	lock throttle to 0.
	unlock steering.
	unlock burnT.
	wait 0. wait 0.	// BLACK MAGIC, DO NOT TOUCH
	
	return true.
}