@LazyGlobal off.

import("burn/burn").
import("maneuver/hohmannTransfer").
import("misc/logger").


local function burnVec {
	parameter f.
	
	return f * ship:velocity:orbit.
}

local function stopPr {
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
	
	local settings is burnSettings().
	set settings["message"] to "changing apoapsis".
	if (ship:obt:eccentricity < 0.01) {
		local dv is hohmannTransfer(ship:obt:semimajoraxis, ship:body:radius + tgtApo)[0].
		set settings["dV"] to dv.
	}
	
	local f is 1.
	if (ship:apoapsis > tgtApo) {
		set f to -1.
	}
	
	local bV is burnVec@:bind(f).
	local sP is stopPr@:bind(tgtApo, f).
	local tF is thrFunction@:bind(tgtApo, throttleDownDiff).
	
	return burn(bV, sP, tF, ut).
}
