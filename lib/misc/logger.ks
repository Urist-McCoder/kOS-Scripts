@LazyGlobal off.

runOncePath("0:/lib/globals").

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
	parameter p_echo is true.
	parameter p_target is MISSION_NAME.
	
	set p_message to lineNum + ".  " + p_message.
	if (lineNum < 100) set p_message to " " + p_message.
	if (lineNum < 10) set p_message to " " + p_message.
	
	set lineNum to lineNum + 1.
	set p_target to p_target + ".log".

	log p_message to p_target.

	if (p_echo) {
		print p_message.
	}
}