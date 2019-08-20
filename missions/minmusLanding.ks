@LazyGlobal off.

runOncePath("0:/lib/globals").

set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "Mun Landing".

	runOncePath("0:/lib/burn/burn").
	runOncePath("0:/lib/burn/executeNode").
	runOncePath("0:/lib/burn/changeSpeed").
	runOncePath("0:/lib/burn/setApoapsis").
	runOncePath("0:/lib/burn/circularize").
	runOncePath("0:/lib/landing/landing").
	runOncePath("0:/lib/launch/launch").
	runOncePath("0:/lib/maneuver/hohmannTransfer").
	runOncePath("0:/lib/misc/logger").
	runOncePath("0:/lib/misc/loopPrint").
	runOncePath("0:/lib/misc/smartWarp").
	runOncePath("0:/lib/obt/vec").
	runOncePath("0:/lib/ship/burnTime").
	runOncePath("0:/lib/ship/caPitch").
	runOncePath("0:/lib/ship/geopositionsAhead").
}.

local function doLaunch {
	parameter tgt.

	local settings is launchSettings().
	set settings["twr90deg"] to 2.
	set settings["twr60deg"] to 2.5.
	set settings["twr45deg"] to 3.
	set settings["twr0deg"] to -1.

	set settings["inclination"] to tgt:obt:inclination.
	set settings["LAN"] to tgt:obt:LAN.
	
	launch(settings).

	lock steering to normalVector().
	wait 10.
	stage.
}

local function doTransfer {
	parameter tgt.
	
	local tgtSMA is tgt:obt:apoapsis + tgt:body:radius.
	local dV is hohmannTransfer(ship:obt:semimajoraxis, tgtSMA)[0].
	local burnETA is hohmannTransferWindow(ship, tgt).
	
	if (burnETA < 60) {
		smartWarp(burnETA + 5, "trust me, it's necessary").
		set burnETA to hohmannTransferWindow(ship, tgt).
	}
	
	add Node(time:seconds + burnETA, 0, 0, dV).
	executeNode().
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
	
	local settings is burnSettings(
		burnVecFunction,
		{ return abs(ship:periapsis - tgtPeri) < 500. },
		{ return 0.1. },
		0
	).

	set settings["forceBurn"] to true.
	set settings["message"] to "correcting periapsis".

	burn(settings).
}

local function doChangeInclination {
	parameter tgtInc.

	local settings is burnSettings(
		normalVector@,
		{ return ship:obt:inclination > tgtInc. },
		{ return 0.1. },
		0
	).

	set settings["forceBurn"] to true.
	set settings["message"] to "changing inclination".

	burn(settings).
}

local function doCaptureBurn {
	circularize(ETA:periapsis).
}

local function doWaitForLandingSpot {
	parameter visited is List().	// visited biome names

	lock steering to -ship:velocity:surface.
	local stopTime is burnTime(ship:velocity:surface:mag).
	local stopTimeList is List(stopTime, 1.1 * stopTime, 1.2 * stopTime, 1.3 * stopTime).
	local sList is List().
	
	local aheadTime is 60.
	local prevTime is time:seconds.
	
	until (false) {
		sList:clear().
		for s in stopTimeList {
			sList:add(aheadTime + s).
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
		
		if (goodBiome) {
			smartWarp(aheadTime, "for landing spot").
			return.
		} else if (aheadTime > ship:obt:period) {
			logger("landing spot not found =(").
			print 1 / 0.
		} else {
			set aheadTime to aheadTime + 5.
		}
		
		if (time:seconds - prevTime > 0.5) {
			set prevTime to time:seconds.
			loopPrint(List(
				"stop time: " + round(stopTime, 2),
				"ahead sec: " + round(aheadTime, 2),
				"ahead %: " + (round(aheadTime / ship:obt:period, 2) * 100) + "%"
			)).
		}
	}
}

local function doLanding {
	parameter offset.
	
	local initialNormal is normalVector().
	
	local burnVecFunction is {
		local dirVec is vxcl(ship:body:position, -ship:velocity:surface):normalized.
		local pitchVec is -ship:body:position:normalized.
		local pitchMag is sin(caPitch(0, 0)).
		
		return dirVec + (pitchVec * pitchMag).
	}.
	local predicate is {
		if (vang(normalVector(), initialNormal) > 90) {
			// already flying in the wrong direction
			return true.
		}
		
		return vxcl(ship:body:position, ship:velocity:surface):mag < 2.
	}.
	
	local settings is burnSettings(
		burnVecFunction,
		predicate,
		{ return 1. },
		0
	).

	set settings["forceBurn"] to true.
	set settings["message"] to "killing horizontal velocity".

	burn(settings).
	
	wait until ship:verticalspeed < -3.
	landing(offset, 0, 0.9).
}

local function doCollectScience {
	toggle ag2.
}

set MISSION_SCRIPT["execute"] to {
	local tgt is Body("Minmus").

	doLaunch(tgt).
	doTransfer(tgt).
	doTransit(tgt).
	doChangeInclination(80).
	doCorrectPeriapsis(7000).
	doCaptureBurn().
	doWaitForLandingSpot(List("Midlands", "Lowlands")).
	doLanding(2).
	doCollectScience().
}.
