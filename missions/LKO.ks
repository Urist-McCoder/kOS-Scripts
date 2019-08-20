// mission to LKO
@LazyGlobal off.

runOncePath("0:/lib/globals").

set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "LKO".
	
	runOncePath("0:/lib/launch/launch").
}.

set MISSION_SCRIPT["execute"] to {
	launchSettings().
	launch().
}.