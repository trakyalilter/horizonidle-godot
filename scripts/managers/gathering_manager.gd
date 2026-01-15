extends "res://scripts/core/skill.gd"

# We assume GameState is a global Autoload or accessible static
# If not, we might need to pass it, but RefCounted doesn't support convenient dependency injection 
# without custom init. We'll use the Autoload 'GameState'.

var is_active: bool = false
var current_action: Dictionary = {}
var current_action_id: String = ""
var action_progress: float = 0.0
var action_duration: float = 4.0

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
			["Wood", 1.0, 1, 2]
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
		"name": "Extract Lithium Salt",
		"loot_table": [
			["Spodumene", 1.0, 1, 3]
		],
		"xp": 30,
		"level_req": 5,
		"research_req": "basic_engineering"
	},
	"mine_bauxite": {
		"name": "Strip Mine Bauxite",
		"loot_table": [
			["Bauxite", 1.0, 2, 4],
			["Fe", 0.3, 1, 2]  # Iron as byproduct
		],
		"xp": 25,
		"level_req": 4,
		"research_req": null
	},
	"mine_dolomite": {
		"name": "Quarry Dolomite",
		"loot_table": [
			["Dolomite", 1.0, 1, 3],
			["Dirt", 0.5, 1, 2]
		],
		"xp": 22,
		"level_req": 4,
		"research_req": null
	},
	"mine_cassiterite": {
		"name": "Mine Cassiterite (Tin Ore)",
		"loot_table": [
			["Cassiterite", 1.0, 1, 2]
		],
		"xp": 18,
		"level_req": 3,
		"research_req": null
	},
	"mine_zinc_ore": {
		"name": "Extract Zinc Ore",
		"loot_table": [
			["ZincOre", 1.0, 1, 3],
			["Si", 0.4, 1, 1]
		],
		"xp": 20,
		"level_req": 4,
		"research_req": null
	}
}

func _init():
	super._init("Planetary Operations")

func get_action_speed_multiplier(action_id: String) -> float:
	var multiplier = 1.0
	
	# Structure: action_id: [{tech_id: "xxx", bonus: 0.25}, ...]
	var upgrades_db = {
		"gather_dirt": [
			{"id": "diamond_drills", "bonus": 0.25},
			{"id": "ultrasonic_drills", "bonus": 0.50},
			{"id": "plasma_bore", "bonus": 0.75}
		],
		"collect_water": [
			{"id": "high_flow_pumps", "bonus": 0.25},
			{"id": "superfluid_intake", "bonus": 0.50},
			{"id": "hydro_vortex", "bonus": 0.75}
		],
		"gather_wood": [
			{"id": "laser_cutters", "bonus": 0.25},
			{"id": "mono_filament", "bonus": 0.50},
			{"id": "molecular_disassembler", "bonus": 0.75}
		],
		"harvest_nebula": [
			{"id": "magnetic_funnels", "bonus": 0.25}
		]
	}
	
	if action_id in upgrades_db:
		for upgrade in upgrades_db[action_id]:
			if GameState.research_manager and GameState.research_manager.is_tech_unlocked(upgrade["id"]):
				multiplier += upgrade["bonus"]
	
	return multiplier

func start_action(action_id: String):
	if action_id in actions:
		var action = actions[action_id]
		
		var lvl = get_level()
		var req = action.get("level_req", 1)
		
		if lvl < req:
			print("Level too low.")
			return
		
		# Research
		var res_req = action.get("research_req")
		if res_req and not GameState.research_manager.is_tech_unlocked(res_req):
			print("Research required: ", res_req)
			return
		
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
