@LazyGlobal off.

runOncePath("0:/lib/misc/logger").

local prevThrust is ship:availablethrust.
local prevTime is time:seconds.

local function stage0 {
	wait until (stage:ready).
	
	logger("stage #" + stage:number + " separated").
	stage.
	
	set prevTime to time:seconds.
	set prevThrust to ship:availablethrust.
}

global function smartStage {
	parameter forceStaging is false.
	
	if (forceStaging or ship:availablethrust = 0) {
		stage0().
	} else {
		if (time:seconds - prevTime < 1) {
			// 10 should be fine
			if (prevThrust - ship:availablethrust > 10) {
				// boosters burned out, should stage
				stage0().
			}
		} else {
			set prevTime to time:seconds.
			set prevThrust to ship:availablethrust.
		}
	}
}
