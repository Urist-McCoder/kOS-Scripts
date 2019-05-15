@LazyGlobal off.

global function normalVector {
	parameter orbitable is ship.
	
	local obtVec is orbitable:velocity:orbit - orbitable:body:velocity:orbit.
	local radVec is orbitable:body:position - orbitable:position.
	
	return vcrs(radVec, obtVec):normalized.
}

global function radialVector {
	parameter orbitable is ship.
	
	return vcrs(normalVector(orbitable), orbitable:velocity:orbit):normalized.
}