@LazyGlobal off.

import("globals").


set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "Mun Fly-By".
	
	import("launch/launch").
	import("burn/executeNode").
	import("maneuver/hohmannTransfer").
	import("obt/vec").
}.

set MISSION_SCRIPT["execute"] to {
	local settings is launchSettings().
	set settings["boosterStage"] to 1.
	launch().
	
	local tgt is Body("Mun").
	local ht is hohmannTransfer(ship:obt:semimajoraxis, tgt:obt:semimajoraxis, ship:body:Mu).
	add Node(hohmannTransferWindow(ship, tgt, 0, true), 0, 0, ht[0]).
	executeNode().
	
	lock steering to normalVector().
	wait until (ship:body = tgt).
	
	lock steering to radialVector().
	wait 5.
	until (ship:periapsis > 15000) {
		lock throttle to 0.05.
		wait 0.
	}
	lock throttle to 0.
	toggle ag1.
	
	wait until (ship:altitude < 20000).
	toggle ag1.
	SAS on.
}.
