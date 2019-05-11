// a mission script for testing libraries
@LazyGlobal off.

import("globals").


set MISSION_SCRIPT["import"] to {
	set MISSION_NAME to "TEST".
	
	import("landing/landing").
}.

set MISSION_SCRIPT["execute"] to {
	lock STEERING to HEADING(90, 80).
	lock THROTTLE to 1.
	
	wait until ship:verticalSpeed > 100. lock THROTTLE to 0.
	wait until ship:verticalSpeed < -2. landing(1.85, 0, 1).
}.