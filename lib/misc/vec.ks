@LazyGlobal off.

global function azymuthOfVector {
	parameter p_vec.
	parameter p_orbitable is ship.
	parameter p_parentBody is ship:body.
	
	local radiusVector is p_orbitable:position - p_parentBody:position.
	local horVec is vxcl(radiusVector, p_vec).
	
	local nVec is p_orbitable:north:forevector.
	local eVec is vcrs(radiusVector, nVec):normalized.
	
	local ang is vang(horVec, nVec).
	if (vdot(horVec, eVec) < 0) {
		return 360 - ang.
	} else {
		return ang.
	}
}