extends Control

@onready var level_label = $VBoxContainer/Header/LevelLabel
@onready var xp_label = $VBoxContainer/Header/XPLabel
@onready var xp_bar = $VBoxContainer/XPBar
@onready var progress_bar = $VBoxContainer/ProgressBar
@onready var grid = $VBoxContainer/ScrollContainer/GridContainer

var manager: RefCounted
var action_widget_scene = preload("res://scenes/ui/gathering_action_widget.tscn")
var widgets = []

func _ready():
	manager = GameState.gathering_manager
	call_deferred("refresh_actions")

func refresh_actions():
	for child in grid.get_children():
		child.queue_free()
	widgets.clear()
	
	# Sort keys or use sorted array if order matters (it usually does for gameplay)
	# Dict iteration order is preserved in Godot 4 but sorting by level is better
	var sorted_keys = manager.actions.keys()
	sorted_keys.sort_custom(func(a, b): return manager.actions[a]["level_req"] < manager.actions[b]["level_req"])
	
	for aid in sorted_keys:
		var data = manager.actions[aid]
		var w = action_widget_scene.instantiate()
		grid.add_child(w)
		w.setup(aid, data, manager, self)
		widgets.append(w)

func _process(delta):
	update_ui()

func update_ui():
	if not manager: return
	
	var lvl = manager.get_level()
	var xp = manager.xp
	
	level_label.text = "Level: %d" % lvl
	xp_label.text = "XP: %d" % int(xp)
	
	xp_bar.value = manager.get_progress_to_next_level()
	
	if manager.is_active:
		var speed_mult = manager.get_action_speed_multiplier(manager.current_action_id)
		var effective_duration = manager.action_duration / speed_mult
		var prog = (manager.action_progress / effective_duration) * 100.0
		progress_bar.value = prog
		progress_bar.visible = true
	else:
		progress_bar.visible = false

	for w in widgets:
		w.update_state()
		
	# Handle events for floating text
	while not manager.events.is_empty():
		var ev = manager.events.pop_front() # [type, text, target_id]
		var type = ev[0]
		var text = ev[1]
		var target_id = ev[2]
		
		# Find target widget
		var target_w = null
		for w in widgets:
			if w.aid == target_id:
				target_w = w
				break
		
		if target_w:
			var color = Color(0.4, 0.9, 0.6) # Default Green (Loot)
			if type == "xp": color = Color(1.0, 0.8, 0.15) # Gold
			
			spawn_floating_text(text, color, target_w)

var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")

func spawn_floating_text(text, color, target_widget):
	var ft = floating_text_scene.instantiate()
	self.add_child(ft)
	
	# Calc position relative to this control
	var center = target_widget.global_position + target_widget.size / 2.0
	var local_pos = center - self.global_position
	
	# Random offset
	local_pos += Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	# If target is not visible (scrolled out), maybe dont spawn? 
	# Or spawn and let it float. For simplicity, just spawn.
	
	ft.setup(text, color, local_pos)
