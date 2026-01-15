extends "res://scripts/core/skill.gd"

# Stats
var max_hp = 100
var current_hp = 100
var attack = 10
var defense = 0
var evasion = 0.0

# Components
var max_shield = 0.0
var shield_regen = 0.0
var attack_kinetic = 0

var attack_energy = 0
var energy_used = 0.0

# Active Ship State
var active_hull: String = "corvette_hull"
var active_ammo: String = ""
var loadout: Dictionary = {} # {slot_index: module_id}

# Inventory
var module_inventory: Dictionary = {}

var hulls: Dictionary = {
	"corvette_hull": {
		"name": "Mining Corvette (T1)",
		"stats": {"hp": 100},
		"cost": {"credits": 50, "Fe": 10},
		"slots": ["weapon", "shield", "engine", "battery"] 
	},
	"frigate_hull": {
		"name": "Industrial Frigate (T2)",
		"stats": {"hp": 500},
		"cost": {"credits": 1000, "Steel": 40, "Chip": 5},
		"slots": ["weapon", "weapon", "shield", "shield", "engine", "battery", "battery"],
		"research_req": "shipwright_1"
	},
	"destroyer_hull": {
		"name": "Escort Destroyer (T3)",
		"stats": {"hp": 1500, "atk": 10},
		"cost": {"credits": 5000, "Steel": 150, "Ti": 50},
		"slots": ["weapon", "weapon", "weapon", "shield", "shield", "engine", "engine", "battery", "battery", "battery"],
		"research_req": "shipwright_2"
	},
	"battlecruiser_hull": {
		"name": "Battlecruiser (T4)",
		"stats": {"hp": 4000, "atk": 25, "energy_capacity": 500},
		"cost": {"credits": 15000, "Steel": 500, "Ti": 200, "VoidArtifact": 1},
		"slots": ["weapon", "weapon", "weapon", "weapon", "weapon", "weapon", "shield", "shield", "shield", "shield", "engine", "battery", "battery", "battery", "battery"],
		"research_req": "capital_ship_engineering"
	},
	"dreadnought_hull": {
		"name": "Dreadnought (T5)",
		"stats": {"hp": 10000, "atk": 50, "energy_capacity": 1000},
		"cost": {"credits": 50000, "Steel": 5000, "Ti": 500, "QuantumCore": 1, "VoidArtifact": 5},
		"slots": ["weapon", "weapon", "weapon", "weapon", "weapon", "weapon", "weapon", "weapon", "shield", "shield", "shield", "shield", "shield", "shield", "shield", "engine", "battery", "battery", "battery", "battery", "battery", "battery"],
		"research_req": "quantum_dynamics"
	}
}

