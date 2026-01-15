extends PanelContainer

var aid: String
var data: Dictionary
var manager: RefCounted
var parent_ui: Node

@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var lvl_lbl = $MarginContainer/VBoxContainer/LevelLabel
@onready var loot_lbl = $MarginContainer/VBoxContainer/LootLabel
@onready var btn = $MarginContainer/VBoxContainer/Button
@onready var status_lbl = $MarginContainer/VBoxContainer/StatusLabel

func setup(p_aid: String, p_data: Dictionary, p_manager, p_parent):
	aid = p_aid
	data = p_data
	manager = p_manager
	parent_ui = p_parent
	
	name_lbl.text = data["name"]
	var req = data.get("level_req", 1)
	lvl_lbl.text = "Lvl %d" % req
	
	var loot_text = ""
	for entry in data["loot_table"]:
		# [Element, Chance, Min, Max]
		loot_text += "%s: %d-%d\n" % [entry[0], entry[2], entry[3]]
	loot_lbl.text = loot_text.strip_edges()

func _on_button_pressed():
	if manager.is_active and manager.current_action_id == aid:
		manager.stop_action()
	else:
		GameState.set_active_manager(manager)
		manager.start_action(aid)
	
	parent_ui.update_ui()

func update_state():
	var is_this_active = (manager.is_active and manager.current_action_id == aid)
	
	var lvl = manager.get_level()
	var req = data.get("level_req", 1)
	
	var unlocked = true
	var status_msg = ""
	
	if lvl < req:
		unlocked = false
		status_msg = "Level Locked"
	
	# Research Check
	if "research_req" in data and data["research_req"]:
		if GameState.research_manager and not GameState.research_manager.is_tech_unlocked(data["research_req"]):
			unlocked = false
			status_msg = "Research Locked"
	
	if unlocked:
		status_lbl.text = ""
		btn.disabled = false
		if is_this_active:
			btn.text = "Stop"
			btn.modulate = Color(1.0, 0.4, 0.4) # Red-ish
			modulate = Color(1.2, 1, 1) # Highlight
		else:
			btn.text = "Start"
			btn.modulate = Color(1, 1, 1)
			modulate = Color(1, 1, 1)
	else:
		btn.text = "Locked"
		btn.disabled = true
		status_lbl.text = status_msg
		modulate = Color(0.7, 0.7, 0.7)
