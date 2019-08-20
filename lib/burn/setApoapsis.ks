@LazyGlobal off.

runOncePath("0:/lib/burn/burn").
runOncePath("0:/lib/maneuver/hohmannTransfer").
runOncePath("0:/lib/misc/logger").

local function burnVec {
	parameter f.
	
	return f * ship:velocity:orbit.
}

local function stopPred {
	parameter tgtApo.
	parameter f.
	
	return f * ship:apoapsis >= f * tgtApo.
}

local function thrFunction {
	parameter tgtApo.
	parameter thrDown.
	
	return abs(ship:apoapsis - tgtApo) / thrDown.
}

global function setApoapsis {
	parameter tgtApo.
	parameter throttleDownDiff.
	parameter burnEta is ETA:periapsis.
	
	local ut is time:seconds + burnETA.
	local radVec is positionAt(ship, ut) - ship:body:position.
	local burnAlt is radVec:mag - ship:body:radius.
	
	if (tgtApo < burnAlt) {
		logger("cannot set apoapsis: too low (" + tgtApo + " < " + burnAlt + ")").
		return false.
	}
	
	local f is 1.
	if (ship:apoapsis > tgtApo) {
		set f to -1.
	}
	
	local settings is burnSettings(
		burnVec@:bind(f),
		stopPred@:bind(tgtApo, f),
		thrFunction@:bind(tgtApo, throttleDownDiff),
		ut
	).

	set settings["message"] to "changing apoapsis".

	if (ship:obt:eccentricity < 0.01) {
		local dv is hohmannTransfer(ship:obt:semimajoraxis, ship:body:radius + tgtApo)[0].
		set settings["dV"] to dv.
	}
	
	return burn(settings).
}
