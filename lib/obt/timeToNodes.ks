@LazyGlobal off.

runOncePath("0:/lib/obt/vec").
runOncePath("0:/lib/obt/anomaly").

global function timeToNodes {
	parameter origin is ship.
	parameter tgtNormal is normalVector(target).
	parameter highestFirst is true.
	
	local orgNormal is normalVector(origin).
	local pVec is vcrs(tgtNormal, orgNormal).
	
	local bodyVec is origin:position - origin:body:position.
	local ahead is vang(bodyVec, pVec).
	
	if (pVec * origin:velocity:orbit < 0) {
		set ahead to 360 - ahead.
	}
	
	local ta1 is mod(origin:obt:trueAnomaly + ahead, 360).
	local ta2 is mod(ta1 + 180, 360).
	
	if (highestFirst) {
		// if ta1 is closer to periapsis than ta2, swap them
		if (ta1 < 90 or ta1 > 270) {
			local temp is ta1.
			set ta1 to ta2.
			set ta2 to temp.
		}
	}
	
	local t1 is taToTime(origin, ta1).
	local t2 is taToTime(origin, ta2).
	
	if (not highestFirst) {
		if (t1:seconds > t2:seconds) {
			local temp is t1.
			set t1 to t2.
			set t2 to temp.
		}
	}
	
	return List(t1, t2).
}