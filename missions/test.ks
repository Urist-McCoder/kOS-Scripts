// a mission script for testing libraries
@LazyGlobal off.

runOncePath("0:/lib/globals").

set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "Mun Scan".

	runOncePath("0:/lib/burn/burn").
	runOncePath("0:/lib/burn/changeSpeed").
	runOncePath("0:/lib/burn/setApoapsis").
	runOncePath("0:/lib/burn/circularize").
	runOncePath("0:/lib/landing/landing").
	runOncePath("0:/lib/launch/launch").
	runOncePath("0:/lib/maneuver/hohmannTransfer").
	runOncePath("0:/lib/misc/beautifyTime").
	runOncePath("0:/lib/misc/logger").
	runOncePath("0:/lib/misc/loopPrint").
	runOncePath("0:/lib/misc/smartWarp").
	runOncePath("0:/lib/obt/vec").
	runOncePath("0:/lib/ship/caPitch").
	runOncePath("0:/lib/ship/geopositionsAhead").
}.

local function doLaunch {
	local launchSettings is launchSettings().
	set launchSettings["twr90deg"] to 2.
	set launchSettings["twr60deg"] to 2.5.
	set launchSettings["twr45deg"] to 3.
	set launchSettings["twr0deg"] to -1.
	
	launch().
}

local function doTransfer {
	parameter tgt.
	
	local tgtSMA is tgt:obt:semimajoraxis - 2 * tgt:radius.
	local dV is hohmannTransfer(ship:obt:semimajoraxis, tgtSMA)[0].
	local burnETA is hohmannTransferWindow(ship, tgt).
	
	if (burnETA < 60) {
		smartWarp(burnETA + 5, "trust me, it's necessary").
		set burnETA to hohmannTransferWindow(ship, tgt).
	}
	
	changeSpeed({return ship:velocity:orbit.}, dV, burnETA).
}

local function doTransit {
	parameter tgt.

	logger("waiting for SOI change").
	until (ship:body = tgt) {
		wait 10.
	}
}

local function doCorrectPeriapsis {
	parameter tgtPeri.
	
	local burnVecFunction is {
		if (ship:periapsis > tgtPeri) {
			return -radialVector().
		} else {
			return radialVector().
		}
	}.
	local predicate is {
		return abs(ship:periapsis - tgtPeri) < 500.
	}.
	local throttleFunction is {return 0.1.}.
	
	local settings is burnSettings().
	set settings["forceBurn"] to true.
	set settings["message"] to "correcting periapsis".
	burn(burnVecFunction, predicate, throttleFunction, 0).
}

local function doCaptureBurn {
	circularize(ETA:periapsis).
}

local function doWaitForLandingSpot {
	parameter visited is List().	// visited biome names
	parameter precision is 50.		// in meters

	lock steering to -ship:velocity:surface.

	local startSeconds is time:seconds.
	local lock duration to time:seconds - startSeconds.
	
	until (false) {
		local maxAcc is ship:availableThrust / ship:mass.
		
		if (maxAcc > 0) {
			local stopSec is ship:velocity:orbit:mag / maxAcc.
			local pStep is precision / ship:velocity:orbit:mag.
			
			local sList is List().
			from {local i is 0.5 * stopSec.} until (i > 2 * stopSec) step {set i to i + pStep.} do {
				sList:add(i).
			}
			
			local geoList is geopositionsAhead(sList).
			local goodBiome is true.
			
			for geo in geoList {
				// requires biome addon
				local biome is addons:biome:at(ship:body, geo).
				
				if (visited:contains(biome)) {
					set goodBiome to false.
					break.
				}
			}
			
			loopPrint(List(
				"waiting for landing spot", 
				"duration:  " + beautifyTime(time + (duration - time:seconds)),
				"stop sec: " + round(stopSec)
			)).
			
			if (goodBiome) {
				set kuniverse:timewarp:warp to 0.
				return.
			}
		}
		
		wait 1.
	}
}

local function doLanding {
	parameter offset.
	
	local initialNormal is normalVector().
	
	local burnVecFunction is {
		local dirVec is vxcl(ship:body:position, -ship:velocity:orbit):normalized.
		local pitchVec is -ship:body:position:normalized.
		local pitchMag is sin(caPitch(0, 0)).
		
		return dirVec + (pitchVec * pitchMag).
	}.
	local predicate is {
		if (vang(normalVector(), initialNormal) > 90) {
			// already flying in the wrong direction
			return true.
		}
		
		return vxcl(ship:body:position, ship:velocity:orbit):mag < 2.
	}.
	local throttleFunction is {return 1.}.
	
	local settings is burnSettings().
	set settings["forceBurn"] to true.
	set settings["message"] to "killing horizontal velocity".
	burn(burnVecFunction, predicate, throttleFunction, 0).
	
	wait until ship:verticalspeed < -10.
	landing(offset, 0, 0.9).
}

local function doCollectScience {
	toggle ag2.
}

// script goes here
set MISSION_SCRIPT["execute"] to {
	local tgt is Body("Mun").

	doLaunch().
	doTransfer(tgt).
	doTransit(tgt).	
	doCorrectPeriapsis(8000).
	doCaptureBurn().
	doWaitForLandingSpot(List("Midlands")).
	doLanding(2).
	doCollectScience().
}.
