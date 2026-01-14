extends "res://scripts/core/skill.gd"

var action_duration = 5.0
var current_action = ""
var is_active = false
var action_progress = 0.0

var unlocked_techs = []

var tech_tree = {
	"basic_engineering": {
		"name": "Basic Engineering",
		"description": "Unlocks Soil Centrifuge (Dirt -> Iron/Silica).",
		"cost": 50,
		"type": "technology",
		"parent": null
	},
	"fluid_dynamics": {
		"name": "Fluid Dynamics",
		"description": "Unlocks Electrolysis (Water -> Hydrogen/Oxygen).",
		"cost": 100,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"combustion": {
		"name": "Organic Combustion",
		"description": "Unlocks Charcoal Kiln (Wood -> Carbon).",
		"cost": 150,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"alloy_synthesis": {
		"name": "Alloy Synthesis",
		"description": "Unlocks Steel Foundry (Iron + Carbon -> Steel).",
		"cost": 300,
		"type": "technology",
		"parent": "combustion"
	},
	"shipwright_1": {
		"name": "Shipwright I",
		"description": "Unlocks Industrial Frigate Class (Tier 2).",
		"cost": 500,
		"type": "construction",
		"parent": "alloy_synthesis"
	},
	"adv_materials": {
		"name": "Advanced Materials",
		"description": "Unlocks Graphite Press (Carbon -> Graphite).",
		"cost": 800,
		"type": "technology",
		"parent": "alloy_synthesis"
	},
	"shipwright_2": {
		"name": "Shipwright II",
		"description": "Unlocks Escort Destroyer Class (Tier 3).",
		"cost": 2000,
		"type": "construction",
		"parent": "shipwright_1"
	},
	"energy_shields": {
		"name": "Energy Fields",
		"description": "Unlocks Deflector Shields.",
		"cost": 400,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"automation": {
		"name": "Industrial Automation",
		"description": "Unlocks Assembly Lines. (Placeholder)",
		"cost": 500,
		"cost_items": {"Circuit": 5},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"sector_alpha_decryption": {
		"name": "Sector Scanning (Alpha)",
		"description": "Decrypt Nav-Data to reveal Sector Alpha (Rich in Titanium).",
		"cost": 500,
		"cost_items": {"NavData": 10},
		"type": "discovery",
		"parent": "shipwright_1"
	},
	"warp_drive": {
		"name": "Warp Drive Theory",
		"description": "Experimental propulsion. Unlocks Galaxy Map.",
		"cost": 5000,
		"cost_items": {"NavData": 20, "Ti": 100},
		"type": "technology",
		"parent": "shipwright_2"
	},
	# --- GATHERING UPGRADES ---
	"diamond_drills": {
		"name": "Diamond Tipped Drills",
		"description": "Reinforced drills increase 'Excavate Soil' speed by 25%.",
		"cost": 200,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"high_flow_pumps": {
		"name": "High-Flow Pumps",
		"description": "Increases 'Pump Water' output speed by 25%.",
		"cost": 250,
		"type": "technology",
		"parent": "fluid_dynamics"
	},
	"laser_cutters": {
		"name": "Laser Cutters",
		"description": "Precision lasers increase 'Deforest Zone' speed by 25%.",
		"cost": 300,
		"type": "technology",
		"parent": "combustion"
	},
	"magnetic_funnels": {
		"name": "Magnetic Funnels",
		"description": "Increases 'Harvest Nebula' collection speed by 25%.",
		"cost": 2000,
		"type": "technology",
		"parent": "energy_shields"
	},
	# --- PROCESSING UPGRADES ---
	"fast_centrifuges": {
		"name": "High-RPM Centrifuges",
		"description": "Increases 'Soil Centrifuge' processing speed by 25%.",
		"cost": 200,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"catalytic_electrodes": {
		"name": "Catalytic Electrodes",
		"description": "Increases 'Water Electrolysis' speed by 25%.",
		"cost": 300,
		"type": "technology",
		"parent": "fluid_dynamics"
	},
	"pyrolysis_control": {
		"name": "Pyrolysis Control",
		"description": "Increases 'Charcoal Kiln' speed by 25%.",
		"cost": 400,
		"type": "technology",
		"parent": "combustion"
	},
	"blast_furnace": {
		"name": "Blast Furnace",
		"description": "Increases 'Steel Foundry' speed by 25%.",
		"cost": 800,
		"type": "technology",
		"parent": "alloy_synthesis"
	},
	"hydraulic_press": {
		"name": "Hydraulic Press",
		"description": "Increases 'Graphite Press' speed by 25%.",
		"cost": 1500,
		"type": "technology",
		"parent": "adv_materials"
	},
	# --- MILITARY UPGRADES ---
	"ballistics_optimization": {
		"name": "Ballistics Optimization", 
		"description": "Unlocks Depleted Uranium Rounds (Ammo T3).",
		"cost": 1500,
		"type": "technology",
		"parent": "alloy_synthesis"
	},
	"energy_metrics": {
		"name": "Energy Metrics",
		"description": "Unlocks Vaporizer Cells (Ammo T3) & Laser Sights.",
		"cost": 1500,
		"type": "technology",
		"parent": "fluid_dynamics"
	},
	# --- LOGISTICS UPGRADES ---
	"automated_logistics": {
		"name": "Automated Logistics",
		"description": "Unlocks Drone Bay (Passive Gathering).",
		"cost": 3000,
		"cost_items": {"Circuit": 20},
		"type": "construction",
		"parent": "basic_engineering"
	},
	"molecular_printing": {
		"name": "Molecular Printing",
		"description": "Unlocks Fabricator (Crafting Speed +20%).",
		"cost": 5000,
		"cost_items": {"Circuit": 50, "Fiber": 20},
		"type": "construction",
		"parent": "shipwright_2"
	},
	# --- END-GAME AUTOMATION (NEW) ---
	"automated_smelting": {
		"name": "Automated Smelting",
		"description": "Unlocks Auto-Smelter (Iron/Carbon -> Steel).",
		"cost": 2500,
		"cost_items": {"Ti": 20},
		"type": "technology",
		"parent": "blast_furnace"
	},
	"industrial_electrolysis": {
		"name": "Industrial Electrolysis",
		"description": "Unlocks Hydro-Plant (Water -> H/O).",
		"cost": 2500,
		"cost_items": {"Si": 50},
		"type": "technology",
		"parent": "catalytic_electrodes"
	},
	"molecular_compression": {
		"name": "Molecular Compression",
		"description": "Unlocks Auto-Press (Carbon -> Graphite).",
		"cost": 3000,
		"cost_items": {"Fe": 100},
		"type": "technology",
		"parent": "hydraulic_press"
	},
	"mass_production_tactics": {
		"name": "Mass Production Tactics",
		"description": "Unlocks Munitions Factories.",
		"cost": 5000,
		"cost_items": {"Circuit": 20, "Steel": 20},
		"type": "technology",
		"parent": "automated_logistics"
	},
	# --- END-GAME SHIPS (NEW) ---
	"capital_ship_engineering": {
		"name": "Capital Ship Doctrine",
		"description": "Unlocks Battlecruiser Class (Tier 4).",
		"cost": 10000,
		"cost_items": {"VoidArtifact": 1, "Ti": 200},
		"type": "construction",
		"parent": "shipwright_2"
	},
	"quantum_dynamics": {
		"name": "Quantum Dynamics",
		"description": "Unlocks Dreadnought Class (Tier 5).",
		"cost": 25000,
		"cost_items": {"QuantumCore": 1, "VoidArtifact": 5},
		"type": "construction",
		"parent": "capital_ship_engineering"
	}
}

func _init():
	super._init("Astrophysics")

func can_unlock(tech_id: String) -> bool:
	if not tech_id in tech_tree: return false
	if tech_id in unlocked_techs: return false
	
	var node = tech_tree[tech_id]
	var cost = node.get("cost", 0)
	var parent = node.get("parent")
	
	if GameState.resources.get_currency("credits") < cost: return false
	
	if "cost_items" in node:
		for item in node["cost_items"]:
			var qty = node["cost_items"][item]
			if GameState.resources.get_element_amount(item) < qty: return false
	
	if parent and not parent in unlocked_techs: return false
	
	return true

func unlock_tech(tech_id: String) -> bool:
	if can_unlock(tech_id):
		var node = tech_tree[tech_id]
		
		# Pay
		if node.get("cost", 0) > 0:
			GameState.resources.remove_currency("credits", node["cost"])
		
		if "cost_items" in node:
			for item in node["cost_items"]:
				GameState.resources.remove_element(item, node["cost_items"][item])
				
		unlocked_techs.append(tech_id)
		print("Unlocked tech: " + node["name"])
		return true
	return false

func is_tech_unlocked(tech_id):
	if tech_id == null: return true
	return tech_id in unlocked_techs

func reset():
	super.reset()
	unlocked_techs = []
	stop_action()

func get_save_data_manager() -> Dictionary:
	var data = get_save_data()
	data["unlocked_techs"] = unlocked_techs
	return data

func load_save_data_manager(data: Dictionary):
	load_save_data(data)
	unlocked_techs = data.get("unlocked_techs", [])

# Action Logic (Scanning)

func start_scan():
	start_action("scan_sector")

func start_action(action_id: String):
	is_active = true
	current_action = action_id
	action_progress = 0.0

func stop_action():
	is_active = false
	current_action = ""
	action_progress = 0.0

func complete_action():
	var base_yield = 15
	if "eff_scanning_1" in unlocked_techs:
		base_yield = int(base_yield * 1.5)
	
	GameState.resources.add_currency("data", base_yield)
	add_xp(25)

func process_tick(delta: float):
	if not is_active or current_action == "": return
	
	action_progress += delta
	if action_progress >= action_duration:
		complete_action()
		action_progress = 0.0 # Loop

func calculate_offline(delta: float):
	if not is_active or current_action == "": return null
	
	var actions = int(delta / action_duration)
	if actions <= 0: return null
	
	var base_yield = 15
	if "eff_scanning_1" in unlocked_techs: 
		base_yield = int(base_yield * 1.5)
		
	var total_data = base_yield * actions
	var total_xp = 25 * actions
	
	GameState.resources.add_currency("data", total_data)
	add_xp(total_xp)
	
	return "Research (Scanning):\nActions: %d\nData Gained: %d\nXP Gained: %d" % [actions, total_data, total_xp]
