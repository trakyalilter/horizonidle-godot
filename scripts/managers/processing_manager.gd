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
		"name": "Mineral Washing",
		"description": "Wash Dirt with Water to extract Iron more efficiently.",
		"input": {"Dirt": 5, "Water": 5},
		"output": { "Fe": 3, "Si": 1 }, 
		"duration": 3.0,
		"level_req": 1, 
		"xp": 8,
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
		"name": "Oxygen-Enriched Smelting",
		"description": "Use Oxygen to blast smelt Steel efficiently.",
		"input": { "Fe": 2, "C": 1, "O": 2 },
		"output": { "Steel": 2 },
		"duration": 4.0,
		"level_req": 4,
		"xp": 30,
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
		"description": "Extract Lithium from Spodumene crystals.",
		"input": { "Spodumene": 2 },
		"output": { "Li": 1 },
		"duration": 5.0,
		"level_req": 5,
		"xp": 20,
		"research_req": "basic_engineering"
	},
	# Germanium / Advanced Electronics
	"extract_germanium": {
		"name": "Fly Ash Separation",
		"description": "Extract trace Germanium from Carbon ash.",
		"input": { "C": 10 },
		"output": { "Ge": 1 },
		"duration": 8.0,
		"level_req": 5,
		"xp": 25,
		"research_req": "combustion"
	},
	"craft_semiconductor": {
		"name": "Semiconductor Wafer",
		"description": "Dope Silicon with Germanium for conductivity.",
		"input": { "Si": 2, "Ge": 1 },
		"output": { "Semiconductor": 1 },
		"duration": 10.0,
		"level_req": 6,
		"xp": 35,
		"research_req": "adv_materials"
	},
	"refine_gold": {
		"name": "Gold Panning",
		"description": "Sift large amounts of dirt for Gold flakes.",
		"input": { "Dirt": 20, "Water": 20 },
		"output": { "Au": 1 },
		"duration": 12.0,
		"level_req": 6,
		"xp": 30,
		"research_req": "basic_engineering"
	},
	"gold_leaching": {
		"name": "Chemical Leaching",
		"description": "Dissolve gold from soil using chemical solvents.",
		"input": { "Dirt": 50, "Water": 10, "H": 5 },
		"output": { "Au": 5 },
		"duration": 20.0,
		"level_req": 15,
		"xp": 100,
		"research_req": "industrial_electrolysis"
	},
	"craft_adv_circuit": {
		"name": "Advanced Circuitry",
		"description": "High-performance integrated circuit.",
		"input": { "Semiconductor": 1, "Au": 1 },
		"output": { "AdvCircuit": 1 },
		"duration": 15.0,
		"level_req": 8,
		"xp": 50,
		"research_req": "automation"
	},
	"craft_battery_t1": {
		"name": "Lithium-Ion Battery",
		"description": "Basic energy storage for ships.",
		"input": { "Li": 5, "Fe": 2 },
		"output": { "BatteryT1": 1 },
		"duration": 10.0,
		"level_req": 10,
		"xp": 50
	},
	"craft_battery_t2": {
		"name": "Graphene Matrix Battery",
		"description": "Advanced high-density battery.",
		"input": { "BatteryT1": 1, "Graphite": 5, "AdvCircuit": 5 },
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
	},
	# Early Game Element Processing
	"smelt_bauxite": {
		"name": "Bauxite Smelting",
		"description": "Extract Aluminum from Bauxite ore using oxygen.",
		"input": { "Bauxite": 3, "O": 2 },
		"output": { "Al": 2 },
		"duration": 5.0,
		"level_req": 4,
		"xp": 20,
		"research_req": "basic_engineering"
	},
	"process_dolomite": {
		"name": "Dolomite Calcination",
		"description": "Extract Magnesium from Dolomite through heating.",
		"input": { "Dolomite": 4, "C": 1 },
		"output": { "Mg": 1, "C": 1 },  # C is returned as CO2 → C cycle
		"duration": 6.0,
		"level_req": 4,
		"xp": 25,
		"research_req": "combustion"
	},
	"smelt_cassiterite": {
		"name": "Tin Smelting",
		"description": "Reduce Cassiterite ore to pure Tin.",
		"input": { "Cassiterite": 2, "C": 1 },
		"output": { "Sn": 1 },
		"duration": 4.0,
		"level_req": 3,
		"xp": 15
	},
	"smelt_zinc": {
		"name": "Zinc Reduction",
		"description": "Extract Zinc from ore via carbon reduction.",
		"input": { "ZincOre": 3, "C": 1 },
		"output": { "Zn": 2 },
		"duration": 4.0,
		"level_req": 4,
		"xp": 18
	},
	"craft_bronze": {
		"name": "Bronze Alloy",
		"description": "Ancient but effective Cu-Tin alloy. Cheaper than Steel.",
		"input": { "Cu": 3, "Sn": 1 },
		"output": { "Bronze": 2 },
		"duration": 3.0,
		"level_req": 3,
		"xp": 20
	},
	"craft_aluminum_alloy": {
		"name": "Aluminum-Magnesium Alloy",
		"description": "Lightweight aerospace alloy. High strength-to-weight ratio.",
		"input": { "Al": 3, "Mg": 1 },
		"output": { "AlMgAlloy": 2 },
		"duration": 5.0,
		"level_req": 5,
		"xp": 30,
		"research_req": "adv_materials"
	},
	"craft_al_wire": {
		"name": "Aluminum Wiring",
		"description": "Insulated aluminum wire for electrical systems.",
		"input": { "Al": 2, "Resin": 1 },
		"output": { "AlWire": 3 },
		"duration": 3.0,
		"level_req": 4,
		"xp": 15
	},
	"galvanize_steel": {
		"name": "Galvanized Steel",
		"description": "Zinc-coated steel. Corrosion resistant.",
		"input": { "Steel": 2, "Zn": 1 },
		"output": { "GalvanizedSteel": 2 },
		"duration": 4.0,
		"level_req": 5,
		"xp": 25,
		"research_req": "alloy_synthesis"
	},
	# Mid-Game Advanced Materials
	"craft_stainless_steel": {
		"name": "Stainless Steel Alloy",
		"description": "Fe-Cr-Ni alloy. Superior corrosion resistance and strength.",
		"input": { "Fe": 5, "Cr": 2, "Ni": 1 },
		"output": { "StainlessSteel": 4 },
		"duration": 8.0,
		"level_req": 12,
		"xp": 60,
		"research_req": "metallurgy_advanced"
	},
	"craft_cobalt_battery": {
		"name": "Lithium-Cobalt Battery",
		"description": "Advanced battery tech. High energy density.",
		"input": { "Li": 2, "Co": 3, "Al": 2, "Circuit": 1 },
		"output": { "CoBattery": 1 },
		"duration": 10.0,
		"level_req": 15,
		"xp": 100,
		"research_req": "advanced_batteries"
	},
	"craft_mg_ion_battery": {
		"name": "Magnesium-Ion Battery",
		"description": "Lightweight alternative to Li-ion. Fast charging.",
		"input": { "Mg": 4, "Mn": 2, "AlWire": 2 },
		"output": { "MgBattery": 1 },
		"duration": 8.0,
		"level_req": 14,
		"xp": 80,
		"research_req": "advanced_batteries"
	},
	"electrolysis_nickel_catalyst": {
		"name": "Nickel-Catalyzed Electrolysis",
		"description": "Ni catalyst speeds H2 production. More efficient.",
		"input": { "Water": 1, "Ni": 0.1 },
		"output": { "H": 3, "O": 2 },
		"duration": 2.0,
		"level_req": 12,
		"xp": 30,
		"research_req": "catalytic_electrodes"
	},
	"craft_superalloy": {
		"name": "Cobalt Superalloy",
		"description": "Co-Ni-Cr heat-resistant alloy for engines and reactors.",
		"input": { "Co": 2, "Ni": 2, "Cr": 1, "Ti": 1 },
		"output": { "Superalloy": 3 },
		"duration": 12.0,
		"level_req": 18,
		"xp": 150,
		"research_req": "superalloy_engineering"
	},
	# Late-Game Rare Metal Processing
	"craft_platinum_catalyst": {
		"name": "Platinum Catalyst Matrix",
		"description": "Pt-ceramic catalyst. Increases ALL processing speed by 25%.",
		"input": { "Pt": 10, "Si": 50, "AdvCircuit": 5 },
		"output": { "PtCatalyst": 1 },
		"duration": 20.0,
		"level_req": 25,
		"xp": 300,
		"research_req": "industrial_catalysis"
	},
	"craft_palladium_cell": {
		"name": "Palladium Fuel Cell",
		"description": "Pd-H2 fuel cell. High efficiency energy generation.",
		"input": { "Pd": 5, "H": 20, "Circuit": 3 },
		"output": { "PdFuelCell": 1 },
		"duration": 15.0,
		"level_req": 22,
		"xp": 200,
		"research_req": "fuel_cell_tech"
	},
	"craft_iridium_plate": {
		"name": "Iridium Armor Plating",
		"description": "Nearly indestructible Ir plating. Ultimate defense.",
		"input": { "Ir": 8, "Ti": 20, "Graphite": 10 },
		"output": { "IrPlate": 5 },
		"duration": 25.0,
		"level_req": 28,
		"xp": 400,
		"research_req": "iridium_metallurgy"
	},
	"craft_osmium_core": {
		"name": "Osmium Reactor Core",
		"description": "Densest material. Extreme HP and mass.",
		"input": { "Os": 5, "VoidCrystal": 2, "QuantumCore": 1 },
		"output": { "OsCore": 1 },
		"duration": 30.0,
		"level_req": 30,
		"xp": 800,
		"research_req": "exotic_metallurgy"
	},
	"refine_platinum_ore": {
		"name": "Platinum Extraction",
		"description": "Extract pure Pt from asteroid samples.",
		"input": { "PtOre": 10 },
		"output": { "Pt": 2 },
		"output_table": [["Pd", 0.3, 1, 2]],  # 30% chance for Pd byproduct
		"duration": 8.0,
		"level_req": 20,
		"xp": 100,
		"research_req": "precious_metal_refining"
	},
	"craft_iridium_tungsten_alloy": {
		"name": "Iridium-Tungsten Alloy",
		"description": "Ir-W armor-piercing penetrator cores.",
		"input": { "Ir": 3, "W": 5 },
		"output": { "IrWAlloy": 4 },
		"duration": 12.0,
		"level_req": 26,
		"xp": 250,
		"research_req": "iridium_metallurgy"
	}
}


