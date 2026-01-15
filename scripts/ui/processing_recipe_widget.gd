extends PanelContainer

var rid: String
var recipe: Dictionary
var manager: RefCounted
var parent_ui: Node

@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var lvl_lbl = $MarginContainer/VBoxContainer/LevelLabel
@onready var in_lbl = $MarginContainer/VBoxContainer/InputLabel
@onready var out_lbl = $MarginContainer/VBoxContainer/OutputLabel
@onready var btn = $MarginContainer/VBoxContainer/Button
@onready var prog_bar = $MarginContainer/VBoxContainer/ProgressBar

func setup(p_rid: String, p_data: Dictionary, p_manager, p_parent):
	rid = p_rid
	recipe = p_data
	manager = p_manager
	parent_ui = p_parent
	
	name_lbl.text = recipe["name"]
	lvl_lbl.text = "Lvl %d" % recipe.get("level_req", 1)
	
	# Input text is handled dynamically in update_state for coloring
	in_lbl.text = ""
	
	var out_str = ""
	if "output" in recipe:
		for item in recipe["output"]:
			out_str += "%d %s\n" % [recipe["output"][item], item]
	# Ignore output table text for simplicity as per Python UI, or add custom logic
	out_lbl.text = out_str.strip_edges()

func _on_button_pressed():
	if manager.is_active and manager.current_recipe_id == rid:
		manager.stop_action()
	else:
		GameState.set_active_manager(manager)
		manager.start_action(rid)
	parent_ui.update_ui()

func update_state():
	var is_this_active = (manager.is_active and manager.current_recipe_id == rid)
	var has_ingredients = true # Will be re-evaluated per item
	
	# Rebuild Ingredient String with Colors
	# We do this every update to reflect real-time amounts
	var in_str = "[center]"
	var inputs = recipe["input"]
	var missing_any = false
	
	for item in inputs:
		var req_qty = inputs[item]
		var avail_qty = GameState.resources.get_element_amount(item)
		var color_hex = "#ff5555" # Red
		
		if avail_qty >= req_qty:
			color_hex = "#55ff55" # Green
		else:
			missing_any = true
			
		in_str += "[color=%s]%d %s[/color]\n" % [color_hex, req_qty, item]
	
	in_str += "[/center]"
	in_lbl.text = in_str
	
	has_ingredients = not missing_any

	var lvl_req = recipe.get("level_req", 1)
	var has_level = manager.get_level() >= lvl_req
	
	# Research Check
	var has_research = true
	if "research_req" in recipe:
		if GameState.research_manager:
			has_research = GameState.research_manager.is_tech_unlocked(recipe["research_req"])
	
	if is_this_active:
		btn.text = "Stop"
		btn.disabled = false
		modulate = Color(1.2, 1, 1)
		
		var speed_mult = manager.get_recipe_speed_multiplier(rid)
		var effective_duration = recipe["duration"] / speed_mult
		var prog = (manager.action_progress / effective_duration) * 100.0
		prog_bar.value = prog
	else:
		prog_bar.value = 0
		modulate = Color(1, 1, 1)
		
		if not has_research:
			btn.text = "Research Required"
			btn.disabled = true
		elif not has_level:
			btn.text = "Requires Lv %d" % lvl_req
			btn.disabled = true
		elif not has_ingredients:
			btn.text = "Missing Materials"
			btn.disabled = true
		else:
			btn.text = "Start"
			btn.disabled = false
