class_name Skill
extends RefCounted

var skill_name: String
var xp: float = 0.0
var level: int = 1
var max_level: int = 99
var xp_table: Dictionary = {}

# Signals for UI updates can be added here or in the manager
signal level_up(new_level)
signal xp_gained(amount)

func _init(p_name: String = "Skill"):
	skill_name = p_name
	xp_table = _generate_xp_table()

func _generate_xp_table() -> Dictionary:
	var table = {}
	var total_xp: float = 0.0
	# RuneScape XP Formula - Adjusted for steeper early game
	# Original diff / 4.0 was too fast for 1-hour loops.
	# Standardizing to require more actions for early milestones.
	for lvl in range(1, 121):
		table[lvl] = int(total_xp)
		if lvl < 120:
			# Steeper early game by adding a flat difficulty constant for first 20 levels
			var boost = 200.0 if lvl < 20 else 0.0
			var diff = int(floor(lvl + boost + 300.0 * pow(2.0, float(lvl) / 7.0)))
			total_xp += diff / 4.0
	return table

func get_xp_for_level(lvl: int) -> int:
	if lvl in xp_table:
		return xp_table[lvl]
	return 0

func get_level() -> int:
	return level

func add_xp(amount: float):
	xp += amount
	xp_gained.emit(amount)
	check_level_up()

func check_level_up():
	var next_level = level + 1
	if next_level in xp_table:
		var req_xp = xp_table[next_level]
		while xp >= req_xp:
			level += 1
			next_level += 1
			level_up.emit(level)
			if next_level > max_level:
				break
			if next_level in xp_table:
				req_xp = xp_table[next_level]

func get_progress_to_next_level() -> float:
	if level >= max_level:
		return 100.0
	
	var current_level_xp = xp_table[level]
	var next_level_xp = xp_table[level + 1]
	
	var needed = next_level_xp - current_level_xp
	var current = xp - current_level_xp
	
	if needed <= 0: return 100.0 # Should not happen based on formula
	
	return (current / float(needed)) * 100.0

func get_save_data() -> Dictionary:
	return {
		"xp": xp
	}

func load_save_data(data: Dictionary):
	if data.is_empty(): return
	xp = float(data.get("xp", 0.0))
	check_level_up()

func reset():
	xp = 0.0
	level = 1
	check_level_up()
