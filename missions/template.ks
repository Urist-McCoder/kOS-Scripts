// a template for mission scripts
@LazyGlobal off.

import("globals").


// imports go here
set MISSION_SCRIPT["import"] to {
	// set global variables
	set MISSION_NAME to "Template Mission Script".
	
	// import some libs
	import("misc/logger").
	
	// do some NON TIME-CONSUMING initialization
	logger(MISSION_NAME + " has started!").
	logger().
}.

// script goes here
set MISSION_SCRIPT["execute"] to {
	logger("if you see this on terminal screen, then:").
	logger("   a) you decided to test 'start.ks', and it's working").
	logger("   b) you forgot to pass a parameter").
}.