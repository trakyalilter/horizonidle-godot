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

var manager: RefCounted
var hull_widget_scene = preload("res://scenes/ui/hull_widget.tscn")
var module_widget_scene = preload("res://scenes/ui/module_widget.tscn")
var widgets = []

func _ready():
	manager = GameState.shipyard_manager
	
	# Premium Styling
	UITheme.apply_tab_style($VBoxContainer/TabContainer, "shipyard")
	UITheme.apply_card_style($VBoxContainer/TabContainer, "shipyard")
	
	call_deferred("refresh_list")

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

func _process(delta):
	update_ui()

func update_ui():
	if not manager: return
	
	# Update Stats
	hp_lbl.text = "Structure: %d / %d" % [manager.current_hp, manager.max_hp]
	atk_lbl.text = "Firepower: %d" % manager.attack
	def_lbl.text = "Shield: %d | Eva: %.1f%%" % [manager.defense, manager.evasion]
	
	# Widgets update via their own _process
