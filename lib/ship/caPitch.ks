@LazyGlobal off.


local prevPitch is 0.

global function caPitch {
	parameter tgtVertSpd is 0.
	parameter maxVertAcc is 5.
	parameter vecAccKP is 5.
	
	local thr is ship:availablethrust.
	if (thr > 0) {
		local radVec is (ship:position - ship:body:position).
		local v2 is vxcl(radVec, ship:velocity:orbit):sqrmagnitude.
		local obtAcc is v2 / radVec:mag.
		local gAcc is ship:body:Mu / radVec:mag^2.
		
		local totalAcc is thr / ship:mass.
		local tgtAcc is gAcc - obtAcc.
		local vSpdAcc is (tgtVertSpd - ship:verticalSpeed) / vecAccKP.
		set vSpdAcc to min(maxVertAcc, max(-maxVertAcc, vSpdAcc)).
		set tgtAcc to tgtAcc + vSpdAcc.
		
		local tgtPitch is arctan2(tgtAcc, totalAcc).
		set prevPitch to tgtPitch.
		return tgtPitch.
	} else {
		return prevPitch.
	}
}