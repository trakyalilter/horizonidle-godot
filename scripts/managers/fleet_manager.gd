extends Skill

signal activity_occurred

# --- MISSION DATABASE ---
# Each mission provides a different passive stream of resources.
var missions = {
	"scavenge_alpha": {
		"name": "Alpha Sector Scavenging",
		"desc": "Passive yield of Titanium and Iron.",
		"yield": {"Ti": 1.0, "Fe": 5.0, "Scrap": 2.0},
		"interval": 10.0,
		"risk": 0.05,
		"min_tier": 1,
		"research_req": "sector_alpha_decryption"
	},
	"harvest_nebula": {
		"name": "Nebula Harvester",
		"desc": "Passive yield of Hydrogen and Helium.",
		"yield": {"H": 10.0, "He": 2.0, "O": 5.0},
		"interval": 10.0,
		"risk": 0.1,
		"min_tier": 2,
		"research_req": "deep_space_nav"
	},
	"tech_recovery": {
		"name": "Gamma Tech Recovery",
		"desc": "Passive yield of SalvageData and DroneCores.",
		"yield": {"SalvageData": 0.5, "DroneCore": 0.1, "Circuit": 1.0},
		"interval": 15.0,
		"risk": 0.2,
		"min_tier": 3,
		"research_req": "radiation_shielding"
	},
	"void_mining": {
		"name": "Void Crystal Extraction",
		"desc": "Passive yield of Void Crystals and Exotic Matter.",
		"yield": {"VoidCrystal": 0.2, "ExoticMatter": 0.1, "credits": 5000},
		"interval": 20.0,
		"risk": 0.35,
		"min_tier": 4,
		"research_req": "void_navigation"
	}
}

# --- FLEET STATE ---
# active_expeditions: {slot_index: {mission_id, hull_id, stats, progress_timer}}
var active_expeditions: Dictionary = {}
var max_slots: int = 1 # Increasable via research

func _init():
	super._init("Administration")

# --- CORE LOGIC ---

func get_available_missions() -> Array:
	var available = []
	for mid in missions:
		var m = missions[mid]
		if m.get("research_req") == null or GameState.research_manager.is_tech_unlocked(m["research_req"]):
			available.append(mid)
	return available

func deploy_fleet(slot_idx: int, mission_id: String, hull_id: String) -> bool:
	# Update max_slots from research
	if GameState.research_manager:
		max_slots = int(GameState.research_manager.get_efficiency_bonus("fleet_slots"))

	if slot_idx >= max_slots: return false
	if active_expeditions.has(slot_idx): return false
	if not mission_id in missions: return false
	
	# Verify hull is not active ship
	if hull_id == GameState.shipyard_manager.active_hull:
		return false
		
	# Verify tier requirements
	var hull_data = GameState.shipyard_manager.hulls.get(hull_id)
	if not hull_data: return false
	
	var mission_data = missions[mission_id]
	if hull_data["tier"] < mission_data["min_tier"]:
		return false
		
	active_expeditions[slot_idx] = {
		"mission_id": mission_id,
		"hull_id": hull_id,
		"progress": 0.0,
		"total_earned": {}
	}
	
	print("[Fleet] Deployed %s to %s" % [hull_id, mission_id])
	return true

func recall_fleet(slot_idx: int):
	if active_expeditions.has(slot_idx):
		active_expeditions.erase(slot_idx)

func process_tick(delta: float):
	var speed_bonus = 0.0
	if GameState.research_manager:
		speed_bonus = GameState.research_manager.get_efficiency_bonus("fleet_speed")

	for slot in active_expeditions:
		var exp = active_expeditions[slot]
		var data = missions[exp["mission_id"]]
		
		# Effective Interval: Base / (1.0 + bonus)
		var effective_interval = data["interval"] / (1.0 + speed_bonus)
		
		exp["progress"] += delta
		if exp["progress"] >= effective_interval:
			_resolve_mission_tick(slot)
			exp["progress"] = 0.0

