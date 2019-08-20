@LazyGlobal off.

runOncePath("0:/lib/globals").

set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "Tourist LKO".
	
	set ship:name to MISSION_NAME.
	
	runOncePath("0:/lib/burn/setPeriapsis").
	runOncePath("0:/lib/launch/launch").
	runOncePath("0:/lib/misc/logger").
	runOncePath("0:/lib/misc/smartWarp").
}.

set MISSION_SCRIPT["execute"] to {
	launch().		
	
	smartWarp(1 * 60 * 60, "contract completion").
	logger("deorbiting").
	setPeriapsis(2e4, 1e4, 15).
	
	stage.
	lock steering to -ship:velocity:surface.
	
	wait until (ALT:RADAR < 5000).
	stage.
	unlock steering.
	
	wait until (ALT:RADAR < 1000).
	stage.
}.