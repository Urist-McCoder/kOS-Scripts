@LazyGlobal off.

import("burn/burn").
import("maneuver/hohmannTransfer").
import("misc/logger").


global function setPeriapsis {
	parameter tgtPeri.
	parameter throttleDownDiff.
	parameter burnEta is ETA:apoapsis.
	
	local ut is time:seconds + burnETA.
	local radVec is positionAt(ship, ut) - ship:body:position.
	local burnAlt is radVec:mag - ship:body:radius.
	
	if (tgtPeri > burnAlt) {
		logger("cannot set periapsis: too hihg (" + tgtPeri + " > " + burnAlt + ")").
		return false.
	}
	
	local settings is burnSettings().
	set settings["message"] to "changing periapsis".
	if (ship:obt:eccentricity < 0.01) {
		local dv is hohmannTransfer(
			ship:obt:semimajoraxis, ship:body:radius + tgtPeri
		)[0].
		set settings["dV"] to dv.
	}
	
	local f is 1.
	if (ship:periapsis > tgtPeri) {
		set f to -1.
	}
	
	local bV is burnVec@:bind(f).
	local sP is stopPr@:bind(tgtPeri, f).
	local tF is thrFunction@:bind(tgtPeri, throttleDownDiff).
	
	return burn(bV, sP, tF, ut).
}

local function burnVec {
	parameter f.
	
	return f * ship:velocity:orbit.
}

local function stopPr {
	parameter tgtPeri.
	parameter f.
	
	return (f * ship:periapsis) >= (f * tgtPeri).
}

local function thrFunction {
	parameter tgtPeri.
	parameter thrDown.
	
	return abs(ship:periapsis - tgtPeri) / thrDown.
}