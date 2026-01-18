extends "res://scripts/core/skill.gd"

var buildings: Dictionary = {}
var generation: float = 0.0
var consumption: float = 0.0
var net_energy: float = 0.0

var building_db: Dictionary = {
	"solar_panel": {
		"name": "Solar Array",
		"description": "Generates clean energy from the local star.",
		"cost": {"credits": 50, "Si": 5}, 
		"energy_gen": 10.0, 
		"energy_cons": 0.0,
		"max": 10
	},
	"coal_burner": {
		"name": "Carbon Generator",
		"description": "Burns Carbon to generate high energy.",
		"cost": {"credits": 150, "Fe": 10},
		"energy_gen": 50.0, 
		"energy_cons": 0.0,
		"max": 5
	},
	"auto_excavator": {
		"name": "Auto-Excavator (XL)",
		"description": "Massive automated drill. Excavates 10 Dirt every 5s.",
		"cost": {"credits": 500, "Si": 50, "Fe": 20},
		"energy_gen": 0.0,
		"energy_cons": 20.0,
		"yield": {"Dirt": 10},
		"interval": 5.0,
		"max": 3
	},
	"industrial_pump": {
		"name": "Industrial Pump",
		"description": "Deep-crust pump. Extracts 10 Water every 5s.",
		"cost": {"credits": 500, "Si": 20, "Fe": 50}, 
		"energy_gen": 0.0,
		"energy_cons": 25.0,
		"yield": {"Water": 10},
		"interval": 5.0,
		"max": 3
	},
	"drone_bay": {
		"name": "Drone Recovery Bay",
		"description": "Automated drones scavenge unlocked zones (10% Efficiency).",
		"cost": {"credits": 2000, "Circuit": 10, "Ti": 20},
		"energy_gen": 0.0,
		"energy_cons": 50.0,
		"max": 1,
		"research_req": "automated_logistics",
		"special": "passive_gather"
	},
	"fabricator": {
		"name": "Molecular Fabricator",
		"description": "Advanced 3D printer. Reduces Crafting Time by 20%.",
		"cost": {"credits": 5000, "Circuit": 50, "Fiber": 20},
		"energy_gen": 0.0,
		"energy_cons": 100.0,
		"max": 1,
		"research_req": "molecular_printing",
		"special": "craft_buff"
	},
	"auto_smelter": {
		"name": "Automated Smelter",
		"description": "Produces Steel from Iron + Carbon + Oxygen. Requires continuous input.",
		"cost": {"credits": 2500, "Ti": 20, "Circuit": 5},
		"energy_gen": 0.0,
		"energy_cons": 50.0,
		"yield": {"Steel": 2},
		"input": {"Fe": 2, "C": 1, "O": 2},
		"interval": 4.0,
		"max": 3,
		"research_req": "automated_smelting"
	},
	"hydro_plant": {
		"name": "Industrial Electrolysis Plant",
		"description": "Splits Water into Hydrogen and Oxygen automatically.",
		"cost": {"credits": 2500, "Si": 50, "Circuit": 10},
		"energy_gen": 0.0,
		"energy_cons": 40.0,
		"yield": {"H": 2, "O": 1},
		"input": {"Water": 1},
		"interval": 2.0,
		"max": 5,
		"research_req": "industrial_electrolysis"
	},
	"auto_press": {
		"name": "Automated Carbon Press",
		"description": "Compresses Carbon into Graphite.",
		"cost": {"credits": 3000, "Fe": 100, "Hydraulics": 5},
		"energy_gen": 0.0,
		"energy_cons": 60.0,
		"yield": {"Graphite": 1},
		"input": {"C": 5},
		"interval": 6.0,
		"max": 2,
		"research_req": "molecular_compression"
	},
	"munitions_factory": {
		"name": "Munitions Factory",
		"description": "Mass produces basic ammunition.",
		"cost": {"credits": 75000, "Circuit": 20, "Steel": 20},
		"energy_gen": 0.0,
		"energy_cons": 80.0,
		"yield": {"SlugT1": 10, "CellT1": 10},
		"input": {"Fe": 2, "Si": 2},
		"interval": 5.0,
		"max": 2,
		"research_req": "mass_production_tactics"
	},
	"catalyst_chamber": {
		"name": "Platinum Catalyst Chamber",
		"description": "Pt catalyst increases ALL processing speed by 25%. Global effect.",
		"cost": {"credits": 500000, "PtCatalyst": 5, "AdvCircuit": 30, "Superalloy": 20},
		"energy_gen": 0.0,
		"energy_cons": 150.0,
		"max": 1,
		"research_req": "industrial_catalysis",
		"special": "global_catalyst"
	},
	"palladium_generator": {
		"name": "Palladium Fuel Cell Generator",
		"description": "Pd-H2 fuel cells. Passive energy generation from hydrogen.",
		"cost": {"credits": 250000, "PdFuelCell": 20, "Circuit": 40},
		"energy_gen": 200.0,
		"energy_cons": 0.0,
		"input": {"H": 1},  # Consumes 1 H per cycle
		"interval": 10.0,
		"max": 3,
		"research_req": "fuel_cell_tech"
	},
	"hydrogen_reactor": {
		"name": "Hydrogen Reactor",
		"description": "Fuses Hydrogen for high energy output. Perfect mid-game power source.",
		"cost": {"credits": 50000, "Steel": 200, "Circuit": 50, "NavData": 5},
		"energy_gen": 100.0,
		"energy_cons": 0.0,
		"input": {"H": 5},
		"interval": 10.0,
		"max": 5,
		"research_req": "fluid_dynamics"
	},
	"industrial_centrifuge": {
		"name": "Industrial Centrifuge",
		"description": "Automated Mineral Washing. Extracts Iron and Silicon from Dirt + Water.",
		"cost": {"credits": 25000, "Steel": 100, "Si": 20, "DroneCore": 10},
		"energy_gen": 0.0,
		"energy_cons": 45.0,
		"yield": {"Fe": 3, "Si": 1},
		"input": {"Dirt": 5, "Water": 5},
		"interval": 3.0,
		"max": 3,
		"research_req": "automated_logistics"
	},
	"electronics_assembler": {
		"name": "Electronics Assembler",
		"description": "Automated production of Circuitry and Advanced Circuitry.",
		"cost": {"credits": 100000, "Ti": 50, "Circuit": 100, "SalvageData": 20},
		"energy_gen": 0.0,
		"energy_cons": 120.0,
		"yield": {"Circuit": 2},
		"input": {"Si": 4, "DroneCore": 2},
		"interval": 8.0,
		"max": 1,
		"research_req": "industrial_automation"
	}
}

