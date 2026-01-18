extends PanelContainer

var parent_ui: Node
var manager: RefCounted
var slot_idx: int = -1

@onready var type_lbl = $MarginContainer/VBoxContainer/TypeLabel
@onready var name_lbl = $MarginContainer/VBoxContainer/HBox/VBox/NameLabel
@onready var status_lbl = $MarginContainer/VBoxContainer/HBox/VBox/StatusLabel
@onready var icon_lbl = $MarginContainer/VBoxContainer/HBox/IconLabel

func setup(p_slot_idx, p_ui, p_manager):
	slot_idx = p_slot_idx
	parent_ui = p_ui
	manager = p_manager
	
	if is_node_ready():
		refresh_state()

func _ready():
	type_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS["shipyard"])
	UITheme.apply_card_style(self, "shipyard")
	refresh_state()

func refresh_state():
	if not is_node_ready(): return
	if not manager: manager = GameState.shipyard_manager
	if not manager: return
	
	# Get ammo for THIS specific slot
	var active_ammo = manager.ammo_loadout.get(slot_idx, "")
	
	type_lbl.text = "WEAPON #%d AMMUNITION" % (slot_idx + 1)
	
	if active_ammo != "":
		var a_name = ElementDB.get_display_name(active_ammo)
		var qty = GameState.resources.get_element_amount(active_ammo)
		name_lbl.text = a_name
		name_lbl.modulate = Color.CYAN
		status_lbl.text = "Available: %d units" % qty
		status_lbl.modulate = Color.CYAN if qty > 0 else Color.RED
		icon_lbl.text = "☗"
		icon_lbl.modulate = Color.CYAN
	else:
		name_lbl.text = "EMPTY"
		name_lbl.modulate = Color(0.33, 0.33, 0.33)
		status_lbl.text = "No specialized rounds"
		status_lbl.modulate = Color(0.33, 0.33, 0.33)
		icon_lbl.text = "☖"
		icon_lbl.modulate = Color(0.33, 0.33, 0.33)

func _get_drag_data(_at_position):
	var active_ammo = manager.ammo_loadout.get(slot_idx, "")
	if active_ammo == "": return null
	
	var drag_data = {
		"type": "unequip_ammo",
		"slot_idx": slot_idx,
		"ammo_id": active_ammo
	}
	
	# Visual Preview
	var preview = load("res://scenes/ui/designer_ammo_slot_widget.tscn").instantiate()
	preview.setup(slot_idx, parent_ui, manager)
	preview.modulate = Color(1, 0.5, 0.5, 0.8) 
	preview.custom_minimum_size = Vector2(250, 80)
	
	set_drag_preview(preview)
	return drag_data

func _can_drop_data(at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "ammo"

func _drop_data(at_position, data):
	var ammo_id = data.get("ammo_id")
	manager.set_slot_ammo(slot_idx, ammo_id)
	parent_ui.trigger_refresh()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			manager.set_slot_ammo(slot_idx, "")
			parent_ui.trigger_refresh()
