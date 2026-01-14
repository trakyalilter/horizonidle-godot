extends Control

@onready var ship_name_lbl = $VBoxContainer/InfoPanel/HBoxContainer/VBoxContainer/ShipNameLabel
@onready var stats_lbl = $VBoxContainer/InfoPanel/HBoxContainer/VBoxContainer/StatsLabel
@onready var grid_container = $VBoxContainer/ScrollContainer/GridContainer
@onready var ammo_opt = $VBoxContainer/AmmoPanel/HBoxContainer/AmmoOption
@onready var ammo_status_lbl = $VBoxContainer/AmmoPanel/HBoxContainer/StatusLabel

var manager: RefCounted
var slot_widget_scene = preload("res://scenes/ui/designer_slot_widget.tscn")
var current_hull_id = ""

func _ready():
	manager = GameState.shipyard_manager
	
	# Init Ammo
	ammo_opt.clear()
	ammo_opt.add_item("No Ammo (Weapons Offline)", 0)
	ammo_opt.set_item_metadata(0, "")
	ammo_opt.add_item("Ferrite Rounds (Kinetic)", 1)
	ammo_opt.set_item_metadata(1, "SlugT1")
	ammo_opt.add_item("Tungsten Sabot (Kinetic+)", 2)
	ammo_opt.set_item_metadata(2, "SlugT2")
	ammo_opt.add_item("Focus Crystal (Energy)", 3)
	ammo_opt.set_item_metadata(3, "CellT1")
	ammo_opt.add_item("Plasma Cell (Energy+)", 4)
	ammo_opt.set_item_metadata(4, "CellT2")
	
	call_deferred("trigger_refresh")

func trigger_refresh():
	update_header()
	rebuild_slots()
	update_ammo_ui()

func update_header():
	if manager.active_hull and manager.active_hull in manager.hulls:
		var h = manager.hulls[manager.active_hull]
		ship_name_lbl.text = "Active Class: " + h["name"]
		var e_max = GameState.resources.max_energy
		var e_used = manager.energy_used
		stats_lbl.text = "HP: %d | SHIELD: %d | ENG: %d/%d | ATK: %d | DEF: %d" % [manager.max_hp, manager.max_shield, e_used, e_max, manager.attack, manager.defense]
		
		if e_used > e_max:
			stats_lbl.modulate = Color(1, 0.3, 0.3) # Red Warning
		else:
			stats_lbl.modulate = Color(1, 1, 1)
	else:
		ship_name_lbl.text = "Structure: None (Escape Pod Mode)"
		stats_lbl.text = "HP: 10 | ATK: 0 | DEF: 0"

func rebuild_slots():
	# Clear existing
	if not grid_container: return
	for child in grid_container.get_children():
		child.queue_free()
		
	if not manager.active_hull in manager.hulls: return
	
	var h_data = manager.hulls[manager.active_hull]
	var slots = h_data["slots"]
	
	for i in range(slots.size()):
		var s_type = slots[i]
		var w = slot_widget_scene.instantiate()
		grid_container.add_child(w)
		w.setup(i, s_type, self, manager)

func _process(delta):
	update_ammo_ui()

func update_ammo_ui():
	# Update Selected
	var current_ammo = manager.active_ammo
	for i in range(ammo_opt.item_count):
		if ammo_opt.get_item_metadata(i) == current_ammo:
			ammo_opt.selected = i
			break
			
	# Update Status
	if current_ammo:
		var qty = GameState.resources.get_element_amount(current_ammo)
		ammo_status_lbl.text = "Available: %d" % qty
		if qty <= 0:
			ammo_status_lbl.modulate = Color.RED
		else:
			ammo_status_lbl.modulate = Color.CYAN
	else:
		ammo_status_lbl.text = "No Ammo Selected"
		ammo_status_lbl.modulate = Color.GRAY

func _on_ammo_option_item_selected(index):
	var ammo_id = ammo_opt.get_item_metadata(index)
	manager.active_ammo = ammo_id
	update_ammo_ui()
