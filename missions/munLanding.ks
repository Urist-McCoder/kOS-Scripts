@LazyGlobal off.

runOncePath("0:/lib/globals").

set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "Mun Landing".

	runOncePath("0:/lib/burn/executeNode").
	runOncePath("0:/lib/landing/landing").
	runOncePath("0:/lib/launch/launch").
	runOncePath("0:/lib/maneuver/hohmannTransfer").
	runOncePath("0:/lib/ship/geopositionsAhead").
	runOncePath("0:/lib/misc/waitAG5").
}.

local function doLaunchFromKerbin {
	local settings is launchSettings().

	set settings["twr90deg"] to 2.
	set settings["twr60deg"] to 2.5.
	set settings["twr45deg"] to 3.
	set settings["twr0deg"] to -1.
	set settings["boosterStage"] to 4.
	
	launch(settings).
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

local function doCaptureBurn {
	circularize(ETA:periapsis).
}

local function doWaitForLandingSpot {
	parameter visited is List().	// visited biome names

	lock steering to -ship:velocity:surface.
	local stopTime is burnTime(ship:velocity:surface:mag).

	local sList is List().
	local stopTimeList is List(
		0.90 * stopTime,
		0.95 * stopTime,
		1.00 * stopTime, 
		1.05 * stopTime, 
		1.10 * stopTime, 
		1.15 * stopTime,
		1.20 * stopTime,
		1.25 * stopTime,
		1.30 * stopTime
	).
	
	local aheadTime is 60.
	local prevTime is time:seconds.
	
	until (false) {
		sList:clear().
		for s in stopTimeList {
			sList:add(aheadTime + s).
		}
		
		local geoList is geopositionsAhead(sList).
		local goodBiome is true.
		local biome is "".
		
		for geo in geoList {
			// requires biome addon
			set biome to addons:biome:at(ship:body, geo).
			
			if (visited:contains(biome)) {
				set goodBiome to false.
				break.
			}
		}
		
		if (goodBiome) {
			smartWarp(aheadTime, "for landing spot (biome: " + biome + ")").
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
	landing(offset, 0.8, 0.9).
}

local function doLaunchFromMun {
	local settings is launchSettings().
	
	set settings["altitude"] to 10000.
	set settings["alt90deg"] to ship:altitude.
	set settings["alt60deg"] to ship:altitude + 100.
	set settings["alt45deg"] to ship:altitude + 500.
	set settings["alt0deg"] to ship:altitude + 1000.
	set settings["boosterStage"] to 3.

	launch(settings).
}

local function doEscapeBurn {
	waitAG5("execute maneuver").
	executeNode().
}

local function doLand {
	wait until ship:altitude < 75000.
	set kuniverse:timewarp:warp to 0.

	stage.
	lock steering to -ship:velocity:surface.
	wait until ship:altitude < 6000.
	stage.
}

set MISSION_SCRIPT["execute"] to {
	local tgt is Body("Mun").

	doLaunchFromKerbin().
	doTransfer(tgt).
	doTransit(tgt).
	doCorrectPeriapsis(7000).
	doCaptureBurn().
	doWaitForLandingSpot(List("Midlands")).
	doLanding(2.5).

	waitAG5("leave the Mun").
	// wait 5.

	doLaunchFromMun().
	doEscapeBurn().
	doTransit(Body("Kerbin")).
	doLand().
}.
