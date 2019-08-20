@LazyGLobal off.

runOncePath("0:/lib/misc/converter").

// takes:   List of scalars (seconds)
// returns: List of GeoCoordinates (result[i] is the point below ship at now + aheadSeconds[i])
global function geopositionsAhead {
	parameter aheadSeconds is List().
	
	local shipObtLng is lngBodyToObt(ship:body, ship:longitude).
	local diff is 0.
	if (ship:obt:inclination > 90) {
		set diff to ship:obt:LAN - shipObtLng. 
	} else {
		set diff to shipObtLng - ship:obt:LAN.
	}
	
	local fromLAN is mod(diff + 360, 360).
	local arc is arccos(cos(ship:latitude) * cos(fromLAN)).
	
	local moreThanHalf is fromLAN > 180.
	if (moreThanHalf) {
		set arc to 360 - arc.
	}
	
	local incSin is sin(ship:obt:inclination).
	local obtDegPerSec is 360 / ship:obt:period.
	local bodyDegPerSec is 360 / ship:body:rotationPeriod.
	local topSin is sin((90 + ship:obt:inclination) / 2).
	local botSin is sin((90 - ship:obt:inclination) / 2).
	local sinOverSin is topSin / botSin.
	
	local result is List().
	for s in aheadSeconds {
		local newArc is mod(arc + s * obtDegPerSec, 360).
		local lat is arcsin(sin(newArc) * incSin).
		
		local angleFromLAN is 2 * arctan(tan((newArc - lat) / 2) * sinOverSin).
		local rotationAng is s * bodyDegPerSec.
		local obtLng is mod(ship:obt:LAN + angleFromLAN - rotationAng + 360, 360).
		local lng is lngObtToBody(ship:body, obtLng).
		
		result:add(LatLng(lat, lng)).
	}
	
	return result.
}