var modules: Dictionary = {
	# Weapons
	"mining_laser_mk1": {
		"name": "Mining Laser Mk.I", 
		"slot_type": "weapon", 
		"stats": {"atk_energy": 10, "energy_load": 5}, 
		"cost": {"credits": 50, "Si": 5},
		"desc": "Energy Beam. Effective vs Shields."
	},
	"mining_laser_mk2": {
		"name": "Focused Laser Mk.II", 
		"slot_type": "weapon", 
		"stats": {"atk_energy": 25, "energy_load": 15}, 
		"cost": {"credits": 500, "Si": 20, "Ti": 10, "Chip": 5},
		"desc": "High intensity beam. Melts shields."
	},
	"railgun_mk1": {
		"name": "Mass Driver", 
		"slot_type": "weapon", 
		"stats": {"atk_kinetic": 15, "energy_load": 5}, 
		"cost": {"credits": 200, "Fe": 50},
		"desc": "Magnetic projectile. Crushes armor."
	},
	"targeting_computer": {
		"name": "Targeting Computer",
		"slot_type": "weapon",
		"stats": {"atk_kinetic": 5, "atk_energy": 5, "energy_load": 5},
		"cost": {"credits": 300, "Chip": 10, "Si": 20},
		"desc": "Advanced analytics. Improves all weapon tracking.",
		"research_req": "basic_engineering"
	},
	# Batteries
	"battery_t1": {
		"name": "Li-Ion Battery",
		"slot_type": "battery",
		"stats": {"energy_capacity": 50},
		"cost": {"BatteryT1": 10},
		"desc": "Standard Energy Storage."
	},
	"battery_t2": {
		"name": "Graphene Matrix",
		"slot_type": "battery",
		"stats": {"energy_capacity": 150},
		"cost": {"BatteryT2": 10},
		"desc": "High-density Storage.",
		"research_req": "adv_materials"
	},
	"battery_t3": {
		"name": "Zero-Point Module",
		"slot_type": "battery",
		"stats": {"energy_capacity": 500},
		"cost": {"BatteryT3": 10},
		"desc": "Infinite Void Energy.",
		"research_req": "quantum_dynamics"
	},
	# Shields
	"basic_shield": {
		"name": "Deflector Shield", 
		"slot_type": "shield", 
		"stats": {"max_shield": 50, "shield_regen": 2, "energy_load": 10}, 
		"cost": {"credits": 1000, "Si": 100},
		"desc": "Generates a regenerative energy field.",
		"research_req": "energy_shields"
	},
	"thermal_tile": {
		"name": "Graphite Armor",
		"slot_type": "shield", 
		"stats": {"def": 12, "hp": 50}, 
		"cost": {"credits": 500, "Graphite": 20},
		"desc": "Ablative carbon armor. Increases Hull & Armor.",
		"research_req": "adv_materials"
	},
	"titanium_armor": {
		"name": "Titanium Plating",
		"slot_type": "shield",
		"stats": {"def": 15, "hp": 100},
		"cost": {"credits": 800, "Ti": 20},
		"desc": "Heavy-duty alloy armor.",
		"research_req": "shipwright_1"
	},
	# Engines
	"basic_thruster": {
		"name": "Ion Thrusters",
		"slot_type": "engine", 
		"stats": {"eva": 10, "energy_load": 5},
		"cost": {"credits": 50, "Fe": 5},
		"desc": "Slow but reliable."
	}
}

func _init():
	super._init("Shipyard")
	recalc_stats()

func construct_hull(hull_id: String) -> bool:
	if not hull_id in hulls: return false
	
	var hull_data = hulls[hull_id]
	if hull_data.get("research_req"):
		if not GameState.research_manager.is_tech_unlocked(hull_data["research_req"]):
			return false
	
	# Check Costs
	for res in hull_data["cost"]:
		var qty = hull_data["cost"][res]
		if res == "credits":
			if GameState.resources.get_currency("credits") < qty: return false
		else:
			if GameState.resources.get_element_amount(res) < qty: return false
			
	# Consume
	for res in hull_data["cost"]:
		var qty = hull_data["cost"][res]
		if res == "credits":
			GameState.resources.remove_currency("credits", qty)
		else:
			GameState.resources.remove_element(res, qty)
			
	# Unequip All
	unequip_all()
	
	active_hull = hull_id
	loadout = {}
	for i in range(hull_data["slots"].size()):
		loadout[i] = null
		
	recalc_stats()
	return true

func unequip_all():
	for idx in loadout:
		var mid = loadout[idx]
		if mid:
			module_inventory[mid] = module_inventory.get(mid, 0) + 1
	loadout = {}

func craft_module(module_id: String) -> bool:
	if not module_id in modules: return false
	
	var mod_data = modules[module_id]
	if mod_data.get("research_req"):
		if not GameState.research_manager.is_tech_unlocked(mod_data["research_req"]):
			return false
	
	# Check Costs
	for res in mod_data["cost"]:
		var qty = mod_data["cost"][res]
		if res == "credits":
			if GameState.resources.get_currency("credits") < qty: return false
		else:
			if GameState.resources.get_element_amount(res) < qty: return false
			
	# Consume
	for res in mod_data["cost"]:
		var qty = mod_data["cost"][res]
		if res == "credits":
			GameState.resources.remove_currency("credits", qty)
		else:
			GameState.resources.remove_element(res, qty)
	
	module_inventory[module_id] = module_inventory.get(module_id, 0) + 1
	return true

