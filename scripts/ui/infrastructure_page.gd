extends Control

@onready var net_lbl = $VBoxContainer/EnergyDash/HBoxContainer/NetLabel
@onready var gen_lbl = $VBoxContainer/EnergyDash/HBoxContainer/VBoxContainer/GenLabel
@onready var cons_lbl = $VBoxContainer/EnergyDash/HBoxContainer/VBoxContainer/ConsLabel
@onready var grid = $VBoxContainer/ScrollContainer/GridContainer

var manager: RefCounted
var building_widget_scene = preload("res://scenes/ui/building_widget.tscn")
var widgets = []

func _ready():
	manager = GameState.infrastructure_manager
	call_deferred("refresh_list")

func refresh_list():
	for child in grid.get_children():
		child.queue_free()
	widgets.clear()
	
	for bid in manager.building_db:
		var data = manager.building_db[bid]
		var w = building_widget_scene.instantiate()
		grid.add_child(w)
		w.setup(bid, data, manager, self)
		widgets.append(w)

func _process(delta):
	# Update UI elements
	update_ui()
	# Manager ticks handled by GameState process

func update_ui():
	if not manager: return
	
	manager.recalc_energy() # Ensure fresh stats? Process loop handles actual logic
	
	var net = manager.net_energy
	var gen = manager.generation
	var cons = manager.consumption
	
	net_lbl.text = "NET: %+.1f kW" % net
	gen_lbl.text = "GEN: %.1f kW" % gen
	cons_lbl.text = "CONS: %.1f kW" % cons
	
	if net >= 0:
		net_lbl.add_theme_color_override("font_color", Color.CYAN)
	else:
		net_lbl.add_theme_color_override("font_color", Color.ORANGE_RED)
	
	# Widgets update themselves in _process usually, or we can force it
	for w in widgets:
		w.update_state()
