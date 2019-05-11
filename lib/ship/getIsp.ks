@LazyGlobal off.


global function getIsp {
	local engList is List().
	local totalC is 0.
	
	list engines in engList.
	for engine in engList {
		if (engine:ignition) {
			set totalC to totalC + engine:availablethrust / engine:isp.
		}
	}
	
	if (totalC = 0) {
		return 0.
	} else {
		return ship:availablethrust / totalC.
	}
}