@LazyGlobal off.
clearscreen.


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// important global function import()
{
	local imported is List().
	
	global function import {
		parameter filePath is "".
		parameter isLib is true.
		
		if (isLib) {
			set filePath to "lib/" + filePath.
		}
		
		if (not imported:contains(filePath)) {
			if (not exists(filePath + ".ks")) {
				copypath("0:/" + filePath + ".ks", "").
			}
			
			runpathonce(filePath).
			imported:add(filePath).
		}
	}
}