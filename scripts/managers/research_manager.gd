extends "res://scripts/core/skill.gd"

var action_duration = 5.0
var current_action = ""
var is_active = false
var action_progress = 0.0

var unlocked_techs = []

signal tech_unlocked(tech_id)

var tech_tree = {
	"basic_engineering": {
		"name": "Basic Engineering",
		"description": "Unlocks:\n• Mineral Washing\n• Scrap Recycling\n• Lithium Refining",
		"cost": 50,
		"type": "technology",
		"parent": null
	},
	"fluid_dynamics": {
		"name": "Fluid Dynamics",
		"description": "Unlocks:\n• Water Pumping\n• Electrolysis",
		"cost": 50,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"combustion": {
		"name": "Organic Combustion",
		"description": "Unlocks:\n• Charcoal Kiln\n• Fly Ash Separation",
		"cost": 50,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"alloy_synthesis": {
		"name": "Alloy Synthesis",
		"description": "Unlocks:\n• Steel Foundry\n• Bronze Alloy",
		"cost": 300,
		"type": "technology",
		"parent": "combustion"
	},
	"shipwright_1": {
		"name": "Shipwright I",
		"description": "Unlocks:\n• Industrial Frigate (T2)\n• Titanium Plating",
		"cost": 500,
		"type": "construction",
		"parent": "alloy_synthesis"
	},
	"adv_materials": {
		"name": "Advanced Materials",
		"description": "Unlocks:\n• Graphite Press\n• Semiconductor Wafer\n• Graphene Battery",
		"cost": 800,
		"type": "technology",
		"parent": "alloy_synthesis"
	},
	"shipwright_2": {
		"name": "Shipwright II",
		"description": "Unlocks:\n• Escort Destroyer (T3)",
		"cost": 2000,
		"type": "construction",
		"parent": "shipwright_1"
	},
	"energy_shields": {
		"name": "Energy Fields",
		"description": "Unlocks:\n• Deflector Shield",
		"cost": 400,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"automation": {
		"name": "Industrial Automation",
		"description": "Unlocks:\n• Advanced Circuitry",
		"cost": 500,
		"cost_items": {"AdvCircuit": 5},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"sector_alpha_decryption": {
		"name": "Sector Scanning (Alpha)",
		"description": "Unlocks:\n• Sector Alpha (Titanium)",
		"cost": 500,
		"cost_items": {"NavData": 10},
		"type": "discovery",
		"parent": "shipwright_1"
	},
	"xeno_archaeology": {
		"name": "Xeno-Archaeology",
		"description": "Unlocks:\n• Analyze Void Artifact",
		"cost": 2000,
		"cost_items": {"VoidArtifact": 1, "NavData": 5},
		"type": "discovery",
		"parent": "sector_alpha_decryption"
	},
	"warp_drive": {
		"name": "Warp Drive Theory",
		"description": "Unlocks:\n• Galaxy Map",
		"cost": 5000,
		"cost_items": {"NavData": 20, "Ti": 100},
		"type": "technology",
		"parent": "shipwright_2"
	},
	# --- GATHERING UPGRADES ---
	"diamond_drills": {
		"name": "Diamond Tipped Drills",
		"description": "Bonus:\n• +25% Excavate Soil speed",
		"cost": 200,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"high_flow_pumps": {
		"name": "High-Flow Pumps",
		"description": "Bonus:\n• +25% Pump Water speed",
		"cost": 250,
		"type": "technology",
		"parent": "fluid_dynamics"
	},
	"laser_cutters": {
		"name": "Laser Cutters",
		"description": "Bonus:\n• +25% Deforest Zone speed",
		"cost": 300,
		"type": "technology",
		"parent": "combustion"
	},
	"magnetic_funnels": {
		"name": "Magnetic Funnels",
		"description": "Bonus:\n• +25% Harvest Nebula speed",
		"cost": 2000,
		"type": "technology",
		"parent": "energy_shields"
	},
	# Gathering Tier 2 (+50%) & Tier 3 (+75%)
	"ultrasonic_drills": {
		"name": "Ultrasonic Drills",
		"description": "Bonus:\n• +50% Excavate Soil speed",
		"cost": 1000,
		"type": "technology",
		"parent": "diamond_drills"
	},
	"plasma_bore": {
		"name": "Plasma Bore",
		"description": "Bonus:\n• +75% Excavate Soil speed",
		"cost": 5000,
		"type": "technology",
		"parent": "ultrasonic_drills"
	},
	"superfluid_intake": {
		"name": "Superfluid Intake",
		"description": "Bonus:\n• +50% Pump Water speed",
		"cost": 1500,
		"type": "technology",
		"parent": "high_flow_pumps"
	},
	"hydro_vortex": {
		"name": "Hydro-Vortex Arrays",
		"description": "Bonus:\n• +75% Pump Water speed",
		"cost": 7500,
		"type": "technology",
		"parent": "superfluid_intake"
	},
	"mono_filament": {
		"name": "Mono-Filament Wire",
		"description": "Bonus:\n• +50% Deforest Zone speed",
		"cost": 2000,
		"type": "technology",
		"parent": "laser_cutters"
	},
	"molecular_disassembler": {
		"name": "Molecular Disassembler",
		"description": "Bonus:\n• +75% Deforest Zone speed",
		"cost": 10000,
		"type": "technology",
		"parent": "mono_filament"
	},
	# --- PROCESSING UPGRADES ---
	"fast_centrifuges": {
		"name": "High-RPM Centrifuges",
		"description": "Bonus:\n• +25% Mineral Washing speed",
		"cost": 200,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"catalytic_electrodes": {
		"name": "Catalytic Electrodes",
		"description": "Bonus:\n• +25% Electrolysis speed",
		"cost": 300,
		"type": "technology",
		"parent": "fluid_dynamics"
	},
	"pyrolysis_control": {
		"name": "Pyrolysis Control",
		"description": "Bonus:\n• +25% Charcoal Kiln speed",
		"cost": 400,
		"type": "technology",
		"parent": "combustion"
	},
	"blast_furnace": {
		"name": "Blast Furnace",
		"description": "Bonus:\n• +25% Steel Foundry speed",
		"cost": 800,
		"type": "technology",
		"parent": "alloy_synthesis"
	},
	"hydraulic_press": {
		"name": "Hydraulic Press",
		"description": "Bonus:\n• +25% Graphite Press speed",
		"cost": 1500,
		"type": "technology",
		"parent": "adv_materials"
	},
	# Processing Tier 2 (+50%) & Tier 3 (+75%)
	"maglev_bearings": {
		"name": "Mag-Lev Bearings",
		"description": "Bonus:\n• +50% Mineral Washing speed",
		"cost": 1000,
		"type": "technology",
		"parent": "fast_centrifuges"
	},
	"quantum_separators": {
		"name": "Quantum Separators",
		"description": "Bonus:\n• +75% Mineral Washing speed",
		"cost": 5000,
		"type": "technology",
		"parent": "maglev_bearings"
	},
	"ion_exchange": {
		"name": "Ion-Exchange Membranes",
		"description": "Bonus:\n• +50% Electrolysis speed",
		"cost": 1500,
		"type": "technology",
		"parent": "catalytic_electrodes"
	},
	"resonance_splitters": {
		"name": "Resonance Splitters",
		"description": "Bonus:\n• +75% Electrolysis speed",
		"cost": 7500,
		"type": "technology",
		"parent": "ion_exchange"
	},
	# --- MILITARY UPGRADES ---
	"ballistics_optimization": {
		"name": "Ballistics Optimization", 
		"description": "Unlocks:\n• Depleted Uranium Rounds (T3)\n• Heavy Railgun",
		"cost": 1500,
		"type": "technology",
		"parent": "alloy_synthesis"
	},
	"energy_metrics": {
		"name": "Energy Metrics",
		"description": "Unlocks:\n• Vaporizer Cells (T3)\n• Plasma Lance Mk.III",
		"cost": 1500,
		"type": "technology",
		"parent": "fluid_dynamics"
	},
	"cryogenic_systems": {
		"name": "Cryogenic Systems",
		"description": "Unlocks:\n• Helium Coolant Cell\n• Cryo-Cooled Laser Mk.III",
		"cost": 8000,
		"cost_items": {"He": 50, "Ti": 30},
		"type": "technology",
		"parent": "energy_metrics"
	},
	# --- LOGISTICS UPGRADES ---
	"automated_logistics": {
		"name": "Automated Logistics",
		"description": "Unlocks:\n• Drone Bay",
		"cost": 3000,
		"cost_items": {"Circuit": 20},
		"type": "construction",
		"parent": "basic_engineering"
	},
	"molecular_printing": {
		"name": "Molecular Printing",
		"description": "Unlocks:\n• Fabricator (+20% crafting)",
		"cost": 5000,
		"cost_items": {"Circuit": 50, "Fiber": 20},
		"type": "construction",
		"parent": "shipwright_2"
	},
	# --- END-GAME AUTOMATION (NEW) ---
	"automated_smelting": {
		"name": "Automated Smelting",
		"description": "Unlocks:\n• Auto-Smelter",
		"cost": 2500,
		"cost_items": {"Ti": 20},
		"type": "technology",
		"parent": "blast_furnace"
	},
	"industrial_electrolysis": {
		"name": "Industrial Electrolysis",
		"description": "Unlocks:\n• Hydro-Plant",
		"cost": 2500,
		"cost_items": {"Si": 50},
		"type": "technology",
		"parent": "catalytic_electrodes"
	},
	"molecular_compression": {
		"name": "Molecular Compression",
		"description": "Unlocks:\n• Auto-Press",
		"cost": 3000,
		"cost_items": {"Fe": 100},
		"type": "technology",
		"parent": "hydraulic_press"
	},
	"mass_production_tactics": {
		"name": "Mass Production Tactics",
		"description": "Unlocks:\n• Munitions Factory",
		"cost": 5000,
		"cost_items": {"Circuit": 20, "Steel": 20},
		"type": "technology",
		"parent": "automated_logistics"
	},
	# --- END-GAME SHIPS (NEW) ---
	"capital_ship_engineering": {
		"name": "Capital Ship Doctrine",
		"description": "Unlocks:\n• Battlecruiser (T4)\n• Coil Cannon\n• Antimatter Engine",
		"cost": 10000,
		"cost_items": {"VoidArtifact": 1, "Ti": 200},
		"type": "construction",
		"parent": "shipwright_2"
	},
	"quantum_dynamics": {
		"name": "Quantum Dynamics",
		"description": "Unlocks:\n• Dreadnought (T5)",
		"cost": 25000,
		"cost_items": {"QuantumCore": 1, "VoidArtifact": 5},
		"type": "construction",
		"parent": "capital_ship_engineering"
	},
	# New Zone Unlocks
	"deep_space_nav": {
		"name": "Deep Space Navigation",
		"description": "Unlocks:\n• Sector Beta (Mining Colony)",
		"cost": 12000,
		"cost_items": {"NavData": 30, "Ti": 150},
		"type": "discovery",
		"parent": "warp_drive"
	},
	"radiation_shielding": {
		"name": "Radiation Shielding Theory",
		"description": "Unlocks:\n• Sector Gamma (Radioactive)",
		"cost": 20000,
		"cost_items": {"Co": 50, "Al": 100, "Circuit": 30},
		"type": "technology",
		"parent": "deep_space_nav"
	},
	"exotic_matter_analysis": {
		"name": "Exotic Matter Analysis",
		"description": "Unlocks:\n• Sector Delta (Crystalline)",
		"cost": 35000,
		"cost_items": {"Pt": 20, "ExoticMatter": 10, "QuantumCore": 3},
		"type": "discovery",
		"parent": "radiation_shielding"
	},
	# Mid-Game Technology
	"metallurgy_advanced": {
		"name": "Advanced Metallurgy",
		"description": "Unlocks:\n• Stainless Steel Alloy",
		"cost": 5000,
		"cost_items": {"Cr": 20, "Ni": 20},
		"type": "technology",
		"parent": "alloy_synthesis"
	},
	"advanced_batteries": {
		"name": "Advanced Battery Technology",
		"description": "Unlocks:\n• Li-Co Battery\n• Mg-Ion Battery",
		"cost": 8000,
		"cost_items": {"Co": 30, "Li": 50, "Circuit": 15},
		"type": "technology",
		"parent": "adv_materials"
	},
	"superalloy_engineering": {
		"name": "Superalloy Engineering",
		"description": "Unlocks:\n• Cobalt Superalloy",
		"cost": 15000,
		"cost_items": {"Co": 100, "Ni": 100, "Cr": 50, "Ti": 100},
		"type": "technology",
		"parent": "metallurgy_advanced"
	},
	# Late-Game Rare Metal Technologies
	"precious_metal_refining": {
		"name": "Precious Metal Refining",
		"description": "Unlocks:\n• Platinum Refining\n• Palladium Refining",
		"cost": 18000,
		"cost_items": {"Ti": 200, "Circuit": 50},
		"type": "technology",
		"parent": "deep_space_nav"
	},
	"industrial_catalysis": {
		"name": "Industrial Catalysis",
		"description": "Bonus:\n• +25% All Production Speed",
		"cost": 30000,
		"cost_items": {"Pt": 50, "Si": 200, "AdvCircuit": 20},
		"type": "technology",
		"parent": "precious_metal_refining"
	},
	"fuel_cell_tech": {
		"name": "Fuel Cell Technology",
		"description": "Unlocks:\n• Hydrogen Fuel Cell",
		"cost": 22000,
		"cost_items": {"Pd": 30, "H": 500, "Circuit": 30},
		"type": "technology",
		"parent": "precious_metal_refining"
	},
	"iridium_metallurgy": {
		"name": "Iridium Metallurgy",
		"description": "Unlocks:\n• Iridium Armor\n• Iridium Rounds",
		"cost": 40000,
		"cost_items": {"Ir": 50, "Ti": 300},
		"type": "technology",
		"parent": "superalloy_engineering"
	},
	"exotic_metallurgy": {
		"name": "Exotic Metallurgy",
		"description": "Unlocks:\n• Osmium Armor\n• Void-Infused Hull",
		"cost": 60000,
		"cost_items": {"Os": 20, "VoidCrystal": 5, "QuantumCore": 5},
		"type": "technology",
		"parent": "iridium_metallurgy"
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
		tech_unlocked.emit(tech_id)
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
