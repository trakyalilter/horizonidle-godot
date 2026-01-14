extends "res://scripts/core/skill.gd"

var is_active: bool = false
var current_recipe: Dictionary = {}
var current_recipe_id: String = ""
var action_progress: float = 0.0

var events: Array = []

var recipes: Dictionary = {
	"electrolysis": {
		"name": "Water Electrolysis",
		"description": "Split Water into Hydrogen and Oxygen.",
		"input": {"Water": 1},
		"output": { "H": 2, "O": 1 },
		"duration": 2.0,
		"level_req": 2,
		"xp": 8,
		"research_req": "fluid_dynamics"
	},
	"centrifuge_dirt": {
		"name": "Soil Centrifuge",
		"description": "Spin Dirt to extract Silica and Iron.",
		"input": {"Dirt": 5},
		"output": { "Si": 3, "Fe": 1 }, 
		"duration": 3.0,
		"level_req": 1, 
		"xp": 5,
		"research_req": "basic_engineering"
	},
	"charcoal_burning": {
		"name": "Charcoal Kiln",
		"description": "Burn Wood to produce Carbon.",
		"input": { "Wood": 1 },
		"output": { "C": 1 },
		"duration": 4.0,
		"level_req": 3,
		"xp": 10
	},
	"smelt_steel": {
		"name": "Steel Foundry",
		"description": "Combine Iron and Carbon to produce Steel Ingots.",
		"input": { "Fe": 2, "C": 2 },
		"output": { "Steel": 1 },
		"duration": 5.0,
		"level_req": 4,
		"xp": 20,
		"research_req": "alloy_synthesis"
	},
	"press_graphite": {
		"name": "Graphite Press",
		"description": "Compress Carbon into high-density Graphite.",
		"input": { "C": 5 },
		"output": { "Graphite": 1 },
		"duration": 6.0,
		"level_req": 5,
		"xp": 25,
		"research_req": "adv_materials"
	},
	"analyze_artifact": {
		"name": "Analyze Void Artifact",
		"description": "Decipher the secrets of the artifact.",
		"input": { "VoidArtifact": 1 },
		# Dynamic Output
		"output_table": [
			["Scrap", 1.0, 1, 5],
			["Chip", 0.3, 1, 2],
			["NavData", 0.2, 1, 2],
			["AncientComponent", 0.05, 1, 1]
		],
		"duration": 10.0,
		"level_req": 5,
		"xp": 100,
		"research_req": "xeno_archaeology"
	},
	"craft_carbon_fiber": {
		"name": "Carbon Fiber",
		"description": "Reinforce Carbon strands.",
		"input": { "C": 3 },
		"output": { "Fiber": 1 },
		"duration": 5.0,
		"level_req": 2,
		"xp": 15
	},
	"craft_polymer": {
		"name": "Polymer Resin",
		"description": "Synthesize resin from hydrocarbons.",
		"input": { "C": 1, "H": 2, "O": 1 },
		"output": { "Resin": 1 },
		"duration": 5.0,
		"level_req": 2,
		"xp": 15
	},
	"craft_nanoweave": {
		"name": "Nanoweave Mesh",
		"description": "Weave fiber for shield repairs.",
		"input": { "Fiber": 2, "Si": 1 },
		"output": { "Mesh": 1 },
		"duration": 15.0,
		"level_req": 3,
		"xp": 30
	},
	"craft_sealant": {
		"name": "Hull Sealant",
		"description": "Mix polymer for rapid hull patching.",
		"input": { "Resin": 2, "Fe": 1 },
		"output": { "Seal": 1 },
		"duration": 15.0,
		"level_req": 3,
		"xp": 30
	},
	"craft_slug_t1": {
		"name": "Ferrite Rounds",
		"description": "Mass produce iron slugs.",
		"input": { "Fe": 2 },
		"output": { "SlugT1": 10 },
		"duration": 5.0,
		"level_req": 1,
		"xp": 10
	},
	"craft_cell_t1": {
		"name": "Focus Crystal",
		"description": "Cut silicate for lenses.",
		"input": { "Si": 2 },
		"output": { "CellT1": 10 },
		"duration": 5.0,
		"level_req": 1,
		"xp": 10
	},
	"craft_slug_t2": {
		"name": "Tungsten Sabot",
		"description": "Heavy kinetic penetrators.",
		"input": { "Steel": 2, "W": 1 },
		"output": { "SlugT2": 10 },
		"duration": 10.0,
		"level_req": 4,
		"xp": 20
	},
	"craft_cell_t2": {
		"name": "Plasma Cell",
		"description": "Contain superheated gas.",
		"input": { "H": 5, "Resin": 1 },
		"output": { "CellT2": 10 },
		"duration": 10.0,
		"level_req": 4,
		"xp": 20
	},
	"craft_slug_t3": {
		"name": "Depleted Uranium Round",
		"description": "Armor-shredding heavy rounds.",
		"input": { "SlugT2": 5, "U": 1 },
		"output": { "SlugT3": 5 },
		"duration": 15.0,
		"level_req": 8,
		"xp": 50,
		"research_req": "ballistics_optimization"
	},
	"craft_cell_t3": {
		"name": "Vaporizer Cell",
		"description": "Matter-disintegrating energy.",
		"input": { "CellT2": 5, "U": 1 },
		"output": { "CellT3": 5 },
		"duration": 15.0,
		"level_req": 8,
		"xp": 50,
		"research_req": "energy_metrics"
	},
	# Components
	"craft_glass": {
		"name": "Tempered Glass",
		"description": "Smelt Silica sand into reinforced glass.",
		"input": { "Si": 2 },
		"output": { "Glass": 1 },
		"duration": 5.0,
		"level_req": 2,
		"xp": 10
	},
	"craft_circuit": {
		"name": "Basic Circuitry",
		"description": "Solder Silicon and Copper.",
		"input": { "Si": 1, "Cu": 1 },
		"output": { "Circuit": 1 },
		"duration": 8.0,
		"level_req": 3,
		"xp": 25
	},
	"craft_hydraulics": {
		"name": "Hydraulic Servo",
		"description": "Precision machined actuator.",
		"input": { "Steel": 2, "Resin": 1 },
		"output": { "Hydraulics": 1 },
		"duration": 10.0,
		"level_req": 5,
		"xp": 40
	},
	# Lithium Chain
	"refine_lithium": {
		"name": "Refine Lithium",
		"description": "Purify Lithium Salts into reactive metal.",
		"input": { "LithiumSalt": 2 },
		"output": { "Li": 1 },
		"duration": 5.0,
		"level_req": 5,
		"xp": 20,
		"research_req": "basic_engineering"
	},
	"craft_battery_t1": {
		"name": "Lithium-Ion Battery",
		"description": "Basic energy storage for ships.",
		"input": { "Li": 5, "Steel": 2 },
		"output": { "BatteryT1": 1 },
		"duration": 10.0,
		"level_req": 5,
		"xp": 50
	},
	"craft_battery_t2": {
		"name": "Graphene Matrix Battery",
		"description": "Advanced high-density battery.",
		"input": { "BatteryT1": 1, "Graphite": 5, "Circuit": 5 },
		"output": { "BatteryT2": 1 },
		"duration": 20.0,
		"level_req": 15,
		"xp": 150,
		"research_req": "adv_materials"
	},
	"craft_battery_t3": {
		"name": "Zero-Point Module",
		"description": "Experimental infinite energy containment.",
		"input": { "BatteryT2": 1, "VoidArtifact": 1, "Circuit": 20 },
		"output": { "BatteryT3": 1 },
		"duration": 60.0,
		"level_req": 30,
		"xp": 500,
		"research_req": "quantum_dynamics"
	}
}