func _resolve_mission_tick(slot: int):
	var exp = active_expeditions[slot]
	var data = missions[exp["mission_id"]]
	
	# Current Ship tier helps mitigate risk? (Future polish)
	
	# Risk Check (Structural Damage)
	if randf() < data["risk"] * 0.1: # Scaled risk per tick
		var damage = randi_range(50, 200)
		_apply_structural_damage(exp["hull_id"], damage)
		
	# Payout
	for res in data["yield"]:
		var qty = data["yield"][res]
		if res == "credits":
			GameState.resources.add_currency("credits", qty)
		else:
			GameState.resources.add_element(res, qty)
		
		exp["total_earned"][res] = exp["total_earned"].get(res, 0.0) + qty
	
	# Skill XP
	add_xp(5)
	activity_occurred.emit()

func _apply_structural_damage(hull_id, amount):
	# Risk Mitigation: Repair Docks infrastructure reduces cost
	var reduction = 1.0
	if GameState.infrastructure_manager:
		var docks = GameState.infrastructure_manager.get_building_count("repair_docks")
		reduction = max(0.1, 1.0 - (docks * 0.1)) # 10% per dock, cap at 90% reduction
	
	var base_cost = amount * 10
	var final_cost = int(base_cost * reduction)
	
	# Safety: Negative Balance Protection
	var current_credits = GameState.resources.get_currency("credits")
	var actual_deduction = min(current_credits, final_cost)
	
	if actual_deduction > 0:
		GameState.resources.add_currency("credits", -actual_deduction)
		print("[Fleet] Ship %s sustained damage! Repaired for %d Cr (Reduced by docks: %d%%)" % [hull_id, actual_deduction, int((1.0-reduction)*100)])
	else:
		print("[Fleet] Ship %s sustained damage! Repairs waived/bankrupt safety triggered." % hull_id)

# Offline Support
func calculate_offline(delta: float) -> String:
	var speed_bonus = 0.0
	if GameState.research_manager:
		speed_bonus = GameState.research_manager.get_efficiency_bonus("fleet_speed")

	var report = "Fleet Command Offline Gains:\n"
	var total_loot = {}
	var ships_damaged = 0
	
	for slot in active_expeditions:
		var exp = active_expeditions[slot]
		var data = missions[exp["mission_id"]]
		
		var effective_interval = data["interval"] / (1.0 + speed_bonus)
		var cycles = int(delta / effective_interval)
		if cycles <= 0: continue
		
		# Loot
		for res in data["yield"]:
			var total = data["yield"][res] * cycles
			if res == "credits":
				GameState.resources.add_currency("credits", total)
			else:
				GameState.resources.add_element(res, total)
			total_loot[res] = total_loot.get(res, 0.0) + total
			exp["total_earned"][res] = exp["total_earned"].get(res, 0.0) + total
			
		# Damage Probability (Approximation for offline)
		var damage_prob = data["risk"] * 0.1 * cycles
		if randf() < damage_prob:
			ships_damaged += 1
			# Use the protected function to handle docks and protection
			_apply_structural_damage(exp["hull_id"], randi_range(500, 2000))
			
		add_xp(5 * cycles)

	if total_loot.is_empty(): return ""
	
	for res in total_loot:
		report += " + %s: %d\n" % [res, total_loot[res]]
	if ships_damaged > 0:
		report += " ! %d Fleet repairs needed.\n" % ships_damaged
		
	return report

func get_save_data_manager() -> Dictionary:
	var data = get_save_data()
	data["active_expeditions"] = active_expeditions
	data["max_slots"] = max_slots
	return data

func load_save_data_manager(data: Dictionary):
	load_save_data(data)
	active_expeditions = data.get("active_expeditions", {})
	max_slots = data.get("max_slots", 1)

func reset(decay_factor: float = 1.0) -> void:
	super.reset(decay_factor)
	active_expeditions.clear()
	max_slots = 1
