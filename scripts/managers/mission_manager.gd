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
		["m001", "Stranded in Orbit", "Gather 500 Dirt to begin basic repairs.", "gather", "Dirt", 500, 200, 50, "m002"],
		["m002", "Analytical Breakthrough", "Research 'Basic Engineering' to unlock refining.", "research", "basic_engineering", 1, 100, 50, "m003"],
		["m003", "Pump Master", "Research 'Fluid Dynamics' to unlock water collection.", "research", "fluid_dynamics", 1, 100, 50, "m004"],
		["m004", "Deep Space Harvest", "Gather 500 Water and 100 Spodumene.", "gather_multi", {"Water": 500, "Spodumene": 100}, 600, 300, 100, "m005"],
		["m005", "Core Selection", "Extract 100 Silicon, 80 Iron, and 50 Lithium.", "gather_multi", {"Si": 100, "Fe": 80, "Li": 50}, 230, 300, 100, "m006"],
		["m006", "Mobility Check", "Craft 'Ion Thrusters' in the Shipyard for evasion.", "craft", "basic_thruster", 1, 250, 100, "m007"],
		["m007", "Hull Integrity", "Research 'Energy Fields' to unlock shielding.", "research", "energy_shields", 1, 300, 150, "m008"],
		["m008", "Aegis System", "Craft a 'Deflector Shield' for defensive protection.", "craft", "basic_shield", 1, 400, 200, "m009"],
		["m009", "Power Storage", "Craft a 'Li-Ion Battery' to increase energy capacity.", "craft", "battery_t1", 1, 300, 150, "m010"],
		["m010", "Prototype Arsenal", "Craft a 'Mass Driver' to enable kinetic attacks.", "craft", "railgun_mk1", 1, 400, 200, "m011"],
		["m011", "Kinetic Munitions", "Produce 10 Ferrite Rounds for your new weapon.", "gather", "SlugT1", 10, 200, 100, "m012"],
		["m012", "Target Locked", "Defeat 1 Lunar Drone in Lunar Orbit.", "defeat", "lunar_drone", 1, 1000, 500, ""]
	]
	
	for entry in m_list:
		var mid = entry[0]
		missions[mid] = {
			"id": mid,
			"name": entry[1],
			"description": entry[2],
			"type": entry[3],
			"target": entry[4],
			"target_qty": entry[5],
			"reward_cr": entry[6],
			"reward_xp": entry[7],
			"next_mission": entry[8],
			"current_qty": 0.0,
			"multi_progress": {}, # For gather_multi
			"completed": false,
			"claimed": false,
			"active": (mid == "m001") # Only the first one is active initially
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
			m["current_qty"] = min(inv_qty, m["target_qty"])
		
		elif m["type"] == "gather_multi":
			var total_p = 0.0
			var all_done = true
			for s in m["target"]:
				var inv_qty = GameState.resources.get_element_amount(s)
				var req = m["target"][s]
				var prog = min(inv_qty, req)
				m["multi_progress"][s] = prog
				total_p += prog
				if prog < req: all_done = false
			m["current_qty"] = total_p
			# Note: all_done check handled by check_completion
			
		elif m["type"] == "research":
			if GameState.research_manager.is_tech_unlocked(m["target"]):
				m["current_qty"] = 1
				
		elif m["type"] == "craft":
			var inv_count = GameState.shipyard_manager.module_inventory.get(m["target"], 0)
			# Also check if equipped
			for slot in GameState.shipyard_manager.loadout:
				if GameState.shipyard_manager.loadout[slot] == m["target"]:
					inv_count += 1
			m["current_qty"] = min(inv_count, m["target_qty"])

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
	