func _init():
	super._init("Engineering")

func get_recipe_speed_multiplier(recipe_id: String) -> float:
	var multiplier = 1.0
	var upgrades = {
		"centrifuge_dirt": "fast_centrifuges",
		"electrolysis": "catalytic_electrodes",
		"charcoal_burning": "pyrolysis_control",
		"smelt_steel": "blast_furnace",
		"press_graphite": "hydraulic_press"
	}
	
	if recipe_id in upgrades:
		var tech_id = upgrades[recipe_id]
		# TODO: Check Research
		pass
		
	# TODO: Check Infrastructure (count fabricator > 0)
	
	return multiplier

func start_action(action_id: String):
	if action_id in recipes:
		var recipe = recipes[action_id]
		
		# Levels
		if get_level() < recipe.get("level_req", 1):
			print("Level too low.")
			return
		
		# Research
		# if recipe.get("research_req") ...
		
		# Ingredients
		if not has_ingredients(recipe["input"]):
			print("Missing ingredients.")
			return
			
		current_recipe = recipe
		current_recipe_id = action_id
		action_progress = 0.0
		is_active = true

func stop_action():
	is_active = false
	current_recipe = {}
	current_recipe_id = ""
	action_progress = 0.0

func reset():
	super.reset()
	stop_action()
	print("Processing Reset.")

func process_tick(delta_time: float):
	if not is_active or current_recipe.is_empty():
		return
		
	action_progress += delta_time
	
	var speed_mult = get_recipe_speed_multiplier(current_recipe_id)
	var effective_duration = current_recipe["duration"] / speed_mult
	
	if action_progress >= effective_duration:
		complete_process()

