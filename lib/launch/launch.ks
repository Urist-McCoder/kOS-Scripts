@LazyGlobal off.

runOncePath("0:/lib/burn/circularize").
runOncePath("0:/lib/launch/window").
runOncePath("0:/lib/misc/converter").
runOncePath("0:/lib/misc/logger").
runOncePath("0:/lib/misc/loopPrint").
runOncePath("0:/lib/misc/smartStage").
runOncePath("0:/lib/misc/smartWarp").
runOncePath("0:/lib/misc/vec").
runOncePath("0:/lib/ship/caPitch").

global function launchSettings {
	local settings is Lexicon().
	
	set settings["suborbital"] to false.
	set settings["boosterStage"] to -1.
	set settings["boosterDropPeriapsis"] to 2e4.
	set settings["useRCS"] to true.
	
	// ascent curve
	set settings["alt90deg"] to 0.
	set settings["alt60deg"] to 1e4.
	set settings["alt45deg"] to 2e4.
	set settings["alt0deg"] to 5e4.
	
	// TWR curve (-1 for no TWR limit)
	set settings["twr90deg"] to -1.
	set settings["twr60deg"] to -1.
	set settings["twr45deg"] to -1.
	set settings["twr0deg"] to -1.
	
	// orbital parameters
	set settings["altitude"] to 8e4.
	set settings["inclination"] to ship:obt:inclination.
	set settings["LAN"] to ship:obt:LAN.
	
	// launch window
	set settings["launchWindowAheadSec"] to 30.
	
	return settings.
}

local function printSettings {
	parameter settings.
	parameter indent is 4.
	
	local s is "".
	until (indent <= 0) {
		set s to s + " ".
		set indent to indent - 1.
	}
	
	logger(s + "Alt: " + round(settings["altitude"] / 1000, 2) + "km").
	logger(s + "Inc: " + round(settings["inclination"], 2)).
	logger(s + "LAN: " + round(settings["LAN"], 2)).
}

local function loopP {
	parameter printList is List().
	parameter showAoa is true.
	
	local aoa is vang(ship:velocity:surface, ship:facing:forevector).
	local etaApo is ETA:apoapsis.
	if (ETA:apoapsis > ETA:periapsis) {
		set etaApo to ETA:apoapsis - ship:obt:period.
	}
	
	if (showAoa) {
		printList:add("AoA: " + round(aoa, 2) + "°").
	}
	printList:add("Apoapsis(km): " + round(ship:apoapsis / 1e3, 2)).
	printList:add("ETA apoapsis: " + round(etaApo, 2)).
	
	loopPrint(printList).
}

