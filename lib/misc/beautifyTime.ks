@LazyGlobal off.


global function beautifyTime {
	parameter p_time is time.
	
	local year   is p_time:year - 1.
	local day    is p_time:day - 1.
	local hour   is p_time:hour.
	local minute is p_time:minute.
	local second is p_time:second.
	local result is "".
	
	local year_flag is false.
	if (year > 0) {
		set result to year + " years, ".
		set year_flag to true.
	}
	if (year_flag or day > 0) {
		if (day < 100) {
			set result to result + " ".
		}
		if (day < 10) {
			set result to result + " ".
		}
		
		set result to result + day + " days, ".
	}
	
	if (hour < 10) {
		set result to result + "0".
	}
	set result to result + hour + ":".
	
	if (minute < 10) {
		set result to result + "0".
	}
	set result to result + minute + ":".
	
	if (second < 10) {
		set result to result + "0".
	}
	set result to result + second + "".
	
	return result.
}