@LazyGlobal off.

global function loopPrint {
	parameter printList is List().
	
	clearscreen.
	local i is 1.
	
	for item in printList {
		print item at(5, i).
		set i to i + 2.
	}
}