func complete_process():
	# 1. Check ingredients again
	if not has_ingredients(current_recipe["input"]):
		stop_action()
		return
		
	# 2. Consume
	for item in current_recipe["input"]:
		var qty = current_recipe["input"][item]
		GameState.resources.remove_element(item, qty)
		
	# 3. Output
	if "output" in current_recipe:
		for item in current_recipe["output"]:
			var qty = current_recipe["output"][item]
			GameState.resources.add_element(item, qty)
			events.append(["loot", "+%d %s" % [qty, item], current_recipe_id])
			
	if "output_table" in current_recipe:
		for entry in current_recipe["output_table"]:
			var item = entry[0]
			var chance = entry[1]
			var min_q = entry[2]
			var max_q = entry[3]
			
			if randf() < chance:
				var qty = randi_range(min_q, max_q)
				GameState.resources.add_element(item, qty)
				if item == "AncientComponent":
					events.append(["xp", "JACKPOT! +%d %s" % [qty, item], current_recipe_id])
				else:
					events.append(["loot", "+%d %s" % [qty, item], current_recipe_id])
					
	# 4. XP
	add_xp(current_recipe.get("xp", 0))
	events.append(["xp", "+%d XP" % current_recipe.get("xp", 0), current_recipe_id])
	
	# 5. Loop
	action_progress = 0.0
	
	# Check for next cycle
	if not has_ingredients(current_recipe["input"]):
		stop_action()

func has_ingredients(inputs: Dictionary) -> bool:
	for item in inputs:
		var qty = inputs[item]
		if GameState.resources.get_element_amount(item) < qty:
			return false
	return true

func calculate_offline(delta: float):
	if not is_active or current_recipe.is_empty():
		return null
		
	var speed_mult = get_recipe_speed_multiplier(current_recipe_id)
	var effective_duration = current_recipe["duration"] / speed_mult
	
	var time_actions = int(delta / effective_duration)
	if time_actions <= 0: return null
	
	# Max based on inputs
	var input_reqs = current_recipe.get("input", {})
	var min_by_input = 99999999999.0
	
	var no_inputs = input_reqs.is_empty()
	
	if not no_inputs:
		for item in input_reqs:
			var qty = input_reqs[item]
			var avail = GameState.resources.get_element_amount(item)
			var possible = int(avail / qty)
			if possible < min_by_input:
				min_by_input = possible
	else:
		min_by_input = time_actions
		
	var actions = min(time_actions, int(min_by_input))
	
	if actions <= 0:
		return "Engineering (%s):\nStopped (Missing Resources)." % current_recipe['name']
		
	var loot_summary = {}
	var total_xp = actions * current_recipe.get("xp", 0)
	add_xp(total_xp)
	
	# Consume
	for item in input_reqs:
		var qty = input_reqs[item]
		GameState.resources.remove_element(item, qty * actions)
		
	# Produce
	if "output" in current_recipe:
		for item in current_recipe["output"]:
			var qty = current_recipe["output"][item]
			var total = qty * actions
			GameState.resources.add_element(item, total)
			loot_summary[item] = loot_summary.get(item, 0) + total
			
	if "output_table" in current_recipe:
		for i in range(actions):
			for entry in current_recipe["output_table"]:
				var item = entry[0]
				var chance = entry[1]
				var min_q = entry[2]
				var max_q = entry[3]
				
				if randf() < chance:
					var qty = randi_range(min_q, max_q)
					GameState.resources.add_element(item, qty)
					loot_summary[item] = loot_summary.get(item, 0) + qty

	var report = "Engineering (%s):\n" % current_recipe['name']
	report += "Time Adjusted: %dm\n" % int(delta/60)
	report += "Actions Completed: %d\n" % actions
	report += "XP Gained: %d\n" % total_xp
	report += "Produced:\n"
	
	for item in loot_summary:
		report += " + %s: %d\n" % [item, loot_summary[item]]
		
	return report

func get_save_data_manager() -> Dictionary:
	var data = get_save_data()
	data["is_active"] = is_active
	data["current_recipe_id"] = current_recipe_id
	return data

func load_save_data_manager(data: Dictionary):
	load_save_data(data)
	if data.is_empty(): return
	
	is_active = data.get("is_active", false)
	current_recipe_id = data.get("current_recipe_id", "")
	
	if is_active and not current_recipe_id.is_empty():
		if current_recipe_id in recipes:
			current_recipe = recipes[current_recipe_id]
		else:
			is_active = false
