extends Control

@onready var level_label = $VBoxContainer/Header/LevelLabel
@onready var xp_label = $VBoxContainer/Header/XPLabel
@onready var xp_bar = $VBoxContainer/XPBar
@onready var refine_grid = $VBoxContainer/TabContainer/Refining/RefineGrid
@onready var ammo_grid = $VBoxContainer/TabContainer/Munitions/AmmoGrid

var manager: RefCounted
var recipe_widget_scene = preload("res://scenes/ui/processing_recipe_widget.tscn")
var widgets = []

func _ready():
	manager = GameState.processing_manager
	
	# Premium Styling
	UITheme.apply_tab_style($VBoxContainer/TabContainer, "engineering")
	UITheme.apply_card_style($VBoxContainer/TabContainer, "engineering")
	UITheme.apply_progress_bar_style(xp_bar, "engineering")
	
	call_deferred("refresh_recipes")

func refresh_recipes():
	for child in refine_grid.get_children():
		child.queue_free()
	for child in ammo_grid.get_children():
		child.queue_free()
	widgets.clear()
	
	var sorted_keys = manager.recipes.keys()
	sorted_keys.sort_custom(func(a, b): 
		var ra = manager.recipes[a]
		var rb = manager.recipes[b]
		if ra["level_req"] != rb["level_req"]:
			return ra["level_req"] < rb["level_req"]
		return ra["name"] < rb["name"]
	)
	
	for rid in sorted_keys:
		var data = manager.recipes[rid]
		var w = recipe_widget_scene.instantiate()
		var target_grid = refine_grid
		
		# Simple categorization logic
		if "slug" in rid or "cell" in rid or "rounds" in rid or "ammo" in rid:
			target_grid = ammo_grid
			
		target_grid.add_child(w)
		w.setup(rid, data, manager, self)
		widgets.append(w)

func get_widget_by_aid(rid_in: String) -> Control:
	for w in widgets:
		if w.get("rid") == rid_in:
			return w
	return null

func focus_tab(rid_in: String):
	if "slug" in rid_in or "cell" in rid_in or "rounds" in rid_in or "ammo" in rid_in:
		$VBoxContainer/TabContainer.current_tab = 1 # Munitions
	else:
		$VBoxContainer/TabContainer.current_tab = 0 # Refining

func _process(delta):
	update_ui()

func update_ui():
	if not manager: return
	
	level_label.text = "Level: %d" % manager.get_level()
	xp_label.text = "XP: %d" % int(manager.xp)
	xp_bar.value = manager.get_progress_to_next_level()
	
	for w in widgets:
		w.update_state()
	
	while not manager.events.is_empty():
		var ev = manager.events.pop_front()
		var type = ev[0]
		var text = ev[1]
		var target_id = ev[2]
		
		var target_w = null
		for w in widgets:
			if w.rid == target_id:
				target_w = w
				break
				
		if target_w:
			var color = Color(0.4, 0.9, 0.6)
			if type == "xp": color = Color(1.0, 0.8, 0.15)
			
			spawn_floating_text(text, color, target_w)

var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")

func spawn_floating_text(text, color, target_widget):
	var ft = floating_text_scene.instantiate()
	self.add_child(ft)
	
	var center = target_widget.global_position + target_widget.size / 2.0
	var local_pos = center - self.global_position
	local_pos += Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	ft.setup(text, color, local_pos)
