class_name FormatUtils
extends Node

const SUFFIXES = ["", "K", "M", "B", "T", "q", "Q", "s", "S", "O", "N", "d"]

static func format_number(val: float) -> String:
	if val < 1000:
		return str(int(val))
	
	var exp = int(floor(log(val) / log(1000)))
	var suffix = SUFFIXES[min(exp, SUFFIXES.size() - 1)]
	var scaled = val / pow(1000, exp)
	
	if scaled >= 100:
		return "%.0f%s" % [scaled, suffix]
	elif scaled >= 10:
		return "%.1f%s" % [scaled, suffix]
	else:
		return "%.2f%s" % [scaled, suffix]

static func format_time(seconds: float) -> String:
	if seconds < 60:
		return "%.1fs" % seconds
	elif seconds < 3600:
		var mins = int(seconds / 60)
		var secs = int(seconds) % 60
		return "%dm %ds" % [mins, secs]
	else:
		var hrs = int(seconds / 3600)
		var mins = int(seconds / 60) % 60
		return "%dh %dm" % [hrs, mins]
