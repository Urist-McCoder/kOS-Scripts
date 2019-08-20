@LazyGlobal off.

runOncePath("0:/lib/burn/burn").
runOncePath("0:/lib/misc/logger").


global function circularize {
	parameter burnETA is -1.
	parameter maxErr is 0.05.
	parameter warpStop is -1.
	
	local lock obtSpeed to sqrt(ship:body:mu / (ship:body:radius + ship:altitude)).
	local lock unitVec to vxcl(ship:body:position, ship:velocity:orbit):normalized.
	local lock obtVec to obtSpeed * unitVec.
	local lock corrVec to obtVec - ship:velocity:orbit.
	
	logger("circularization (estimated dV: " + round(corrVec:mag) + ")").
	logger("initial orbit parameters:").
	printInfo().
	
	local settings is burnSettings().
	set settings["forceBurn"] to true.
	set settings["message"] to "performing orbit circularization".
	if (warpStop <> -1) {
		set settings["warpStop"] to warpStop.
	}
	
	local ut is time:seconds + burnETA.
	local burnVec is {return corrVec.}.
	local stopPredicate is {return corrVec:mag < maxErr.}.
	local thrFunction is {
		local thr is ship:availablethrust.
		if (thr > 0) {
			return 5 * corrVec:mag * ship:mass / thr.
		} else {
			return 0.
		}
	}.
	
	burn(burnVec, stopPredicate, thrFunction, ut).
	
	logger("circularization complete").
	logger("circularized orbit parameters:").
	printInfo().
}

local function printInfo {
	parameter indentation is 4.
	
	local s is "".
	until (indentation <= 0) {
		set s to s + " ".
		set indentation to indentation - 1.
	}
	
	logger(s + "Apoapsis:   " + round(ship:apoapsis / 1000, 3) + " km").
	logger(s + "Periapsis:  " + round(ship:periapsis / 1000, 3) + " km").
	logger(s + "Eccentricity: " + round(ship:obt:eccentricity, 4)).
}