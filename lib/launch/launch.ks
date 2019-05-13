@LazyGlobal off.

import("burn/circularize").
import("launch/window").
import("misc/converter").
import("misc/logger").
import("misc/loopPrint").
import("misc/smartStage").
import("misc/smartWarp").
import("misc/vec").
import("ship/caPitch").


local settings is Lexicon().
launchSettings().

global function launchSettings {
	local settings0 is Lexicon().
	
	set settings0["suborbital"] to false.
	set settings0["boosterStage"] to -1.
	set settings0["boosterDropPeriapsis"] to 2e4.
	
	// ascent curve
	set settings0["alt90deg"] to 0.
	set settings0["alt60deg"] to 1e4.
	set settings0["alt45deg"] to 2e4.
	set settings0["alt0deg"] to 5e4.
	
	// orbital parameters
	set settings0["altitude"] to 8e4.
	set settings0["inclination"] to ship:obt:inclination.
	set settings0["LAN"] to ship:obt:LAN.
	
	// launch window
	set settings0["waitForLaunchWindow"] to false.
	set settings0["launchWindowAheadSec"] to 10.
	
	set settings to settings0.
	return settings.
}

local function printSettings {
	parameter indent is 4.
	
	local s is "".
	until (indent <= 0) {
		set s to s + " ".
		set indent to indent - 1.
	}
	
	logger(s + "Alt: " + round(settings["altitude"] / 1000, 2) + "km").
	logger(s + "Inc: " + round(settings["inclination"], 2)).
	logger(s + "LAN: " + round(settings["LAN"], 2)).
	logger(s + "90°: " + round(settings["alt90deg"] / 1000, 2) + "km").
	logger(s + "60°: " + round(settings["alt60deg"] / 1000, 2) + "km").
	logger(s + "45°: " + round(settings["alt45deg"] / 1000, 2) + "km").
	logger(s + "0° : " + round(settings["alt0deg"] / 1000, 2) + "km").
}

local function loopP {
	parameter printList is List().
	
	local aoa is vang(ship:velocity:surface, ship:facing:forevector).
	local etaApo is ETA:apoapsis.
	if (ETA:apoapsis > ETA:periapsis) {
		set etaApo to ETA:apoapsis - ship:obt:period.
	}
	
	printList:add("AoA:   " + round(aoa, 2) + "°").
	printList:add("Q:     " + round(ship:dynamicpressure, 2)).
	printList:add("Apoapsis(km): " + round(ship:apoapsis / 1e3, 2)).
	printList:add("ETA apoapsis: " + round(etaApo, 2)).
	
	loopPrint(printList).
}

global function launch {
	logger("launching from " + ship:body:name).
	logger("launch settings:").
	printSettings().
	
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
	local a90 is settings["alt90deg"].
	local a60 is settings["alt60deg"].
	local a45 is settings["alt45deg"].
	local a0  is settings["alt0deg"].
	
	local a60_90 is a60 - a90.
	local a45_60 is a45 - a60.
	local a0_45  is a0 - a45.

	local function getPitch {
		if (ship:altitude < a90) {
			return 90.
		} else if (ship:altitude < a60) {
			return 60 + 30 * (a60 - ship:altitude) / a60_90.
		} else if (ship:altitude < a45) {
			return 45 + 15 * (a45 - ship:altitude) / a45_60.
		} else {
			local tgtPitch is 0.
			if (ship:altitude < a0) {
				set tgtPitch to 45 * (a0 - ship:altitude) / a0_45.
			}
			
			return max(tgtPitch, caPitch()).
		}
	}	
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
	
	local tgtAlt is settings["altitude"].
	local tgtInc is settings["inclination"].
	local tgtLAN is settings["LAN"].
	
	local boosterStage is settings["boosterStage"].
	local boosterDropPeri is settings["boosterDropPeriapsis"].
	
	local incSin is sin(tgtInc).
	local tgtAzymuth is 0.
	
	local function getAzymuth {
		local obtLng to lngBodyToObt(ship:body, ship:longitude).
		local diff to mod(obtLng - tgtLAN + 360, 360).
		
		// spherical triangle, a = inc, b = 90°, c = diff
		set tgtAzymuth to arccos(incSin * cos(diff)).
		
		local horVec is vxcl(ship:body:position, ship:velocity:orbit).
		local tgtVec is Heading(tgtAzymuth, 0):forevector.
		set tgtVec:mag to 2 * horVec:mag.
		
		local corrVec is tgtVec - horVec.
		return azymuthOfVector(corrVec).
	}
	
	if (settings["waitForLaunchWindow"]) {
		local times is timeToLaunchWindow(ship:latitude, tgtInc, tgtLAN).
		local ahead is settings["launchWindowAheadSec"].
		
		local t1 is mod(times[0] - ahead + ship:body:rotationPeriod, ship:body:rotationPeriod).
		local t2 is mod(times[1] - ahead + ship:body:rotationPeriod, ship:body:rotationPeriod).
		
		smartWarp(min(t1, t2), "launch window", 5).
	}
	
	logger("ascending").
	local lock stAzymuth to getAzymuth().
	local lock stPitch to getPitch().
	lock steering to Heading(stAzymuth, stPitch).
	lock throttle to 1.
	
	until (ship:apoapsis > tgtAlt + 500) {
		// separate booster stage
		if (stage:number = boosterStage and ship:periapsis >= boosterDropPeri) {
			smartStage(true).
		}
		
		loopP(List(
			"Pitch:   " + round(stPitch, 2) + "°",
			"Azymuth (calc): " + round(tgtAzymuth, 2) + "°",
			"Azymuth (corr): " + round(stAzymuth, 2) + "°"
		)).
		smartStage().
		wait 0.
	}
	
	lock steering to ship:velocity:surface.
	logger("coasting from atmosphere").
	
	until (ship:altitude > ship:body:atm:height) {
		if (ship:apoapsis < tgtAlt) {
			lock throttle to 1.
		} else {
			lock throttle to 0.
		}
		
		loopP(List("Coasting from atmosphere")).
		smartStage().
		wait 0.
	}
	
	lock throttle to 0.
	toggle ag10.	// solar panels, antennas etc.
	
	// separate booster stage
	if (stage:number = boosterStage) {
		smartStage(true).
	}
	
	if (not settings["suborbital"]) {
		lock steering to ship:velocity:orbit.
		if (ETA:apoapsis < ETA:periapsis) {
			smartWarp(ETA:apoapsis - 5, "coasting to apoapsis", 5).
		}
		
		circularize().
	}
	
	local incErr is abs(ship:obt:inclination - tgtInc).
	local LANErr is abs(ship:obt:LAN - tgtLAN).
	local altErr is abs(ship:obt:apoapsis - tgtAlt).
	
	logger("launch completed:").
	logger("    Altitude error:    " + round(altErr / 1e3, 2) + "km").
	logger("    Inclination error: " + round(incErr, 2)).
	logger("    LAN error:         " + round(LANErr, 2)).
}
