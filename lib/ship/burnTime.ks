@LazyGlobal off.

runOncePath("0:/lib/ship/getIsp").

global function burnTime {
	parameter dV.
	
	if (dV > 0) {
		set dV to -dV.
	}
	local gIsp is constant:g0 * getIsp().
	
	return gIsp * ship:mass * (1 - constant:e^(dV / gIsp)) / ship:availablethrust.
}