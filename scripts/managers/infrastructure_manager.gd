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
	# Recalc every tick? Or only on build?
	# Energy fluctuations might happen if battery logic exists, but net_energy is static per build
	# Safer to just use cached net_energy unless modified
	
	# Battery Logic
	if net_energy > 0:
		GameState.resources.add_energy(net_energy * delta)
	
	# Production Logic (if powered)
	if net_energy >= 0:
		for bid in buildings:
			var count = buildings[bid]
			if count <= 0: continue
			
			var data = building_db.get(bid)
			if not data: continue
			
			if "yield" in data:
				if not bid in production_timers: production_timers[bid] = 0.0
				production_timers[bid] += delta
				
				var interval = data.get("interval", 5.0)
				if production_timers[bid] >= interval:
					for res in data["yield"]:
						var qty = data["yield"][res]
						GameState.resources.add_element(res, qty * count)
					production_timers[bid] = 0.0
			
			elif data.get("special", "") == "passive_gather":
				if not bid in production_timers: production_timers[bid] = 0.0
				production_timers[bid] += delta
				
				if production_timers[bid] >= 10.0:
					# Passive Gather Logic
					# Need access to gathering manager zones? 
					# For now, MVP implementation similar to Python
					var gm = GameState.gathering_manager
					# In Godot version, we didn't explicity port 'zones' structure inside Manager yet
					# But actions have 'loot_table'.
					
					# Simple fallback for now: Random dirt
					GameState.resources.add_element("Dirt", 1)
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
			if cycles > 0:
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
