@LazyGlobal off.

runOncePath("0:/lib/misc/logger").

global function waitAG5 {
	parameter p_message is "".

	local display is "press 5 to continue".
	if (p_message <> "") {
		set display to display + ": " + p_message.
	}
	
	logger(display).
	
	set ag5 to false.
	until (ag5) {
		wait 0.
	}
}