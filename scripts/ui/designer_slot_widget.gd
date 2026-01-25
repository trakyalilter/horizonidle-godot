extends PanelContainer

var slot_idx: int
var slot_type: String
var parent_ui: Node
var manager: RefCounted
var is_occupied: bool = false

@onready var type_lbl = $MarginContainer/VBoxContainer/TypeLabel
@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var icon_lbl = $MarginContainer/VBoxContainer/IconLabel
@onready var option_btn = $MarginContainer/VBoxContainer/OptionButton

func setup(idx: int, s_type: String, p_ui, p_manager):
	slot_idx = idx
	slot_type = s_type
	parent_ui = p_ui
	manager = p_manager
	
	if is_node_ready():
		refresh_state()

func _ready():
	UITheme.apply_card_style(self, "shipyard")
	# We'll hide the option button in setup to favor Drag & Drop
	option_btn.visible = false 
	refresh_state()

func refresh_state():
	if not is_node_ready(): return
	if not manager: manager = GameState.shipyard_manager
	if not manager: return
	
	type_lbl.text = "SLOT %d: %s" % [slot_idx + 1, slot_type.to_upper()]
	type_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS["shipyard"])
	
	option_btn.clear()
	option_btn.add_item("Change...", 0)
	option_btn.set_item_metadata(0, null)
	
	var equipped_id = manager.loadout.get(slot_idx)
	is_occupied = equipped_id != null
	
	# Current Item Display
	if equipped_id:
		var m_data = manager.modules.get(equipped_id)
		var en_load = m_data["stats"].get("energy_load", 0)
		
		if en_load > 0:
			name_lbl.text = "%s (-%d En)" % [m_data["name"], en_load]
		else:
			name_lbl.text = m_data["name"]
			
		name_lbl.modulate = Color(0, 0.73, 0.83) # Cyan
		icon_lbl.text = "▣"
		icon_lbl.modulate = Color(0, 0.73, 0.83)
		
		# Option to Unequip
		option_btn.add_item("Unequip", 1)
		option_btn.set_item_metadata(1, "unequip")
	else:
		name_lbl.text = "EMPTY"
		name_lbl.modulate = Color(0.33, 0.33, 0.33) # Dark Gray
		icon_lbl.text = "⛝"
		icon_lbl.modulate = Color(0.33, 0.33, 0.33)

	# Populate Inventory Options
	var inv = manager.module_inventory
	var idx_counter = 2
	for mid in inv:
		var count = inv[mid]
		if count > 0 and mid in manager.modules:
			var m_data = manager.modules[mid]
			if m_data["slot_type"] == slot_type:
				option_btn.add_item("%s (x%d)" % [m_data["name"], count], idx_counter)
				option_btn.set_item_metadata(option_btn.item_count - 1, mid)
				idx_counter += 1

func _get_drag_data(_at_position):
	var equipped_id = manager.loadout.get(slot_idx)
	if not equipped_id: return null
	
	var data = manager.modules.get(equipped_id)
	
	var drag_data = {
		"type": "unequip_module",
		"slot_idx": slot_idx,
		"mid": equipped_id,
		"slot_type": slot_type
	}
	
	# Visual Preview: Use a real slot instance
	var preview = load("res://scenes/ui/designer_slot_widget.tscn").instantiate()
	preview.setup(slot_idx, slot_type, parent_ui, manager)
	preview.modulate = Color(1, 0.5, 0.5, 0.8) # Reddish tint for unequip
	preview.custom_minimum_size = Vector2(100, 100) # Slightly smaller than original
	
	set_drag_preview(preview)
	return drag_data

func _can_drop_data(at_position, data):
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "module":
		return data.get("slot_type") == slot_type
	return false

func _drop_data(at_position, data):
	var mid = data.get("mid")
	if manager.equip_module(slot_idx, mid):
		UITheme.trigger_circuit_surge(self)
		parent_ui.trigger_refresh()

func _on_option_button_item_selected(index):
	var data = option_btn.get_item_metadata(index)
	
	if data == "unequip":
		manager.unequip_slot(slot_idx)
		parent_ui.trigger_refresh()
	elif data:
		if manager.equip_module(slot_idx, data):
			UITheme.trigger_circuit_surge(self)
			parent_ui.trigger_refresh()
	
	option_btn.select(0)

# Optional: Handing unequip via right click
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			manager.unequip_slot(slot_idx)
			parent_ui.trigger_refresh()