var production_timers: Dictionary = {}

func _init():
	super._init("Infrastructure")

func get_building_count(building_id: String) -> int:
	return buildings.get(building_id, 0)

func can_afford(building_id: String) -> bool:
	if not building_id in building_db: return false
	
	var data = building_db[building_id]
	var count = get_building_count(building_id)
	
	# Check research requirement
	if data.get("research_req"):
		if not GameState.research_manager.is_tech_unlocked(data["research_req"]):
			return false
	
	if count >= data.get("max", 999):
		return false
		
	for res in data["cost"]:
		var qty = data["cost"][res]
		if res == "credits":
			if GameState.resources.get_currency("credits") < qty:
				return false
		else:
			if GameState.resources.get_element_amount(res) < qty:
				return false
	
	return true

func build(building_id: String) -> bool:
	if can_afford(building_id):
		var data = building_db[building_id]
		
		# Spend
		for res in data["cost"]:
			var qty = data["cost"][res]
			if res == "credits":
				GameState.resources.remove_currency("credits", qty)
			else:
				GameState.resources.remove_element(res, qty)
		
		# Add
		var count = get_building_count(building_id)
		buildings[building_id] = count + 1
		recalc_energy()
		return true
	return false

func recalc_energy():
	var gen = 0.0
	var cons = 0.0
	
	for bid in buildings:
		var count = buildings[bid]
		if bid in building_db:
			var data = building_db[bid]
			gen += data.get("energy_gen", 0.0) * count
			cons += data.get("energy_cons", 0.0) * count
	
	generation = gen
	consumption = cons
	net_energy = gen - cons

