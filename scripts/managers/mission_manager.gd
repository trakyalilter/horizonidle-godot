extends RefCounted

var missions = {}
var active_missions = []

signal mission_updated()

func _init():
	init_missions()

func connect_signals():
	if GameState.resources:
		if not GameState.resources.element_added.is_connected(_on_element_added):
			GameState.resources.element_added.connect(_on_element_added)
		if not GameState.resources.currency_added.is_connected(_on_currency_added):
			GameState.resources.currency_added.connect(_on_currency_added)
			
	if GameState.research_manager:
		if not GameState.research_manager.tech_unlocked.is_connected(_on_tech_unlocked):
			GameState.research_manager.tech_unlocked.connect(_on_tech_unlocked)
			
	if GameState.shipyard_manager:
		if not GameState.shipyard_manager.module_crafted.is_connected(_on_module_crafted):
			GameState.shipyard_manager.module_crafted.connect(_on_module_crafted)
			
	if GameState.combat_manager:
		if not GameState.combat_manager.enemy_defeated.is_connected(_on_enemy_defeated):
			GameState.combat_manager.enemy_defeated.connect(_on_enemy_defeated)
			
	sync_progress()

func init_missions():
	missions.clear()
	active_missions.clear()
	
	# Tutorial Missions Sequence
	# Structure: [id, name, description, type, target, target_qty, reward_cr, reward_xp, next_mission_id]
	var m_list = [
		# ID, Name, Desc, Type, Target, TargetQty, RewardCr, RewardXP, NextID
		["m001", "Stranded in Orbit", "Gather 500 Dirt to begin basic repairs.", "gather", "Dirt", 500, 500, 50, "m002"],
		["m002", "Analytical Breakthrough", "Research 'Basic Engineering' to unlock refining.", "research", "basic_engineering", 1, 300, 50, "m003"],
		["m003", "Pump Master", "Research 'Fluid Dynamics' to unlock water collection.", "research", "fluid_dynamics", 1, 300, 50, "m004"],
		["m004", "Hydration", "Gather 500 units of Water.", "gather", "Water", 500, 500, 100, "m005"],
		["m005", "Mineral Washing", "Recover 100 Silicon and 100 Iron from Dirt.", "gather_multi", {"Si": 100, "Fe": 100}, 200, 1000, 200, "m006"],
		["m006", "Applied Physics", "Research the 'Applied Physics' hub.", "research", "applied_physics", 1, 500, 100, "m007"],
		["m007", "Mobility Check", "Craft 'Ion Thrusters' in the Shipyard.", "craft", "basic_thruster", 1, 1000, 100, "m008"],
		["m008", "Materials Science", "Research the 'Materials Science' hub.", "research", "materials_science", 1, 500, 100, "m009"],
		["m009", "Deforestation", "Gather 100 units of Wood from the orbital debris.", "gather", "Wood", 100, 500, 100, "m010"],
		["m010", "Organic Combustion", "Research 'Organic Combustion' to unlock the Kiln.", "research", "combustion", 1, 1000, 150, "m011"],
		["m011", "Essential Carbon", "Use the Charcoal Kiln to produce 50 Carbon.", "gather", "C", 50, 600, 150, "m012"],
		["m012", "Lithium Discovery", "Gather 100 samples of Spodumene ore.", "gather", "Spodumene", 100, 800, 200, "m013"],
		["m013", "Voltaic Storage", "Refine 50 Lithium in the Engineering tab.", "gather", "Li", 50, 1000, 250, "m014"],
		["m014", "Ballistics Theory", "Research 'Kinetics 101' for weapons technology.", "research", "kinetics_101", 1, 500, 100, "m015"],
		["m015", "Prototype Arsenal", "Craft a 'Mass Driver' in the Shipyard.", "craft", "railgun_mk1", 1, 1500, 200, "m016"],
		["m016", "Kinetic Munitions", "Produce 40 Ferrite Rounds for your weapon.", "gather", "SlugT1", 40, 500, 100, "m017"],
		["m017", "Target Locked", "Defeat 1 Lunar Drone in Lunar Orbit.", "defeat", "lunar_drone", 1, 2500, 500, "m018"],
		["m018", "Industrial Logistics", "Research the 'Industrial Logistics' hub.", "research", "industrial_logistics", 1, 500, 100, "m018b"],
		["m018b", "Automated Intelligence", "Research 'Automated Logistics' for circuitry.", "research", "automated_logistics", 1, 1000, 200, "m019"],
		["m019", "Cybernetic Integration", "Craft 5 Basic Circuitry in the Engineering tab.", "gather", "Circuit", 5, 2000, 300, "m020"],
		["m020", "Advanced Energy", "Research 'Power Systems' for batteries.", "research", "power_systems", 1, 500, 100, "m021"],
		["m021", "Industrial Energy", "Craft 10 Basic Batteries in the Engineering tab.", "gather", "BatteryT1", 10, 1000, 100, "m022"],
		["m022", "Power Storage", "Craft a 'Basic Battery Module' in the Shipyard.", "craft", "battery_t1", 1, 1500, 150, "m023"],
		["m023", "Hull Integrity", "Research 'Energy Fields' to unlock shielding.", "research", "energy_shields", 1, 1000, 150, "m024"],
		["m024", "Aegis System", "Craft a 'Deflector Shield' for protection.", "craft", "basic_shield", 1, 2500, 200, "m025"],
		["m025", "Refining Mastery", "Research 'Efficient Smelting' for alloys.", "research", "smelting", 1, 5000, 500, "m026"],
		["m026", "Master Constructor", "Research 'Shipwright I' for hull reinforcement.", "research", "shipwright_1", 1, 5000, 500, "m027"],
		["m027", "Scanning Horizon", "Unlock 'Sector Alpha' via decryption.", "research", "sector_alpha_decryption", 1, 5000, 500, "m028"],
		["m028", "Deep Field Mining", "Mine 1000 Cassiterite in Sector Alpha.", "gather", "Cassiterite", 1000, 10000, 2000, "m029"],
		["m029", "Hardened Shell", "Craft 'Titanium Plating' in the Shipyard.", "craft", "titanium_armor", 1, 15000, 5000, "m030"],
		["m030", "Deep Space Comms", "Build a 'Fabricator' to prepare for the long journey.", "build", "fabricator", 1, 30000, 5000, "m031"],
		["m031", "Belt Bound", "Research 'Warp Drive Theory' to reach the Belt (Ends Tutorial).", "research", "warp_drive", 1, 50000, 10000, ""],
		["goal_001", "THE GREAT EXPEDITION", "Reach Sector Epsilon and discover the Primordial Core.", "discover", "sector_epsilon", 1, 0, 1000000, ""]
	]
	
	for i in range(m_list.size()):
		var entry = m_list[i]
		var mid = entry[0]
		var stage = i + 1 # missions index for scaling
		
		# Use hand-tuned base reward from mission definition
		# Apply gentle linear scaling: Base * (1 + 0.05 * stage)
		# This gives ~50% more at stage 10, ~150% more at stage 30
		# Much gentler than the old 1.15^stage which was causing hyperinflation
		var base_reward = entry[6]
		var scaled_reward = int(float(base_reward) * (1.0 + 0.05 * float(stage)))
		
		# Cutoff Enforcement: No mission follows the final tutorial step
		var next_id = entry[8]
		if mid == "m031": next_id = "" 
		
		var m_name = entry[1]
		if mid.begins_with("m"): m_name = "[TUTORIAL] " + m_name
		else: m_name = "[CORE GOAL] " + m_name
		
		missions[mid] = {
			"id": mid,
			"name": m_name,
			"description": entry[2],
			"type": entry[3],
			"target": entry[4],
			"target_qty": entry[5],
			"reward_cr": scaled_reward,
			"reward_xp": entry[7],
			"next_mission": next_id,
			"current_qty": 0.0,
			"multi_progress": {}, # For gather_multi
			"completed": false,
			"claimed": false,
			"active": (mid == "m001" or mid.begins_with("goal")) # Tutorial starts at m001, Core Goals always active
		}
		if missions[mid]["active"]:
			active_missions.append(mid)
	
	mission_updated.emit()

