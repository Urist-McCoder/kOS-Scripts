@LazyGlobal off.

runOncePath("0:/lib/misc/converter").

// returns List(time_to_closest, time_to_other)
global function timeToLaunchWindow {
	parameter p_lat.
	parameter p_inc.
	parameter p_LAN.
	parameter p_orbitable is ship.
	
	local lat is abs(p_lat).
	local f is 1.
	
	if (p_inc > 90) {
		set p_inc to 180 - p_inc.
		set f to -1.
	}
	
	if (lat > p_inc) {
		set p_inc to lat + 0.01.	// a little margin for safety
	}
	
	local angFromLAN is arctan(lat / p_inc).
	local obtLng is lngBodyToObt(p_orbitable:body, p_orbitable:longitude).
	
	local angToLAN is mod(p_LAN - obtLng + 360, 360).
	local angToLDN is mod(angToLAN + 180, 360).
	
	local angToANLaunch is mod(angToLAN + f * angFromLAN + 360, 360).
	local angToDNLaunch is mod(angToLDN - f * angFromLAN + 360, 360).
	
	local secPerDeg is p_orbitable:body:rotationperiod / 360.
	local timeToANLaunch is angToANLaunch * secPerDeg.
	local timeToDNLaunch is angToDNLaunch * secPerDeg.
	
	local t1 is min(timeToANLaunch, timeToDNLaunch).
	local t2 is max(timeToANLaunch, timeToDNLaunch).
	
	return List(t1, t2).
}
