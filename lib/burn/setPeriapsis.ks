@LazyGlobal off.

runOncePath("0:/lib/burn/burn").
runOncePath("0:/lib/maneuver/hohmannTransfer").
runOncePath("0:/lib/misc/logger").

local function burnVec {
	parameter f.
	
	return f * ship:velocity:orbit.
}

local function stopPred {
	parameter tgtPeri.
	parameter f.
	
	return (f * ship:periapsis) >= (f * tgtPeri).
}

local function thrFunction {
	parameter tgtPeri.
	parameter thrDown.
	
	return abs(ship:periapsis - tgtPeri) / thrDown.
}

global function setPeriapsis {
	parameter tgtPeri.
	parameter throttleDownDiff.
	parameter burnEta is ETA:apoapsis.
	
	local ut is time:seconds + burnETA.
	local radVec is positionAt(ship, ut) - ship:body:position.
	local burnAlt is radVec:mag - ship:body:radius.
	
	if (tgtPeri > burnAlt) {
		logger("cannot set periapsis: too high (" + tgtPeri + " > " + burnAlt + ")").
		return false.
	}
	
	local f is 1.
	if (ship:periapsis > tgtPeri) {
		set f to -1.
	}
	
	local settings is burnSettings(
		 burnVec@:bind(f),
		 stopPred@:bind(tgtPeri, f),
		 thrFunction@:bind(tgtPeri, throttleDownDiff),
		 ut
	).

	set settings["message"] to "changing periapsis".

	if (ship:obt:eccentricity < 0.01) {
		local dv is hohmannTransfer(ship:obt:semimajoraxis, ship:body:radius + tgtPeri)[0].
		set settings["dV"] to dv.
	}
	
	return burn(settings).
}
