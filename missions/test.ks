// a mission script for testing libraries
@LazyGlobal off.

import("globals").


set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "TEST".
	
	import("burn/setPeriapsis").
	import("launch/launch").
	import("launch/window").
	import("landing/landing").
}.

set MISSION_SCRIPT["execute"] to {
	local tgt is Body("Minmus"):obt.
	
	local settings is launchSettings().
	set settings["inclination"] to tgt:inclination.
	set settings["LAN"] to tgt:LAN.
	set settings["waitForLaunchWindow"] to true.
	
	set settings["alt60deg"] to 2e4.
	set settings["alt45deg"] to 4e4.
	set settings["alt0deg"]  to 7e4.
	
	launch().
	stage.
	
	setPeriapsis(2e4, 1e4).
	lock steering to -ship:velocity:surface.
	
	wait until ship:altitude < 5000.
	landing(1.85, 0.95, 0.98).
}.