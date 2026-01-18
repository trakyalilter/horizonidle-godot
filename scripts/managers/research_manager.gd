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
		"cost_items": {"SalvageData": 2},  # Requires 2 Survey Probe kills
		"type": "technology",
		"parent": null
	},
	"fluid_dynamics": {
		"name": "Fluid Dynamics",
		"description": "Unlocks:\n• Water Pumping\n• Electrolysis",
		"cost": 50,
		"cost_items": {"Res1": 2},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"combustion": {
		"name": "Organic Combustion",
		"description": "Unlocks:\n• Charcoal Kiln\n• Fly Ash Separation",
		"cost": 50,
		"cost_items": {"Res1": 2},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"smelting": {
		"name": "Smelting",
		"description": "Unlocks:\n• Steel Foundry\n• Bronze Alloy",
		"cost": 300,
		"cost_items": {"Res1": 5},
		"type": "technology",
		"parent": "combustion"
	},
	"shipwright_1": {
		"name": "Shipwright I",
		"description": "Unlocks:\n• Industrial Frigate (T2)\n• Titanium Plating",
		"cost": 2000,
		"cost_items": {"Res1": 20},
		"type": "construction",
		"parent": "smelting"
	},
	"upgrade_rare_artifact": {
		"name": "Synthesize Rare Artifact",
		"description": "Combine Common artifacts with circuits to create Rare research data.",
		"input": { "Res1": 15, "Circuit": 5 },
		"output": { "Res2": 1 },
		"duration": 30.0,
		"level_req": 35, # Increased from 8
		"xp": 100, # Increased from 50
		"research_req": "smelting"
	},
	"shipwright_2": {
		"name": "Shipwright II",
		"description": "Unlocks:\n• Escort Destroyer (T3)",
		"cost": 2000,
		"cost_items": {"Res2": 10},
		"type": "construction",
		"parent": "shipwright_1"
	},
	"adv_materials": {
		"name": "Advanced Materials",
		"description": "Unlocks:\n• Graphite Press\n• Semiconductor Wafer\n• Graphene Battery",
		"cost": 2000,
		"cost_items": {"Res2": 10},
		"type": "technology",
		"parent": "smelting"
	},
	"energy_shields": {
		"name": "Energy Fields",
		"description": "Unlocks:\n• Deflector Shield",
		"cost": 400,
		"type": "technology",
		"parent": "basic_engineering"
	},
	"upgrade_exotic_artifact": {
		"name": "Compile Exotic Artifact",
		"description": "Merge Rare artifacts with advanced tech to unlock capital-class research.",
		"input": { "Res2": 15, "AdvCircuit": 5, "NavData": 10 },
		"output": { "Res3": 1 },
		"duration": 60.0,
		"level_req": 60, # Increased from 15
		"xp": 300, # Increased from 150
		"research_req": "sector_alpha_decryption"
	},
	"automation": {
		"name": "Factory Automation",
		"description": "Unlocks:\n• Advanced Circuitry\n• Automated Assembly Line",
		"cost": 5000,
		"cost_items": {"Res2": 25, "Circuit": 20},
		"type": "technology",
		"parent": "shipwright_2"
	},
	"sector_alpha_decryption": {
		"name": "Sector Scanning (Alpha)",
		"description": "Unlocks:\n• Sector Alpha (Titanium)",
		"cost": 500,
		"cost_items": {"NavData": 10, "PirateManifest": 10},  # Requires Pirate Skiff kills
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
		"cost_items": {"NavData": 20, "Ti": 100, "Res3": 10},
		"type": "technology",
		"parent": "shipwright_2"
	},
	# --- NEW EARLY GAME GATES ---
	"kinetics_101": {
		"name": "Kinetic Weapons Theory",
		"description": "Unlocks:\n• Mass Driver",
		"cost": 50,
		"cost_items": {"Res1": 3},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"laser_optics": {
		"name": "Laser Optics",
		"description": "Unlocks:\n• Focused Laser Mk.II",
		"cost": 300,
		"cost_items": {"Res1": 5},
		"type": "technology",
		"parent": "fluid_dynamics"
	},
	"power_systems": {
		"name": "Power Systems",
		"description": "Unlocks:\n• Basic Battery Module",
		"cost": 150,
		"cost_items": {"Res1": 3},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"bronze_smithing": {
		"name": "Bronze Smithing",
		"description": "Unlocks:\n• Bronze Plating",
		"cost": 100,
		"cost_items": {"Res1": 2},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"lightweight_alloys": {
		"name": "Lightweight Alloys",
		"description": "Unlocks:\n• Aluminum Hull Patch",
		"cost": 200,
		"cost_items": {"Res1": 3},
		"type": "technology",
		"parent": "basic_engineering"
	},
	# --- GATHERING UPGRADES ---
	"diamond_drills": {
		"name": "Diamond Tipped Drills",
		"description": "Bonus:\n• +25% Excavate Soil speed",
		"cost": 200,
		"cost_items": {"Res1": 2},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"high_flow_pumps": {
		"name": "High-Flow Pumps",
		"description": "Bonus:\n• +25% Pump Water speed",
		"cost": 250,
		"cost_items": {"Res1": 2},
		"type": "technology",
		"parent": "fluid_dynamics"
	},
	"laser_cutters": {
		"name": "Laser Cutters",
		"description": "Bonus:\n• +25% Deforest Zone speed",
		"cost": 300,
		"cost_items": {"Res1": 2},
		"type": "technology",
		"parent": "combustion"
	},
	"magnetic_funnels": {
		"name": "Magnetic Funnels",
		"description": "Bonus:\n• +25% Harvest Nebula speed",
		"cost": 2000,
		"cost_items": {"Res1": 10},
		"type": "technology",
		"parent": "energy_shields"
	},
	# Gathering Tier 2 (+50%) & Tier 3 (+75%)
	"ultrasonic_drills": {
		"name": "Ultrasonic Drills",
		"description": "Bonus:\n• +50% Excavate Soil speed",
		"cost": 1000,
		"cost_items": {"Res1": 10},
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
		"cost_items": {"Res1": 5},
		"type": "technology",
		"parent": "combustion"
	},
	"blast_furnace": {
		"name": "Blast Furnace",
		"description": "Bonus:\n• +25% Steel Foundry speed",
		"cost": 800,
		"cost_items": {"Res1": 10},
		"type": "technology",
		"parent": "smelting"
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
	"advanced_mineralogy": {
		"name": "Advanced Mineralogy",
		"description": "Industrial Centrifuges now have a chance to extract Titanium (Ti) from Dirt processing.",
		"cost": 5000,
		"cost_items": {"Si": 100, "Fe": 100},
		"type": "technology",
		"parent": "fast_centrifuges"
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
	"processing_tungsten": {
		"name": "Processing Tungsten",
		"description": "Unlocks:\n• Tungsten Sabot Rounds (T2)",
		"cost": 1000,
		"cost_items": {"Res1": 10},
		"type": "technology",
		"parent": "smelting"
	},
	"ballistics_optimization": {
		"name": "Ballistics Optimization", 
		"description": "Unlocks:\n• Depleted Uranium Rounds (T3)\n• Heavy Railgun",
		"cost": 1500,
		"type": "technology",
		"parent": "processing_tungsten"
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
		"cost": 25000,
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
	"xeno_engineering": {
		"name": "Xeno-Engineering",
		"description": "Integrates alien salvage data. Increases Drone Recovery efficiency by 50%.",
		"cost": 10000,
		"cost_items": {"SalvageData": 10, "Circuit": 50},
		"type": "technology",
		"parent": "automated_logistics"
	},
	# --- END-GAME SHIPS (NEW) ---
	"capital_ship_engineering": {
		"name": "Capital Ship Doctrine",
		"description": "Unlocks:\n• Battlecruiser (T4)\n• Coil Cannon\n• Antimatter Engine",
		"cost": 500000,
		"cost_items": {"VoidArtifact": 5, "Ti": 200, "Res3": 100},
		"type": "construction",
		"parent": "shipwright_2"
	},
	"quantum_dynamics": {
		"name": "Quantum Dynamics",
		"description": "Unlocks:\n• Dreadnought (T5)",
		"cost": 5000000,
		"cost_items": {"QuantumCore": 20, "VoidArtifact": 50, "Res3": 500},
		"type": "construction",
		"parent": "capital_ship_engineering"
	},
	# New Zone Unlocks
	"deep_space_nav": {
		"name": "Deep Space Navigation",
		"description": "Unlocks:\n• Sector Beta (Mining Colony)",
		"cost": 100000,
		"cost_items": {"NavData": 30, "Ti": 150, "Res3": 10},
		"type": "discovery",
		"parent": "warp_drive"
	},
	"radiation_shielding": {
		"name": "Radiation Shielding Theory",
		"description": "Unlocks:\n• Sector Gamma (Radioactive)",
		"cost": 250000,
		"cost_items": {"Co": 50, "Al": 100, "Circuit": 30},
		"type": "technology",
		"parent": "deep_space_nav"
	},
	"exotic_matter_analysis": {
		"name": "Exotic Matter Analysis",
		"description": "Unlocks:\n• Sector Delta (Crystalline)",
		"cost": 1000000,
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
		"parent": "smelting"
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
		"cost": 100000,
		"cost_items": {"Co": 100, "Ni": 100, "Cr": 50, "Ti": 100},
		"type": "technology",
		"parent": "metallurgy_advanced"
	},
	# Late-Game Rare Metal Technologies
	"precious_metal_refining": {
		"name": "Precious Metal Refining",
		"description": "Unlocks:\n• Platinum Refining\n• Palladium Refining",
		"cost": 150000,
		"cost_items": {"Ti": 200, "Circuit": 50},
		"type": "technology",
		"parent": "deep_space_nav"
	},
	"industrial_catalysis": {
		"name": "Industrial Catalysis",
		"description": "Bonus:\n• +25% All Production Speed",
		"cost": 1000000,
		"cost_items": {"Pt": 200, "Si": 200, "AdvCircuit": 20},
		"type": "technology",
		"parent": "precious_metal_refining"
	},
	"fuel_cell_tech": {
		"name": "Fuel Cell Technology",
		"description": "Unlocks:\n• Hydrogen Fuel Cell",
		"cost": 250000,
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
		"cost": 2000000,
		"cost_items": {"Os": 20, "VoidCrystal": 5, "QuantumCore": 5},
		"type": "technology",
		"parent": "iridium_metallurgy"
	},
	# --- NEW LATE-GAME TECH (Expansion) ---
	"colony_automation": {
		"name": "Colony AI Integration",
		"description": "Unlocks:\n• Colonial Auto-Extractor (+25% all gathering yield)",
		"cost": 50000,
		"cost_items": {"ColonyDataCore": 1, "ColonySalvage": 100, "AdvCircuit": 50},
		"type": "technology",
		"parent": "deep_space_nav"
	},
	"gamma_optics": {
		"name": "High-Energy Gamma Optics",
		"description": "Unlocks:\n• Gamma Pulse Battery (+100 Energy Capacity)",
		"cost": 75000,
		"cost_items": {"RadIsotope": 50, "Pt": 100},
		"type": "technology",
		"parent": "radiation_shielding"
	},
	"void_physics": {
		"name": "Extreme Void Physics",
		"description": "Unlocks:\n• Singularity Engine (75% Evasion)",
		"cost": 5000000,
		"cost_items": {"VoidCrystal": 20, "QuantumCore": 10, "AntimatterParticle": 5},
		"type": "technology",
		"parent": "exotic_matter_analysis"
	},
	"perfect_automation": {
		"name": "Omni-Fabrication",
		"description": "Bonus:\n• -30% All action durations (Global)",
		"cost": 10000000,
		"cost_items": {"AICore": 5, "AncientTech": 5, "AdvCircuit": 200},
		"type": "technology",
		"parent": "colony_automation"
	},
	# --- EFFICIENCY & STAT EXPANSION (Phase 7) ---
	"salvage_heuristics": {
		"name": "Salvage Heuristics",
		"description": "Bonus:\n• +2 rolls in Scrap Recycling",
		"cost": 1000,
		"cost_items": {"Res1": 10},
		"type": "technology",
		"parent": "smelting"
	},
	"scavenger_protocol": {
		"name": "Scavenger Protocol",
		"description": "Bonus:\n• +15% DroneCore drop chance",
		"cost": 2500,
		"cost_items": {"Res2": 5},
		"type": "technology",
		"parent": "salvage_heuristics"
	},
	"combat_heuristics": {
		"name": "Combat Heuristics",
		"description": "Bonus:\n• +20% Combat XP gain",
		"cost": 1500,
		"cost_items": {"Res1": 10},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"shield_harmonics": {
		"name": "Shield Harmonics",
		"description": "Bonus:\n• +20% Shield Regeneration speed",
		"cost": 2000,
		"cost_items": {"Res1": 10},
		"type": "technology",
		"parent": "energy_shields"
	},
	"hull_hardening": {
		"name": "Carbon Hull Lattice",
		"description": "Bonus:\n• +15% Ship Max HP",
		"cost": 1200,
		"cost_items": {"Res1": 5},
		"type": "technology",
		"parent": "combustion"
	},
	"core_overclocking": {
		"name": "Reactor Overclocking",
		"description": "Bonus:\n• +10% Combat Attack Speed",
		"cost": 4000,
		"cost_items": {"Res2": 10},
		"type": "technology",
		"parent": "power_systems"
	},
	"deep_core_optics": {
		"name": "Deep Core Optics",
		"description": "Bonus:\n• +1 Base Yield for all Gathering",
		"cost": 800,
		"cost_items": {"Res1": 5},
		"type": "technology",
		"parent": "laser_cutters"
	},
	"nano_fabrication": {
		"name": "Nano-Fabrication",
		"description": "Bonus:\n• -15% Processing duration",
		"cost": 5000,
		"cost_items": {"Res2": 10},
		"type": "technology",
		"parent": "automation"
	},
	"data_clustering": {
		"name": "Data Clustering",
		"description": "Bonus:\n• -20% Research action duration",
		"cost": 2000,
		"cost_items": {"Res1": 15},
		"type": "technology",
		"parent": "basic_engineering"
	},
	"industrial_automation": {
		"name": "Industrial Automation",
		"description": "Advanced robotics for mass production.\nUnlocks:\n• Electronics Assembler",
		"cost": 15000,
		"cost_items": {"Circuit": 50, "Steel": 200},
		"type": "technology",
		"parent": "automated_smelting"
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

func get_efficiency_bonus(bonus_type: String) -> float:
	match bonus_type:
		"scrap_rolls":
			return 2.0 if "salvage_heuristics" in unlocked_techs else 0.0
		"drone_core_chance":
			return 0.15 if "scavenger_protocol" in unlocked_techs else 0.0
		"combat_xp":
			return 0.20 if "combat_heuristics" in unlocked_techs else 0.0
		"shield_regen":
			return 0.20 if "shield_harmonics" in unlocked_techs else 0.0
		"max_hp_mult":
			return 0.15 if "hull_hardening" in unlocked_techs else 0.0
		"attack_speed":
			return 0.10 if "core_overclocking" in unlocked_techs else 0.0
		"gathering_yield":
			var yield_bonus = 0.0
			if "deep_core_optics" in unlocked_techs: yield_bonus += 1.0
			if "colony_automation" in unlocked_techs: yield_bonus += 2.0 # Significant late-game boost
			return yield_bonus
		"processing_speed":
			var p_speed = 0.0
			if "nano_fabrication" in unlocked_techs: p_speed += 0.15
			if "perfect_automation" in unlocked_techs: p_speed += 0.30
			return p_speed
		"research_speed":
			var r_speed = 0.0
			if "data_clustering" in unlocked_techs: r_speed += 0.20
			if "perfect_automation" in unlocked_techs: r_speed += 0.30
			return r_speed
	return 0.0

func get_available_researches_count() -> int:
	var count = 0
	for tid in tech_tree:
		if not is_tech_unlocked(tid) and can_unlock(tid):
			count += 1
	return count

func get_affordable_researches_count() -> int:
	"""Phase 2.1: Checks if tech is available AND player has specific items/credits"""
	var count = 0
	for tid in tech_tree:
		if not is_tech_unlocked(tid) and can_unlock(tid):
			# can_unlock already checks credits and items
			count += 1
	return count

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
	
	var speed_mult = 1.0 + get_efficiency_bonus("research_speed")
	action_progress += delta * speed_mult
	
	if action_progress >= action_duration:
		complete_action()
		action_progress = 0.0 # Loop

func calculate_offline(delta: float):
	if not is_active or current_action == "": return null
	
	var speed_mult = 1.0 + get_efficiency_bonus("research_speed")
	var effective_duration = action_duration / speed_mult
	
	var actions = int(delta / effective_duration)
	if actions <= 0: return null
	
	var base_yield = 15
	if "eff_scanning_1" in unlocked_techs: 
		base_yield = int(base_yield * 1.5)
		
	var total_data = base_yield * actions
	var total_xp = 25 * actions
	
	GameState.resources.add_currency("data", total_data)
	add_xp(total_xp)
	
	return "Research (Scanning):\nActions: %d\nData Gained: %d\nXP Gained: %d" % [actions, total_data, total_xp]