func _on_element_added(symbol, amount):
	_update_progress("gather", symbol, amount)
	_update_multi_progress(symbol, amount)

func _on_currency_added(type, amount):
	_update_progress("sell", type, amount)

func _on_tech_unlocked(tech_id):
	_update_progress("research", tech_id, 1)

func _on_module_crafted(module_id):
	_update_progress("craft", module_id, 1)

func _on_enemy_defeated(enemy_id):
	_update_progress("defeat", enemy_id, 1)

func _update_progress(type, target, amount):
	for mid in active_missions:
		var m = missions[mid]
		if not m["completed"] and m["type"] == type and m["target"] == target:
			m["current_qty"] += amount
			print("[MissionDebug] ID: %s, Progress: %d/%d (added %d)" % [mid, m["current_qty"], m["target_qty"], amount])
			check_completion(m)
			mission_updated.emit()

func _update_multi_progress(symbol, amount):
	for mid in active_missions:
		var m = missions[mid]
		if not m["completed"] and m["type"] == "gather_multi":
			if symbol in m["target"]:
				var current = m["multi_progress"].get(symbol, 0.0)
				var to_add = min(amount, m["target"][symbol] - current)
				if to_add > 0:
					m["multi_progress"][symbol] = current + to_add
					m["current_qty"] += to_add
					print("[MissionDebug] ID: %s, Multi-Progress: %d/%d (added %d %s)" % [mid, m["current_qty"], m["target_qty"], to_add, symbol])
				
				# Check overall completion
				var all_done = true
				for s in m["target"]:
					if m["multi_progress"].get(s, 0.0) < m["target"][s]:
						all_done = false
						break
				if all_done:
					check_completion(m)
				
				mission_updated.emit()


