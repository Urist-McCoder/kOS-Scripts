@LazyGlobal off.

runOncePath("0:/lib/burn/burn").
runOncePath("0:/lib/ship/burnTime").

global function changeSpeed {
	parameter burnVecFunction.
	parameter dV.
	parameter burnETA.
	
	local settings is burnSettings().
	set settings["stopParam"] to true.
	set settings["dV"] to dV.
	
	local tgtBurnTime is burnTime(dV).
	
	local burnVec is {return burnVecFunction().}.
	local stopPred is {parameter burnT. return burnT >= tgtBurnTime.}.
	local thrFunc is {return 1.}.
	
	if (dV < 0) {
		set burnVec to {return -burnVecFunction().}.
	}
	
	print stopPred(2).
	return burn(burnVec, stopPred, thrFunc, time:seconds + burnETA).
}