func process_tick(delta: float):
	# Energy Management
	# 1. Generate energy from generators
	if net_energy > 0:
		GameState.resources.add_energy(net_energy * delta)
	
	# 2. Check if we have enough energy to power consumers
	var current_energy = GameState.resources.get_energy()
	var can_run_full = (net_energy >= 0 or current_energy > 0)
	
	# 3. Calculate energy efficiency (0.0 to 1.0)
	var energy_efficiency = 1.0
	if net_energy < 0:
		# Negative net energy - running on battery
		var deficit = abs(net_energy) * delta
		if current_energy >= deficit:
			# Consume from battery
			GameState.resources.add_energy(-deficit)
			energy_efficiency = 1.0
		elif current_energy > 0:
			# Partial battery available
			GameState.resources.add_energy(-current_energy)  # Drain remaining
			energy_efficiency = current_energy / deficit
		else:
			# No battery - complete shutdown
			energy_efficiency = 0.0
	
	# Production Logic (scaled by energy efficiency)
	if energy_efficiency > 0:
		for bid in buildings:
			var count = buildings[bid]
			if count <= 0: continue
			
			var data = building_db.get(bid)
			if not data: continue
			
			if "yield" in data:
				if not bid in production_timers: production_timers[bid] = 0.0
				production_timers[bid] += delta * energy_efficiency
				
				var interval = data.get("interval", 5.0)
				if production_timers[bid] >= interval:
					# Check if building needs inputs
					var can_produce = true
					if "input" in data:
						for res in data["input"]:
							var qty_needed = data["input"][res] * count
							if GameState.resources.get_element_amount(res) < qty_needed:
								can_produce = false
								break
					
					if can_produce:
						# Consume inputs if required
						if "input" in data:
							for res in data["input"]:
								var qty = data["input"][res] * count
								GameState.resources.remove_element(res, qty)
						
						# Produce outputs
						for res in data["yield"]:
							var qty = data["yield"][res]
							GameState.resources.add_element(res, qty * count)
						
						# Special Upgrade: Industrial Centrifuge Titanium Extraction
						if bid == "industrial_centrifuge":
							if GameState.research_manager and GameState.research_manager.is_tech_unlocked("advanced_mineralogy"):
								# 20% chance per cycle per centrifuge to find Titanium
								for i in range(count):
									if randf() < 0.2:
										GameState.resources.add_element("Ti", 1)
					
					production_timers[bid] = 0.0
			
			elif data.get("special", "") == "passive_gather":
				if not bid in production_timers: production_timers[bid] = 0.0
				production_timers[bid] += delta * energy_efficiency
				
				if production_timers[bid] >= 10.0:
					# Passive Gather from unlocked gathering actions at 10% efficiency
					var gm = GameState.gathering_manager
					if gm and gm.actions:
						for action_id in gm.actions:
							var action = gm.actions[action_id]
							
							# Check if action is unlocked (level + research)
							var lvl_req = action.get("level_req", 1)
							if gm.get_level() < lvl_req:
								continue
							
							var res_req = action.get("research_req")
							if res_req and not GameState.research_manager.is_tech_unlocked(res_req):
								continue
							
							# 10% chance to trigger this action per 10s tick
							if randf() < 0.1:
								var loot_table = action.get("loot_table", [])
								for entry in loot_table:
									var element = entry[0]
									var chance = entry[1]
									var min_amt = entry[2]
									var max_amt = entry[3]
									
									if randf() < chance:
										var amount = randi_range(min_amt, max_amt)
										# 10% efficiency
										amount = max(1, int(amount * 0.1))
										GameState.resources.add_element(element, amount)
					
					production_timers[bid] = 0.0

func calculate_offline(delta: float) -> String:
	# Offline Industry
	# 1. Energy check (static)
	if net_energy < 0:
		return "Infrastructure:\nGrid Offline (Negative Energy)."
	
	var report = ""
	var loot_summary = {}
	
	for bid in buildings:
		var count = buildings[bid]
		if count <= 0: continue
		var data = building_db.get(bid)
		if "yield" in data:
			var interval = data.get("interval", 5.0)
			var cycles = int(delta / interval)
			
			# If building has input requirements, calculate max possible cycles
			if "input" in data:
				var max_cycles = cycles
				for res in data["input"]:
					var qty_per_cycle = data["input"][res] * count
					var available = GameState.resources.get_element_amount(res)
					var possible = int(available / qty_per_cycle)
					max_cycles = min(max_cycles, possible)
				cycles = max_cycles
			
			if cycles > 0:
				# Consume inputs if required
				if "input" in data:
					for res in data["input"]:
						var qty = data["input"][res] * count * cycles
						GameState.resources.remove_element(res, qty)
				
				# Produce outputs
				for res in data["yield"]:
					var qty = data["yield"][res]
					var total = qty * count * cycles
					GameState.resources.add_element(res, total)
					loot_summary[res] = loot_summary.get(res, 0) + total

	
	if not loot_summary.is_empty():
		report += "Infrastructure Production (Offline):\n"
		for item in loot_summary:
			report += " + %s: %d\n" % [item, loot_summary[item]]
			
	return report

func get_save_data_manager() -> Dictionary:
	var data = get_save_data()
	data["buildings"] = buildings
	return data

func load_save_data_manager(data: Dictionary):
	load_save_data(data)
	if data.is_empty(): return
	
	buildings = data.get("buildings", {})
	# Fix types if json loaded strings
	for k in buildings: buildings[k] = int(buildings[k])
	
	recalc_energy()