func _init():
	super._init("Engineering")

func get_recipe_speed_multiplier(recipe_id: String) -> float:
	var multiplier = 1.0
	
	var upgrades_db = {
		"centrifuge_dirt": [
			{"id": "fast_centrifuges", "bonus": 0.25},
			{"id": "maglev_bearings", "bonus": 0.50},
			{"id": "quantum_separators", "bonus": 0.75}
		],
		"electrolysis": [
			{"id": "catalytic_electrodes", "bonus": 0.25},
			{"id": "ion_exchange", "bonus": 0.50},
			{"id": "resonance_splitters", "bonus": 0.75}
		],
		"charcoal_burning": [{"id": "pyrolysis_control", "bonus": 0.25}],
		"smelt_steel": [{"id": "blast_furnace", "bonus": 0.25}],
		"press_graphite": [{"id": "hydraulic_press", "bonus": 0.25}]
	}
	
	if recipe_id in upgrades_db:
		for upgrade in upgrades_db[recipe_id]:
			if GameState.research_manager and GameState.research_manager.is_tech_unlocked(upgrade["id"]):
				multiplier += upgrade["bonus"]
		
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
		var res_req = recipe.get("research_req")
		if res_req and not GameState.research_manager.is_tech_unlocked(res_req):
			print("Research required: ", res_req)
			return
		
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
