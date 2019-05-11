@LazyGlobal off.

import("obt/vec").


// returns: List(dv1, dv2, dV_total)
global function hohmannTransfer {
	parameter r1 is ship:obt:semimajoraxis.		// from
	parameter r2 is target:obt:semimajoraxis.	// to
	parameter mu is ship:body:Mu.
	
	local dv1 is sqrt(mu / r1) * (sqrt(2 * r2 / (r1 + r2)) - 1).
	local dv2 is sqrt(mu / r2) * (1 - sqrt(2 * r1 / (r1 + r2))).
	
	return List(dv1, dv2, dv1 + dv2).
}

global function hohmannTransferWindow {
	parameter p_from is ship.
	parameter p_to is target.
	parameter offset is 0.
	parameter returnUT is false.
	parameter maxIncDifference is 2.
	
	if (p_from:body <> p_to:body) {
		// that's illegal, kill the whole script
		print 1 / 0.
	}
	
	local fromNorm is normalVector(p_from).
	local toNorm is normalVector(p_to).
	local incDiff is vang(fromNorm, toNorm).
	
	if (incDiff < maxIncDifference) {
		local wF is 360 / p_from:obt:period.
		local wT is 360 / p_to:obt:period.
		if (incDiff > 90) {
			set wT to -wT.
		}
		local w is wF - wT.
		
		local bodyVec is p_from:body:position.
		local vecF is p_from:position - bodyVec.
		local vecT is p_to:position - bodyVec.
		
		local angDiff is vang(vecF, vecT).
		if (p_from:velocity:orbit * vecT < 0) {
			set angDiff to 360 - angDiff.
		}
		
		if (w < 0) {
			set angDiff to 360 - angDiff.
			set w to -w.
		}
		
		local r1 is p_from:obt:semimajoraxis.
		local r2 is p_to:obt:semimajoraxis.
		local mu is p_from:body:Mu.
		local transferTime is constant:Pi * sqrt((r1 + r2)^3 / (8 * mu)).
		
		local tgtAngle is mod(mod(180 - transferTime * wT, 360) + 360, 360).
		local angleDiff is mod(angDiff - tgtAngle + 360, 360).
		
		print "wF:      " + wF.
		print "wT:      " + wT.
		print "w:       " + w.
		print "angDiff: " + angDiff.
		print "transT:  " + transferTime.
		print "tgtAng:  " + tgtAngle.
		print "angleD:  " + angleDiff.
		
		local result is abs(angleDiff / w).
		if (returnUT) {
			set result to time:seconds + result.
		}
		
		return result.
	} else {
		// TODO
		print "non complanar".
		return hohmannTransferWindow(p_from, p_to, offset, returnUT, 180).
	}
}
