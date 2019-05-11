@LazyGlobal off.

local col is 5.
local row is 1.
local rowStep is 2.

global function loopPrint {
	parameter printList is List().
	
	clearscreen.
	local i is row.
	for item in printList {
		print item at(col, i).
		set i to i + rowStep.
	}
}