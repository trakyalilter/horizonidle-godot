extends PanelContainer

var slot_idx: int
var slot_type: String
var parent_ui: Node
var manager: RefCounted

@onready var type_lbl = $MarginContainer/VBoxContainer/TypeLabel
@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var icon_lbl = $MarginContainer/VBoxContainer/IconLabel
@onready var option_btn = $MarginContainer/VBoxContainer/OptionButton

func setup(idx: int, s_type: String, p_ui, p_manager):
	slot_idx = idx
	slot_type = s_type
	parent_ui = p_ui
	manager = p_manager
	
	type_lbl.text = "SLOT %d: %s" % [idx + 1, slot_type.to_upper()]
	refresh_state()

func refresh_state():
	option_btn.clear()
	option_btn.add_item("Change...", 0)
	option_btn.set_item_metadata(0, null)
	
	var equipped_id = manager.loadout.get(slot_idx)
	
	# Current Item Display
	if equipped_id:
		var m_data = manager.modules.get(equipped_id)
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

func _on_option_button_item_selected(index):
	var data = option_btn.get_item_metadata(index)
	if data == "unequip":
		manager.unequip_slot(slot_idx)
		parent_ui.trigger_refresh()
	elif data:
		if manager.equip_module(slot_idx, data):
			parent_ui.trigger_refresh()
	
	# Reset dropdown to "Change..."
	option_btn.select(0)
