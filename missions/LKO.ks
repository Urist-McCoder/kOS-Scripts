// mission to LKO
@LazyGlobal off.

import("globals").


// imports go here
set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "LKO".
	
	import("launch/launch").
}.

set MISSION_SCRIPT["execute"] to {
	local settings is launchSettings().
	launch().
}.