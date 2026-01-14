extends "res://scripts/core/skill.gd"

# We assume GameState is a global Autoload or accessible static
# If not, we might need to pass it, but RefCounted doesn't support convenient dependency injection 
# without custom init. We'll use the Autoload 'GameState'.

var is_active: bool = false
var current_action: Dictionary = {}
var current_action_id: String = ""
var action_progress: float = 0.0
var action_duration: float = 3.0

var events: Array = [] # Buffer for UI

var actions: Dictionary = {
	"gather_dirt": {
		"name": "Excavate Soil",
		"loot_table": [
			["Dirt", 1.0, 1, 3] # [Element, Chance, Min, Max]
		],
		"xp": 10,
		"level_req": 1,
		"research_req": null
	},
	"collect_water": {
		"name": "Pump Water",
		"loot_table": [
			["Water", 1.0, 1, 2]
		],
		"xp": 15,
		"level_req": 1,
		"research_req": "fluid_dynamics"
	},
	"gather_wood": {
		"name": "Deforest Zone",
		"loot_table": [
			["Wood", 0.8, 1, 2],
			["C", 0.1, 1, 1]
		],
		"xp": 20,
		"level_req": 3,
		"research_req": "combustion"
	},
	"harvest_nebula": {
		"name": "Harvest Nebula (Orbital)",
		"loot_table": [
			["H", 0.7, 1, 2],
			["He", 0.3, 1, 1]
		],
		"xp": 50,
		"level_req": 10,
		"research_req": null
	},
	"extract_salts": {
		"name": "Extract Planetary Salts",
		"loot_table": [
			["LithiumSalt", 1.0, 1, 3]
		],
		"xp": 30,
		"level_req": 5,
		"research_req": "basic_engineering"
	}
}

func _init():
	super._init("Planetary Operations")

func get_action_speed_multiplier(action_id: String) -> float:
	var multiplier = 1.0
	
	var upgrades = {
		"gather_dirt": "diamond_drills",
		"collect_water": "high_flow_pumps",
		"gather_wood": "laser_cutters",
		"harvest_nebula": "magnetic_funnels"
	}
	
	if action_id in upgrades:
		var tech_id = upgrades[action_id]
		# Access global GameState
		# if GameState.research_manager and GameState.research_manager.is_tech_unlocked(tech_id):
		#      multiplier = 1.25
		pass # TODO: Implement ResearchManager check
	
	return multiplier

func start_action(action_id: String):
	if action_id in actions:
		var action = actions[action_id]
		
		var lvl = get_level()
		var req = action.get("level_req", 1)
		
		if lvl < req:
			print("Level too low.")
			return
		
		# TODO: Check Research
		
		current_action = action
		current_action_id = action_id
		action_progress = 0.0
		is_active = true

func stop_action():
	is_active = false
	current_action = {}
	current_action_id = ""
	action_progress = 0.0

func reset():
	super.reset()
	stop_action()
	print("Gathering Reset.")

# Called by Engine
func process_tick(delta_time: float):
	if not is_active or current_action.is_empty():
		return

	action_progress += delta_time
	
	var speed_mult = get_action_speed_multiplier(current_action_id)
	var required_time = action_duration / speed_mult
	
	if action_progress >= required_time:
		complete_action()
		action_progress = 0.0

func complete_action():
	var loot_table = current_action["loot_table"]
	var xp_reward = current_action.get("xp", 0)
	
	var dropped_any = false
	for entry in loot_table:
		var element = entry[0]
		var chance = entry[1]
		var min_amt = entry[2]
		var max_amt = entry[3]
		
		if randf() < chance:
			var amount = randi_range(min_amt, max_amt)
			GameState.resources.add_element(element, amount)
			events.append(["loot", "+%d %s" % [amount, element], current_action_id])
			dropped_any = true
			
	if not dropped_any:
		var entry = loot_table[0]
		var element = entry[0]
		var min_amt = entry[2]
		var max_amt = entry[3]
		var amount = randi_range(min_amt, max_amt)
		GameState.resources.add_element(element, amount)
		events.append(["loot", "+%d %s" % [amount, element], current_action_id])
	
	add_xp(xp_reward)
	events.append(["xp", "+%d XP" % xp_reward, current_action_id])

func calculate_offline(delta: float):
	if not is_active or current_action.is_empty():
		return null
		
	var speed_mult = get_action_speed_multiplier(current_action_id)
	var effective_duration = action_duration / speed_mult
	
	var num_actions = int(delta / effective_duration)
	if num_actions <= 0: return null
	
	var loot_summary = {}
	var loot_table = current_action["loot_table"]
	var xp_per_action = current_action.get("xp", 0)
	
	var total_xp = num_actions * xp_per_action
	add_xp(total_xp)
	
	for i in range(num_actions):
		var dropped_any = false
		for entry in loot_table:
			var element = entry[0]
			var chance = entry[1]
			var min_amt = entry[2]
			var max_amt = entry[3]
			
			if randf() < chance:
				var amount = randi_range(min_amt, max_amt)
				GameState.resources.add_element(element, amount)
				loot_summary[element] = loot_summary.get(element, 0) + amount
				dropped_any = true
		
		if not dropped_any:
			var entry = loot_table[0]
			var element = entry[0]
			var min_amt = entry[2]
			var max_amt = entry[3]
			var amount = randi_range(min_amt, max_amt)
			GameState.resources.add_element(element, amount)
			loot_summary[element] = loot_summary.get(element, 0) + amount
	
	var report = "Off-World Operations (%s):\n" % current_action['name']
	report += "Time: %dm %ds\n" % [int(delta/60), int(delta) % 60]
	report += "Actions Completed: %d\n" % num_actions
	report += "XP Gained: %d\n" % total_xp
	report += "Loot Gathered:\n"
	
	for item in loot_summary:
		report += " - %s: %d\n" % [item, loot_summary[item]]
		
	return report

func get_save_data_manager() -> Dictionary:
	var data = get_save_data() # super
	data["is_active"] = is_active
	data["current_action_id"] = current_action_id
	return data

func load_save_data_manager(data: Dictionary):
	load_save_data(data) # super
	if data.is_empty(): return
	
	is_active = data.get("is_active", false)
	current_action_id = data.get("current_action_id", "")
	
	if is_active and not current_action_id.is_empty():
		if current_action_id in actions:
			current_action = actions[current_action_id]
		else:
			is_active = false
