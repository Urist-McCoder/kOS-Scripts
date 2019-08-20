@LazyGlobal off.

runOncePath("0:/lib/misc/beautifyTime").
runOncePath("0:/lib/misc/logger").
runOncePath("0:/lib/misc/loopPrint").

local timeWarp is kuniverse:timeWarp.
local warpRates is timeWarp:railsRateList.

local function limitWarp {
	parameter p_seconds.
	parameter margin.
	
	local warpLevel is 1.
	local flag is false.
	
	until (flag) {
		if (warpLevel < warpRates:length) {
			if (warpRates[warpLevel] < p_seconds - margin) {
				set warpLevel to warpLevel + 1.
			} else {
				set flag to true.
			}
		} else {
			set flag to true.
		}
	}
	
	set warpLevel to warpLevel - 1.
	if (timeWarp:warp > warpLevel) {
		set timeWarp:warp to warpLevel.
	}
}

global function smartWarp {
	parameter p_seconds is 0.
	parameter p_message is "�".
	parameter margin is 1.
	
	// remember when to stop waiting
	local endTime is time + p_seconds.
	local lock timeLeft to endTime - time:seconds.
	
	if (timeLeft:seconds >= 1) {
		logger("waiting for " + beautifyTime(timeLeft) +", reason: " + p_message).
	}
	
	// modify p_message for displaying
	set p_message to "WAITING:    " + p_message.
	
	until (timeLeft:seconds < 0.05) {	// approx 1 game tick
		limitWarp(timeLeft:seconds, margin).
		
		loopPrint(List(
			p_message,
			"TIME LEFT:  " + beautifyTime(timeLeft)
		)).
		wait 0.
	}
	
	clearscreen.
}