func equip_module(slot_idx: int, module_id: String) -> bool:
	# Used by Designer UI
	if not active_hull in hulls: 
		print("Equip Fail: Active hull not found or invalid.")
		return false
	var hull_data = hulls[active_hull]
	
	if slot_idx >= hull_data["slots"].size(): 
		print("Equip Fail: Slot index out of bounds.")
		return false
	var req_type = hull_data["slots"][slot_idx]
	
	if not module_id in modules: 
		print("Equip Fail: Module ID not found.")
		return false
	var mod_data = modules[module_id]
	if mod_data["slot_type"] != req_type: 
		print("Equip Fail: Slot Type Mismatch. Req: ", req_type, " Got: ", mod_data["slot_type"])
		return false
	
	if module_inventory.get(module_id, 0) <= 0: 
		print("Equip Fail: No inventory.")
		return false
	
	# Unequip existing
	var existing = loadout.get(slot_idx)
	if existing:
		module_inventory[existing] += 1
		
	module_inventory[module_id] -= 1
	loadout[slot_idx] = module_id
	
	recalc_stats()
	return true

func unequip_slot(slot_idx: int):
	var existing = loadout.get(slot_idx)
	if existing:
		module_inventory[existing] = module_inventory.get(existing, 0) + 1
		loadout[slot_idx] = null
		recalc_stats()

func recalc_stats():
	var hp = 0
	var shield = 0.0
	var s_reg = 0.0
	var atk_k = 0
	var atk_e = 0
	var defe = 0
	var eva = 0.0
	var e_cap = 0.0
	var e_load = 0.0
	
	if active_hull in hulls:
		var h = hulls[active_hull]["stats"]
		hp += h.get("hp", 0)
		shield += h.get("max_shield", 0)
		atk_k += h.get("atk", 0)
		defe += h.get("def", 0)
		eva += h.get("eva", 0)
		e_cap += h.get("energy_capacity", 0)
		
	for mid in loadout.values():
		if mid and mid in modules:
			var m = modules[mid]["stats"]
			hp += m.get("hp", 0)
			shield += m.get("max_shield", 0)
			s_reg += m.get("shield_regen", 0)
			atk_k += m.get("atk_kinetic", 0)
			atk_e += m.get("atk_energy", 0)
			defe += m.get("def", 0)
			eva += m.get("eva", 0)
			e_cap += m.get("energy_capacity", 0)
			e_load += m.get("energy_load", 0)
			
	max_hp = hp if hp > 0 else 10
	max_shield = shield
	shield_regen = s_reg
	attack_kinetic = atk_k
	attack_energy = atk_e
	attack = atk_k + atk_e
	defense = defe
	evasion = eva
	energy_used = e_load
	
	# Update Global Resources
	if GameState.resources:
		GameState.resources.max_energy = e_cap
	
	if current_hp > max_hp: current_hp = max_hp

func get_save_data_manager() -> Dictionary:
	var data = get_save_data()
	data["active_hull"] = active_hull
	data["loadout"] = loadout
	data["inventory"] = module_inventory
	data["hp"] = current_hp
	return data

func load_save_data_manager(data: Dictionary):
	load_save_data(data)
	if data.is_empty(): return
	
	active_hull = data.get("active_hull", "corvette_hull")
	var saved_load = data.get("loadout", {})
	
	# Convert JSON string keys back to int if needed or handle direct
	loadout = {}
	if active_hull in hulls:
		var slot_count = hulls[active_hull]["slots"].size()
		for i in range(slot_count):
			var val = saved_load.get(str(i)) # JSON keys are strings
			if not val: val = saved_load.get(i) # Try int key
			loadout[i] = val
			
	module_inventory = data.get("inventory", {})
	recalc_stats()
	current_hp = data.get("hp", max_hp)
	
func reset():
	active_hull = "corvette_hull"
	module_inventory = {}
	loadout = {}
	if active_hull in hulls:
		for i in range(hulls[active_hull]["slots"].size()):
			loadout[i] = null
	recalc_stats()
	super.reset()
