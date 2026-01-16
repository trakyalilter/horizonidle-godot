extends PanelContainer

var parent_ui: Node
var manager: RefCounted

@onready var type_lbl = $MarginContainer/VBoxContainer/TypeLabel
@onready var name_lbl = $MarginContainer/VBoxContainer/HBox/VBox/NameLabel
@onready var status_lbl = $MarginContainer/VBoxContainer/HBox/VBox/StatusLabel
@onready var icon_lbl = $MarginContainer/VBoxContainer/HBox/IconLabel

func setup(p_ui, p_manager):
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
	
	var active_ammo = manager.active_ammo
	
	if active_ammo != "":
		# We should get the ammo name from somewhere. 
		# For now we'll match it manually or use ElementDB.
		var a_name = "Unknown Rounds"
		match active_ammo:
			"SlugT1": a_name = "Ferrite Rounds"
			"SlugT2": a_name = "Tungsten Sabot"
			"CellT1": a_name = "Focus Crystal"
			"CellT2": a_name = "Plasma Cell"
			
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
		status_lbl.text = "No rounds loaded"
		status_lbl.modulate = Color(0.33, 0.33, 0.33)
		icon_lbl.text = "☖"
		icon_lbl.modulate = Color(0.33, 0.33, 0.33)

func _get_drag_data(_at_position):
	var active_ammo = manager.active_ammo
	if active_ammo == "": return null
	
	var drag_data = {
		"type": "unequip_ammo",
		"ammo_id": active_ammo
	}
	
	# Visual Preview: Use a real ammo slot instance
	var preview = load("res://scenes/ui/designer_ammo_slot_widget.tscn").instantiate()
	preview.setup(parent_ui, manager)
	preview.modulate = Color(1, 0.5, 0.5, 0.8) # Reddish tint for unequip
	preview.custom_minimum_size = Vector2(250, 80)
	
	set_drag_preview(preview)
	return drag_data

func _can_drop_data(at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "ammo"

func _drop_data(at_position, data):
	var ammo_id = data.get("ammo_id")
	manager.active_ammo = ammo_id
	parent_ui.trigger_refresh()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			manager.active_ammo = ""
			parent_ui.trigger_refresh()
