extends Control

@onready var hp_lbl = $VBoxContainer/StatsPanel/HBoxContainer/HPLabel
@onready var atk_lbl = $VBoxContainer/StatsPanel/HBoxContainer/AtkLabel
@onready var def_lbl = $VBoxContainer/StatsPanel/HBoxContainer/DefLabel
@onready var hull_grid = $VBoxContainer/TabContainer/Hulls/HullGrid
@onready var kinetic_grid = $VBoxContainer/TabContainer/Modules/Weapons/WeaponCategorizer/KineticGrid
@onready var energy_grid = $VBoxContainer/TabContainer/Modules/Weapons/WeaponCategorizer/EnergyGrid
@onready var shield_grid = $VBoxContainer/TabContainer/Modules/Shields/ShieldGrid
@onready var engine_grid = $VBoxContainer/TabContainer/Modules/Engines/EngineGrid
@onready var battery_grid = $VBoxContainer/TabContainer/Modules/Batteries/BatteryGrid

var repair_btn: Button
var manager: RefCounted
var hull_widget_scene = preload("res://scenes/ui/hull_widget.tscn")
var module_widget_scene = preload("res://scenes/ui/module_widget.tscn")
var widgets = []

func _ready():
	manager = GameState.shipyard_manager
	
	# Premium Styling
	UITheme.apply_tab_style($VBoxContainer/TabContainer, "shipyard")
	UITheme.apply_card_style($VBoxContainer/TabContainer, "shipyard")
	
	# UI Robustness: Ensure parent containers don't block mouse events
	$VBoxContainer/StatsPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$VBoxContainer/StatsPanel/HBoxContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Create Repair Button dynamically
	repair_btn = Button.new()
	repair_btn.text = "Repair (0 Cr)"
	repair_btn.custom_minimum_size = Vector2(120, 30) # Ensure it's clickable
	repair_btn.mouse_filter = Control.MOUSE_FILTER_STOP # Detect clicks
	repair_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	repair_btn.pressed.connect(_on_repair_pressed)
	$VBoxContainer/StatsPanel/HBoxContainer.add_child(repair_btn)
	UITheme.apply_premium_button_style(repair_btn, "shipyard")
	
	call_deferred("refresh_list")

func _process(_delta):
	_update_repair_button()
	_update_hp_display()

func _update_repair_button():
	if not repair_btn: return
	var cost = manager.get_repair_cost()
	if cost == 0:
		repair_btn.text = "Hull OK"
		repair_btn.disabled = true
	else:
		repair_btn.text = "Repair (%d Cr)" % cost
		repair_btn.disabled = not manager.can_repair()

func _update_hp_display():
	if hp_lbl:
		hp_lbl.text = "HP: %d / %d" % [manager.current_hp, manager.max_hp]

func _on_repair_pressed():
	print("[UI] Repair button pressed!")
	if manager.repair_hull():
		print("[UI] Repair successful, refreshing UI...")
		# We don't need a full refresh_list, but let's ensure labels update immediately
		_update_hp_display()
		_update_repair_button()


func refresh_list():
	for child in hull_grid.get_children(): child.queue_free()
	for child in kinetic_grid.get_children(): child.queue_free()
	for child in energy_grid.get_children(): child.queue_free()
	for child in shield_grid.get_children(): child.queue_free()
	for child in engine_grid.get_children(): child.queue_free()
	for child in battery_grid.get_children(): child.queue_free()
	widgets.clear()
	
	# Hulls
	var sorted_hulls = manager.hulls.keys()
	sorted_hulls.sort_custom(func(a,b): return manager.hulls[a]["cost"].get("credits",0) < manager.hulls[b]["cost"].get("credits",0))
	
	for hid in sorted_hulls:
		var w = hull_widget_scene.instantiate()
		hull_grid.add_child(w)
		w.setup(hid, manager.hulls[hid], manager, self)
		widgets.append(w)
		
	# Modules Categorization
	var sorted_mods = manager.modules.keys()
	sorted_mods.sort()
	
	for mid in sorted_mods:
		var data = manager.modules[mid]
		var type = data.get("slot_type", "weapon")
		var target_grid = null
		
		match type:
			"weapon":
				var stats = data.get("stats", {})
				if stats.get("atk_kinetic", 0) > stats.get("atk_energy", 0):
					target_grid = kinetic_grid
				else:
					target_grid = energy_grid
			"shield": target_grid = shield_grid
			"engine": target_grid = engine_grid
			"battery": target_grid = battery_grid
			_: target_grid = energy_grid # Default
		
		if target_grid == null: continue
		
		var w = module_widget_scene.instantiate()
		target_grid.add_child(w)
		w.setup(mid, data, manager, self)
		widgets.append(w)

func get_module_widget(module_id: String) -> Control:
	for w in widgets:
		if w.get("mid") == module_id:
			return w
	return null

func focus_module_tab(module_id: String):
	if not module_id in manager.modules: return
	var data = manager.modules[module_id]
	var type = data.get("slot_type", "weapon")
	
	# Main Tab to Modules
	$VBoxContainer/TabContainer.current_tab = 1
	
	# Sub Tab
	var sub_tabs = $VBoxContainer/TabContainer/Modules
	match type:
		"weapon": sub_tabs.current_tab = 0
		"shield": sub_tabs.current_tab = 1
		"engine": sub_tabs.current_tab = 2
		"battery": sub_tabs.current_tab = 3
