@LazyGlobal off.

runOncePath("0:/lib/burn/burn").
runOncePath("0:/lib/ship/burnTime").

local function stop {
	parameter tgtBurnTime.
	parameter burnT.

	return burnT >= tgtBurnTime.
}

global function changeSpeed {
	parameter burnVecFunction.
	parameter dV.
	parameter burnETA.
	
	local tgtBurnTime is burnTime(dV).
	local burnVec is burnVecFunction.

	if (dV < 0) {
		set burnVec to { return -burnVecFunction(). }.
	}

	local settings is burnSettings(
		burnVec,
		stop@:bind(tgtBurnTime),
		{ return 1. },
		time:seconds + burnETA
	).

	set settings["stopParam"] to true.
	set settings["dV"] to dV.
	
	return burn(settings).
}