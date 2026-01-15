extends Node

## Element Display Names Database
## Maps chemical symbols to full names for UI display

var ELEMENT_NAMES = {
	# Basic Elements
	"H": "Hydrogen",
	"He": "Helium",
	"C": "Carbon",
	"O": "Oxygen",
	"Si": "Silicon",
	"S": "Sulfur",
	
	# Common Metals
	"Fe": "Iron",
	"Cu": "Copper",
	"Al": "Aluminum",
	"Mg": "Magnesium",
	"Zn": "Zinc",
	"Sn": "Tin",
	
	# Industrial Metals
	"Ti": "Titanium",
	"Co": "Cobalt",
	"Ni": "Nickel",
	"Cr": "Chromium",
	"Mn": "Manganese",
	"W": "Tungsten",
	
	# Precious/Rare Metals
	"Au": "Gold",
	"Ag": "Silver",
	"Pt": "Platinum",
	"Pd": "Palladium",
	"Ir": "Iridium",
	"Os": "Osmium",
	"Rh": "Rhodium",
	
	# Radioactive
	"U": "Uranium",
	
	# Special Materials
	"Li": "Lithium",
	
	# Processed Materials
	"Steel": "Steel",
	"Bronze": "Bronze",
	"Graphite": "Graphite",
	"StainlessSteel": "Stainless Steel",
	"GalvanizedSteel": "Galvanized Steel",
	"Superalloy": "Superalloy",
	"AlMgAlloy": "Aluminum-Magnesium Alloy",
	"IrWAlloy": "Iridium-Tungsten Alloy",
	
	# Ores
	"Dirt": "Dirt",
	"Bauxite": "Bauxite Ore",
	"Dolomite": "Dolomite",
	"Cassiterite": "Tin Ore",
	"ZincOre": "Zinc Ore",
	"Spodumene": "Lithium Ore",
	"PtOre": "Platinum Ore",
	
	# Components
	"Circuit": "Circuit Board",
	"AdvCircuit": "Advanced Circuit",
	"Chip": "Microchip",
	"Hydraulics": "Hydraulic System",
	"AlWire": "Aluminum Wiring",
	
	# Batteries
	"BatteryT1": "Basic Battery",
	"BatteryT2": "Improved Battery",
	"BatteryT3": "Zero-Point Battery",
	"CoBattery": "Cobalt-Lithium Battery",
	"MgBattery": "Magnesium-Ion Battery",
	"PdFuelCell": "Palladium Fuel Cell",
	"PtCatalyst": "Platinum Catalyst",
	
	# Consumables
	"Mesh": "Nanoweave Mesh",
	"Seal": "Hull Sealant",
	"Resin": "Polymer Resin",
	"Fiber": "Carbon Fiber",
	
	# Ammo
	"SlugT1": "Ferrite Rounds",
	"SlugT2": "Tungsten Sabot",
	"SlugT3": "Depleted Uranium Rounds",
	"CellT1": "Focus Crystal",
	"CellT2": "Plasma Cell",
	"CellT3": "Vaporizer Cell",
	
	# Special/Exotic
	"VoidArtifact": "Void Artifact",
	"QuantumCore": "Quantum Core",
	"ExoticMatter": "Exotic Matter",
	"VoidCrystal": "Void Crystal",
	"Diamond": "Diamond",
	"SyntheticCrystal": "Synthetic Crystal",
	"Neutronium": "Neutronium",
	"AntimatterParticle": "Antimatter Particle",
	"ExoticIsotope": "Exotic Isotope",
	"ReactiveCore": "Reactive Core",
	"AICore": "AI Core",
	"AncientTech": "Ancient Technology",
	
	# Other
	"Wood": "Wood",
	"Water": "Water",
	"NavData": "Navigation Data",
	"IrPlate": "Iridium Plating",
	"OsCore": "Osmium Core"
}

## Category mappings for inventory filtering
var CATEGORIES = {
	"ores": ["Dirt", "Bauxite", "Dolomite", "Cassiterite", "ZincOre", "Spodumene", "PtOre"],
	"basic_metals": ["Fe", "Cu", "Al", "Mg", "Sn", "Zn"],
	"advanced_metals": ["Ti", "Co", "Ni", "Cr", "Mn", "W"],
	"rare_metals": ["Au", "Ag", "Pt", "Pd", "Ir", "Os", "Rh", "U"],
	"alloys": ["Steel", "Bronze", "Graphite", "StainlessSteel", "GalvanizedSteel", "Superalloy", "AlMgAlloy", "IrWAlloy"],
	"components": ["Circuit", "AdvCircuit", "Chip", "Hydraulics", "AlWire", "Resin", "Fiber"],
	"batteries": ["BatteryT1", "BatteryT2", "BatteryT3", "CoBattery", "MgBattery", "PdFuelCell"],
	"consumables": ["Mesh", "Seal"],
	"ammo": ["SlugT1", "SlugT2", "SlugT3", "CellT1", "CellT2", "CellT3"],
	"special": ["VoidArtifact", "QuantumCore", "ExoticMatter", "VoidCrystal", "Diamond", "SyntheticCrystal", 
				"Neutronium", "AntimatterParticle", "ExoticIsotope", "ReactiveCore", "AICore", "AncientTech",
				"NavData", "IrPlate", "OsCore", "PtCatalyst"],
	"basic": ["H", "He", "C", "O", "Si", "S", "Li", "Wood", "Water"]
}

## Get display name for an element
func get_display_name(symbol: String) -> String:
	return ELEMENT_NAMES.get(symbol, symbol)

## Get display name with symbol in parentheses
func get_full_display(symbol: String) -> String:
	var name = get_display_name(symbol)
	if name != symbol and symbol.length() <= 3:  # Only add symbol if it's short
		return "%s (%s)" % [name, symbol]
	return name

## Get category for an element
func get_category(symbol: String) -> String:
	for cat in CATEGORIES:
		if symbol in CATEGORIES[cat]:
			return cat
	return "other"

## Get all elements in a category
func get_elements_in_category(category: String) -> Array:
	return CATEGORIES.get(category, [])
