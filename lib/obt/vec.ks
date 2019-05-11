@LazyGlobal off.

global function normalVector {
	parameter orbitable is ship.
	
	local obtVec is orbitable:velocity:orbit.
	local radVec is orbitable:body:position - orbitable:position.
	
	return -vcrs(obtVec, radVec):normalized.
}

global function radialVector {
	parameter orbitable is ship.
	
	return -vcrs(orbitable:velocity:orbit, normalVector(orbitable)):normalized.
}