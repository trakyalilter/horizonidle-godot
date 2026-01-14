extends PanelContainer

var hid: String
var data: Dictionary
var manager: RefCounted
var parent_ui: Node

@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var slot_lbl = $MarginContainer/VBoxContainer/SlotsLabel
@onready var cost_lbl = $MarginContainer/VBoxContainer/CostLabel
@onready var btn = $MarginContainer/VBoxContainer/Button

func setup(p_hid: String, p_data: Dictionary, p_manager, p_parent):
	hid = p_hid
	data = p_data
	manager = p_manager
	parent_ui = p_parent
	
	name_lbl.text = data["name"]
	slot_lbl.text = "Slots: %d" % data["slots"].size()
	
	var cost_str = ""
	for res in data["cost"]:
		cost_str += "%d %s\n" % [data["cost"][res], res.capitalize()]
	cost_lbl.text = cost_str.strip_edges()
	
func _process(delta):
	update_state()

func update_state():
	if manager.active_hull == hid:
		btn.text = "Active"
		btn.disabled = true
		modulate = Color(1.2, 1.2, 1)
	else:
		btn.text = "Construct"
		# Check afford
		var affordable = true
		for res in data["cost"]:
			var qty = data["cost"][res]
			if res == "credits":
				if GameState.resources.get_currency("credits") < qty: affordable = false
			else:
				if GameState.resources.get_element_amount(res) < qty: affordable = false
		
		btn.disabled = not affordable
		modulate = Color(1, 1, 1)

func _on_button_pressed():
	if manager.construct_hull(hid):
		parent_ui.update_ui()
