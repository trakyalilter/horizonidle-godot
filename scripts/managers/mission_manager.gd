extends RefCounted

var missions = {}
var active_missions = []

# Class-like dictionary structure for Mission? Or just Dict?
# Using Dict for simplicity as per other managers.

func _init():
	init_missions()
	# Connect Signals
	# Since GameState is Autoload, we can access it.
	# But Resources is a child of GameState (or var in GameState).
	pass
	
func connect_signals():
	if GameState.resources:
		if not GameState.resources.element_added.is_connected(_on_element_added):
			GameState.resources.element_added.connect(_on_element_added)
		if not GameState.resources.currency_added.is_connected(_on_currency_added):
			GameState.resources.currency_added.connect(_on_currency_added)

func init_missions():
	var data = [
		["m001", "First Steps", "Excavate 10 units of Dirt.", "gather", "Dirt", 10, 10, 5],
		["m002", "Hydration", "Pump 10 liters of Water.", "gather", "Water", 10, 15, 5],
		["m003", "Refining", "Produce 5 Silicon.", "gather", "Si", 5, 20, 10],
		["m004", "Heavy Metal", "Produce 2 Iron.", "gather", "Fe", 2, 25, 10],
		["m005", "Merchant", "Earn 50 Credits from sales.", "sell", "credits", 50, 50, 0],
		["m006", "Forestry", "Harvest 5 Wood.", "gather", "Wood", 5, 30, 20]
	]
	
	for entry in data:
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
			"current_qty": 0.0,
			"completed": false,
			"claimed": false
		}
		active_missions.append(mid)

func _on_element_added(symbol, amount):
	for mid in active_missions:
		var m = missions[mid]
		if not m["completed"] and m["type"] == "gather" and m["target"] == symbol:
			m["current_qty"] += amount
			check_completion(m)

func _on_currency_added(type, amount):
	for mid in active_missions:
		var m = missions[mid]
		if not m["completed"] and m["type"] == "sell" and m["target"] == type:
			m["current_qty"] += amount
			check_completion(m)

func check_completion(mission):
	if mission["current_qty"] >= mission["target_qty"]:
		mission["current_qty"] = mission["target_qty"]
		mission["completed"] = true
		# Optional: Toast notification?

func claim_reward(mission_id) -> bool:
	if not mission_id in missions: return false
	var m = missions[mission_id]
	if m["completed"] and not m["claimed"]:
		m["claimed"] = true
		
		# Grant Rewards
		if m["reward_cr"] > 0:
			GameState.resources.add_currency("credits", m["reward_cr"])
			
		# XP? Which skill? 
		# Python code had reward_xp, but didn't seem to apply it to a specific skill.
		# Maybe generic XP? Or omitted for now.
		return true
	return false

func get_save_data_manager() -> Dictionary:
	var m_data = {}
	for mid in missions:
		var m = missions[mid]
		m_data[mid] = {
			"current_qty": m["current_qty"],
			"completed": m["completed"],
			"claimed": m["claimed"]
		}
	return {"missions": m_data}

func load_save_data_manager(data: Dictionary):
	if data.is_empty(): return
	var m_data = data.get("missions", {})
	for mid in m_data:
		if mid in missions:
			var saved = m_data[mid]
			var m = missions[mid]
			m["current_qty"] = saved.get("current_qty", 0.0)
			m["completed"] = saved.get("completed", false)
			m["claimed"] = saved.get("claimed", false)

func reset():
	missions.clear()
	active_missions.clear()
	init_missions()
