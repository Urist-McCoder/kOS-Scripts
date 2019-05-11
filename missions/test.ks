// a mission script for testing libraries
@LazyGlobal off.

import("globals").


set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "TEST".
	
	import("burn/setPeriapsis").
}.

set MISSION_SCRIPT["execute"] to {
	setPeriapsis(2e4, 1e4, 15).
}.