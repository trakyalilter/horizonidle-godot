extends Control

@onready var hp_lbl = $VBoxContainer/StatsPanel/HBoxContainer/HPLabel
@onready var atk_lbl = $VBoxContainer/StatsPanel/HBoxContainer/AtkLabel
@onready var def_lbl = $VBoxContainer/StatsPanel/HBoxContainer/DefLabel
@onready var hull_grid = $VBoxContainer/TabContainer/Hulls/HullGrid
@onready var module_grid = $VBoxContainer/TabContainer/Modules/ModuleGrid

var manager: RefCounted
var hull_widget_scene = preload("res://scenes/ui/hull_widget.tscn")
var module_widget_scene = preload("res://scenes/ui/module_widget.tscn")
var widgets = []

func _ready():
	manager = GameState.shipyard_manager
	call_deferred("refresh_list")

func refresh_list():
	for child in hull_grid.get_children():
		child.queue_free()
	for child in module_grid.get_children():
		child.queue_free()
	widgets.clear()
	
	# Hulls
	var sorted_hulls = manager.hulls.keys()
	sorted_hulls.sort_custom(func(a,b): return manager.hulls[a]["cost"].get("credits",0) < manager.hulls[b]["cost"].get("credits",0))
	
	for hid in sorted_hulls:
		var w = hull_widget_scene.instantiate()
		hull_grid.add_child(w)
		w.setup(hid, manager.hulls[hid], manager, self)
		widgets.append(w)
		
	# Modules
	var sorted_mods = manager.modules.keys()
	sorted_mods.sort()
	
	for mid in sorted_mods:
		var w = module_widget_scene.instantiate()
		module_grid.add_child(w)
		w.setup(mid, manager.modules[mid], manager, self)
		widgets.append(w)

func _process(delta):
	update_ui()

func update_ui():
	if not manager: return
	
	# Update Stats
	hp_lbl.text = "Structure: %d / %d" % [manager.current_hp, manager.max_hp]
	atk_lbl.text = "Firepower: %d" % manager.attack
	def_lbl.text = "Shield: %d | Eva: %.1f%%" % [manager.defense, manager.evasion]
	
	# Widgets update via their own _process
