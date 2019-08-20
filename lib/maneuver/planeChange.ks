@LazyGlobal off.

runOncePath("0:/lib/misc/converter").
runOncePath("0:/lib/obt/vec").
runOncePath("0:/lib/obt/timeToNodes").

local settings is Lexicon().
planeChangeSettings().

global function planeChangeSettings {
	local settings0 is Lexicon().
	
	set settings0["speedChange"] to 0.
	set settings0["highestFirst"] to true.
	
	set settings to settings0.
	return settings0.
}

// returns: List(burnVector1, timeOfBurn1, burnVector2, timeOfBurn2)
global function planeChange {
	parameter origin is ship.
	parameter tgtInc is target:obt:inclination.
	parameter tgtLAN is target:obt:LAN.
	
	local time0 is time.
	local tgtNormal is getNormal(tgtInc, tgtLAN, origin:body).
	local nodeTimes is timeToNodes(origin, tgtNormal, settings["highestFirst"]).
	
	local nodeTime1 is time0 + nodeTimes[0].
	local nodeTime2 is time0 + nodeTimes[1].
	
	local corrVec1 is calculateVec(origin, tgtNormal, nodeTime1).
	local corrVec2 is calculateVec(origin, tgtNormal, nodeTime2).
	
	return List(corrVec1, nodeTime1, corrVec2, nodeTime2).
}

local function calculateVec {
	parameter origin.
	parameter tgtNormal.
	parameter ut.
	
	local orgVec is velocityAt(origin, ut):orbit.
	local bodyVec is origin:body:position - positionAt(origin, ut).
	local tgtVec is vcrs(tgtNormal, bodyVec).
	set tgtVec:mag to orgVec:mag + settings["speedChange"].
	
	return tgtVec - orgVec.
}

local function getNormal {
	parameter p_inc.
	parameter p_LAN.
	parameter p_body.
	
	local bodyLng is lngObtToBody(p_body, p_LAN).
	local lat is sin(p_inc).
	local lng is mod(bodyLng + cos(p_inc) + 180, 360) - 180.
	 
	local vec1 is p_body:geopositionLatLng(0, bodyLng):position.
	local vec2 is p_body:geopositionLatLng(lat, lng):position.
	local progVec is vec2 - vec1.
	local bodyVec is vec1 - p_body:position.	
	
	return vcrs(progVec, bodyVec):normalized.
}