global function launch {
	parameter settings.

	logger("launching from " + ship:body:name).
	logger("launch settings:").
	printSettings(settings).
	
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
	
	local twr90 is settings["twr90deg"].
	local twr60 is settings["twr60deg"].
	local twr45 is settings["twr45deg"].
	local twr0  is settings["twr0deg"].
	
	local function twrOf {
		parameter twr.
		parameter maxTwr.
		
		if (twr < 0) {
			return maxTwr.
		} else {
			return twr.
		}
	}
	
	local function getTwr {
		parameter maxTwr.
		
		local loTwr is maxTwr.
		local hiTwr is maxTwr.
		local f is 0.
		
		if (ship:altitude < a90) {
			return twrOf(twr90, maxTwr).
		} else if (ship:altitude < a60) {
			set f to (ship:altitude - a90) / a60_90.
		
			if (twr90 > 0) {
				set loTwr to twr90.
			}
			if (twr60 > 0) {
				set hiTwr to twr60.
			}
		} else if (ship:altitude < a45) {
			set f to (ship:altitude - a60) / a45_60.
		
			if (twr60 > 0) {
				set loTwr to twr60.
			}
			if (twr45 > 0) {
				set hiTwr to twr45.
			}
		} else if (ship:altitude < a0) {
			set f to (ship:altitude - a45) / a0_45.
		
			if (twr45 > 0) {
				set loTwr to twr45.
			}
			if (twr0 > 0) {
				set hiTwr to twr0.
			}
		} else {
			return twrOf(twr0, maxTwr).
		}
		
		local twrDiff is hiTwr - loTwr.
		return twrOf(loTwr + f * twrDiff, maxTwr).
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
		local obtLng is lngBodyToObt(ship:body, ship:longitude).
		local diff is mod(obtLng - tgtLAN + 360, 360).
		
		// spherical triangle, alpha = inc, beta = 90°, C = diff
		set tgtAzymuth to arccos(incSin * cos(diff)).
		if (tgtInc > 90) {
			set tgtAzymuth to 360 - tgtAzymuth.
		}
		
		local horVec is vxcl(ship:body:position, ship:velocity:orbit).
		local tgtVec is Heading(tgtAzymuth, 0):forevector.
		set tgtVec:mag to 2 * horVec:mag.
		
		local corrVec is tgtVec - horVec.
		return azymuthOfVector(corrVec).
	}
	
	local incDiff is abs(ship:obt:inclination - tgtInc).
	local lanDiff is abs(ship:obt:LAN - tgtLAN).

	if (incDiff > 1 or lanDiff > 1) {
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
	
	local lock g to ship:body:mu / (ship:body:position - ship:position):mag^2.
	local lock maxTwr to ship:availablethrust / (g * ship:mass).
	local lock tgtTwr to getTwr(maxTwr).
	local thrFunction is {
		if (ship:availablethrust > 0) {
			return min(1, max(0, tgtTwr / maxTwr)).
		} else {
			return 1.
		}
	}.
	lock throttle to thrFunction().
	
	until (ship:apoapsis >= tgtAlt) {
		// separate booster stage
		if (stage:number = boosterStage and ship:periapsis >= boosterDropPeri) {
			smartStage(true).
		}
		
		loopP(List(
			"Pitch:   " + round(stPitch, 2) + "°",
			"Azymuth (calc): " + round(tgtAzymuth, 2) + "°",
			"Azymuth (corr): " + round(stAzymuth, 2) + "°",
			"TWR: " + round(tgtTwr, 2)
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
	
	if (settings["suborbital"]) {
		// separate booster stage
		if (stage:number = boosterStage) {
			smartStage(true).
		}
	} else {
		if (settings["useRCS"]) {
			RCS on.
		}
		
		lock steering to ship:velocity:orbit.
		if (ETA:apoapsis < ETA:periapsis) {
			smartWarp(ETA:apoapsis - 5, "coasting to apoapsis", 5).
		}
		
		// CA burn
		lock throttle to 1.
		local tgtPeri is max(0, min(tgtAlt, boosterDropPeri - 500)).
		until (ship:periapsis >= tgtPeri) {
			local maxAcc is ship:availablethrust / ship:mass.
		
			if (maxAcc > 0) {
				local altDiff is tgtAlt - ship:altitude.
				local maxVAcc is maxAcc / 2.
				local maxVSpeed is maxVAcc * 2.
				local tgtVSpeed is min(maxVSpeed, max(-maxVSpeed, altDiff / 10)).
				
				local az is azymuthOfVector(ship:velocity:orbit).
				local pt is caPitch(tgtVSpeed, -90, 90, maxVAcc).
				
				lock steering to Heading(az, pt).
				
				loopP(List(
					"maxAcc:    " + round(maxAcc, 2),
					"maxVAcc:   " + round(maxVAcc, 2),
					"maxVSpeed: " + round(maxVSpeed, 2),
					"tgtVSpeed: " + round(tgtVSpeed, 2),
					"actVSpeed: " + round(ship:verticalspeed, 2),
					"CA pitch:  " + round(pt, 2)
				), false).
			}
			
			smartStage().
			wait 0.
		}
		lock throttle to 0.
		
		// separate booster stage
		if (stage:number = boosterStage) {
			smartStage(true).
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
