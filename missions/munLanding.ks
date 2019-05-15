@LazyGlobal off.

import("globals").


// imports go here
set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "Mun Landing".

	import("burn/burn").
	import("burn/changeSpeed").
	import("burn/setApoapsis").
	import("burn/circularize").
	import("landing/landing").
	import("launch/launch").
	import("maneuver/hohmannTransfer").
	import("misc/logger").
	import("misc/loopPrint").
	import("misc/smartWarp").
	import("obt/vec").
	import("ship/caPitch").
}.

local function doLaunch {
	local launchSettings is launchSettings().
	set launchSettings["twr90deg"] to 2.
	set launchSettings["twr60deg"] to 2.5.
	set launchSettings["twr45deg"] to 3.
	set launchSettings["twr0deg"] to -1.
	set launchSettings["boosterStage"] to 2.
	
	launch().
	stage.
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
	local flag is false.
	local tgtNormal is normalVector(ship:body).
	
	lock steering to normalVector().	
	until (flag) {
		local shipVec is ship:position - ship:body:position.
		local homeVec is ship:body:body:position - ship:body:position.
		
		local shipVecVxcl is vxcl(tgtNormal, shipVec).
		local homeVecVxcl is vxcl(tgtNormal, homeVec).
		
		local angRaw is vang(shipVec, homeVec).
		local angVxcl is vang(shipVecVxcl, homeVecVxcl).
		
		if (angVxcl < 5) {
			set flag to true.
		}
		
		loopPrint(List(
			"angle (raw):   " + round(angRaw, 2),
			"angle (vxcl):  " + round(angVxcl, 2)
		)).
		wait 0.
	}
}

local function doLanding {
	parameter offset.
	
	local initialNormal is normalVector().
	
	local burnVecFunction is {
		local dirVec is vxcl(ship:body:position, -ship:velocity:orbit):normalized.
		local pitchVec is -ship:body:position:normalized.
		local pitchMag is sin(caPitch()).
		
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
	doWaitForLandingSpot().
	doLanding(2).
	doCollectScience().
}.
