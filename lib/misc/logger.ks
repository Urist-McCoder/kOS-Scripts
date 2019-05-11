@LazyGlobal off.

import("globals").


if (CLEAR_PREV_LOGS) {
	local itemList is List().
	list files in itemList.
			
	for item in itemList {
		if (item:isFile and item:extension = "log") {
			deletepath(item).
		}
	}
}

local lineNum is 1.

global function logger {
	parameter p_message is "".
	parameter p_consoleEcho is true.
	parameter p_target is MISSION_NAME.
	
	set p_message to lineNum + ".  " + p_message.
	if (lineNum < 100) set p_message to " " + p_message.
	if (lineNum < 10) set p_message to " " + p_message.
	
	set lineNum to lineNum + 1.
	log p_message to (p_target + ".log").
	
	if (p_consoleEcho) {
		print p_message.
	}
}