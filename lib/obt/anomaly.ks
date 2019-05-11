@LazyGlobal off.


global function taToMa {
	parameter taDeg.
	parameter ecc.
	
	local eaDeg is arctan2(sqrt(1 - ecc^2) * sin(taDeg), ecc + cos(taDeg)).
	local maRad is eaDeg * constant:DegToRad - ecc * sin(eaDeg).
	
	// convert to degrees to avoid confusion
	return mod(maRad * constant:RadToDeg + 360, 360).
}

global function timeFromPeToTa {
	parameter orbitable.
	parameter ta is orbitable:obt:trueAnomaly.
	
	local maDeg is taToMa(ta, orbitable:obt:eccentricity).
	local mu is orbitable:body:mu.
	local sma is orbitable:obt:semimajoraxis.
	
	return maDeg * constant:DegToRad / sqrt(mu / sma^3).
}

global function taToTime {
	parameter orbitable.
	parameter tgtTa.
	
	local orgTime is timeFromPeToTa(orbitable, orbitable:obt:trueAnomaly).
	local tgtTime is timeFromPeToTa(orbitable, tgtTa).
	local obtPeriod is orbitable:obt:period.
	
	return mod(tgtTime - orgTime + obtPeriod, obtPeriod).
}
