@LazyGlobal off.

runOncePath("0:/lib/ship/burnTime").
runOncePath("0:/lib/misc/logger").
runOncePath("0:/lib/misc/smartStage").
runOncePath("0:/lib/misc/smartWarp").

local defWarpStop is 10.

global function burnSettings {
	parameter burnVecFunction.
	parameter stopPredicate.
	parameter throttleFunction.
	parameter burnUT.

	local settings is Lexicon().
	
	// required parameters
	set settings["burnVecFunction"] to burnVecFunction.
	set settings["stopPredicate"] to stopPredicate.
	set settings["throttleFunction"] to throttleFunction.
	set settings["burnUT"] to burnUT.

	// default vparameters
	set settings["stopParam"] to false.
	set settings["warpStop"] to defWarpStop.
	set settings["forceBurn"] to false.
	set settings["dV"] to -1.
	set settings["message"] to "performing maneuver".
		
	return settings.
}

global function burn {
	parameter settings.
	
	local warpStop is settings["warpStop"].
	local estimatedDeltaV is settings["dV"].
	local burnUT is settings["burnUT"].

	if (estimatedDeltaV <> -1) {
		set burnUT to burnUT - burnTime(estimatedDeltaV / 2).
	}

	if (not settings["forceBurn"] and (burnUT - warpStop) < time:seconds) {
		logger("cannot perform maneuver: too late").
		return false.
	}
	
	lock steering to settings["burnVecFunction"]().
	smartWarp(burnUT - time:seconds, settings["message"], warpStop).
	
	local t0 is time:seconds.
	local lock burnT to time:seconds - t0.
	
	local stopPred is {
		if (settings["stopParam"]) {
			return settings["stopPredicate"](burnT).
		} else {
			return settings["stopPredicate"]().
		}
	}.
	
	until (stopPred()) {
		if (vang(steering, ship:facing:forevector) < 5) {
			local th is min(1, max(0.01, settings["throttleFunction"]())).
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