func check_completion(mission):
	if mission["current_qty"] >= mission["target_qty"]:
		mission["current_qty"] = mission["target_qty"]
		mission["completed"] = true

func claim_reward(mission_id) -> bool:
	if not mission_id in missions: return false
	var m = missions[mission_id]
	if m["completed"] and not m["claimed"]:
		m["claimed"] = true
		
		# Remove from active list
		active_missions.erase(mission_id)
		
		# Grant Rewards
		if m["reward_cr"] > 0:
			GameState.resources.add_currency("credits", m["reward_cr"])
		
		# Auto-unlock next mission
		if m["next_mission"] != "" and m["next_mission"] in missions:
			var next_id = m["next_mission"]
			missions[next_id]["active"] = true
			if not next_id in active_missions:
				active_missions.append(next_id)
		
		sync_progress() # Sync the new mission immediately
		mission_updated.emit()
		return true
	return false

func get_save_data_manager() -> Dictionary:
	var m_data = {}
	for mid in missions:
		var m = missions[mid]
		m_data[mid] = {
			"current_qty": m["current_qty"],
			"multi_progress": m["multi_progress"],
			"completed": m["completed"],
			"claimed": m["claimed"],
			"active": m["active"]
		}
	return {"missions": m_data}

func sync_progress():
	if not GameState.resources: return
	
	var changed = false
	for mid in active_missions:
		var m = missions[mid]
		if m["completed"]: continue
		
		var old_qty = m["current_qty"]
		
		if m["type"] == "gather":
			var inv_qty = GameState.resources.get_element_amount(m["target"])
			# Persistence: Only update if it helps progression or if we haven't hit completion yet
			m["current_qty"] = max(m["current_qty"], min(inv_qty, m["target_qty"]))
		
		elif m["type"] == "gather_multi":
			for s in m["target"]:
				var inv_qty = GameState.resources.get_element_amount(s)
				var req = m["target"][s]
				var prog = min(inv_qty, req)
				m["multi_progress"][s] = max(m["multi_progress"].get(s, 0.0), prog)
			
			# Recalculate total current_qty from locked-in sub-progress
			var total_p = 0.0
			for s in m["multi_progress"]:
				total_p += m["multi_progress"][s]
			m["current_qty"] = total_p
		
		elif m["type"] == "research":
			if GameState.research_manager.is_tech_unlocked(m["target"]):
				m["current_qty"] = 1
				
		elif m["type"] == "craft":
			var inv_count = GameState.shipyard_manager.module_inventory.get(m["target"], 0)
			# Also check if equipped
			for slot in GameState.shipyard_manager.loadout:
				if GameState.shipyard_manager.loadout[slot] == m["target"]:
					inv_count += 1
			m["current_qty"] = max(m["current_qty"], min(inv_count, m["target_qty"]))

		if m["current_qty"] != old_qty:
			changed = true
			
		check_completion(m)
	
	if changed:
		mission_updated.emit()

func load_save_data_manager(data: Dictionary):
	if data.is_empty(): return
	var m_data = data.get("missions", {})
	active_missions.clear()
	for mid in m_data:
		if mid in missions:
			var saved = m_data[mid]
			var m = missions[mid]
			m["current_qty"] = saved.get("current_qty", 0.0)
			m["multi_progress"] = saved.get("multi_progress", {})
			m["completed"] = saved.get("completed", false)
			m["claimed"] = saved.get("claimed", false)
			m["active"] = saved.get("active", false)
			if m["active"] and not m["claimed"]:
				active_missions.append(mid)

func reset():
	init_missions()

func has_progress() -> bool:
	for mid in missions:
		var m = missions[mid]
		if m["claimed"] or m["completed"]:
			return true
	return false
	
