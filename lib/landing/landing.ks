@LazyGlobal off.

runOncePath("0:/lib/misc/logger").
runOncePath("0:/lib/misc/loopPrint").

global function getTrueAlt {
	parameter offset is 0.
	
	// in case of underwater surface
	return min(ALT:RADAR, ship:altitude) - offset.
}

global function landing {
	parameter altOffset.
	parameter minThrottle is 0.9.
	parameter targetThrottle is 0.95.
	
	local lock h to getTrueAlt(altOffset).
	local lock g to ship:body:Mu / (ship:body:radius + ship:altitude) ^ 2.
	local lock totalAcc to ship:availablethrust / ship:mass.
	local lock ang to vang((ship:position - ship:body:position), ship:facing:forevector).
	local lock vAcc to totalAcc * cos(ang) - g.
	local lock suicideBurnH to ship:verticalSpeed ^ 2 / (2 * vAcc).
	local lock thr to suicideBurnH / h.
	local lock ETL to -ship:verticalSpeed / vAcc.
	
	lock steering to -ship:velocity:surface.
	local burning is false.
	local haveBurned is false.
	
	logger("landing [minThrottle: " + minThrottle + "; targetThrottle: " + targetThrottle + "]").
	when (ship:status = "LANDED" or ship:status = "SPLASHED") then {
		logger("landed [vSpd: " + ship:verticalSpeed + "]").
	}
	when (haveBurned and ETL < 4) then {
		logger("deploying landing legs").
		LEGS on.
	}
	
	until (ship:verticalSpeed > -0.05 or ship:status = "LANDED" or ship:status = "SPLASHED") {
		if (ship:verticalSpeed > -1) {
			lock steering to -ship:body:position.
		}
		
		if (burning) {
			if (thr < minThrottle) {
				lock throttle to 0.
				set burning to false.
			}
		} else {
			if (thr >= targetThrottle) {
				lock throttle to thr.
				set burning to true.
				
				if (not haveBurned) {
					set haveBurned to true.
				}
			}
		}
		
		local thrStr is (100 * round(thr, 2)) + "%".
		if (thr < 10) {
			set thrStr to " " + thrStr.
		}
		if (thr < 100) {
			set thrStr to " " + thrStr.
		}
		
		loopPrint(List(
			"Altitude:  " + round(h),
			"Vert spd:  " + round(-ship:verticalSpeed, 2),
			"Throttle:  " + thrStr,
			"Est time:  " + round(ETL, 2)
		)).
		wait 0.
	}
	
	lock throttle to 0.
	lock steering to -ship:body:position.
}