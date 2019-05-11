// a mission script for testing libraries
@LazyGlobal off.

import("globals").


set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "TEST".
	
	import("misc/converter").
	import("launch/launch").
}.

set MISSION_SCRIPT["execute"] to {
	local settings is launchSettings().
	set settings["altitude"] to 1e5.
	set settings["inclination"] to 90.
	set settings["LAN"] to lngBodyToObt(ship:body, ship:longitude).
	
	launch().
}.