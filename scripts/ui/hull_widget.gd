extends PanelContainer

var hid: String
var data: Dictionary
var manager: RefCounted
var parent_ui: Node

@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var slot_lbl = $MarginContainer/VBoxContainer/SlotsLabel
@onready var cost_lbl = $MarginContainer/VBoxContainer/CostLabel
@onready var research_lbl = $MarginContainer/VBoxContainer/ResearchLabel
@onready var btn = $MarginContainer/VBoxContainer/Button
@onready var ship_icon = $MarginContainer/VBoxContainer/ShipIcon

func setup(p_hid: String, p_data: Dictionary, p_manager, p_parent):
	hid = p_hid
	data = p_data
	manager = p_manager
	parent_ui = p_parent
	
	name_lbl.text = data["name"]
	name_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS["shipyard"])
	slot_lbl.text = "Slots: %d" % data["slots"].size()
	
	UITheme.apply_card_style(self, "shipyard")
	UITheme.apply_premium_button_style(btn, "shipyard")
	
	if data.has("visual"):
		ship_icon.texture = load(data["visual"])
	
	# Cost text handled dynamically in update_state
	cost_lbl.text = ""
	research_lbl.hide()
	
func _process(delta):
	update_state()

func update_state():
	if manager.active_hull == hid:
		btn.text = "Active"
		btn.disabled = true
		modulate = Color(1.2, 1.2, 1)
		research_lbl.hide()
	else:
		btn.text = "Construct"
		
		# Check Research Requirements
		var req_id = data.get("research_req")
		var tech_unlocked = GameState.research_manager.is_tech_unlocked(req_id)
		
		if not tech_unlocked:
			var tech_name = GameState.research_manager.tech_tree.get(req_id, {}).get("name", req_id)
			research_lbl.text = "Req: %s" % tech_name
			research_lbl.show()
			btn.disabled = true
			cost_lbl.hide()
			return
		else:
			research_lbl.hide()
			cost_lbl.show()

		# Check afford
		var affordable = true
		var cost_str = "[center]"
		
		for res in data["cost"]:
			var qty = data["cost"][res]
			var can_afford = false
			var color = "#ff5555" # Red
			
			if res == "credits":
				if GameState.resources.get_currency("credits") >= qty: 
					can_afford = true
					color = "#55ff55" # Green
			else:
				if GameState.resources.get_element_amount(res) >= qty: 
					can_afford = true
					color = "#55ff55"
			
			if not can_afford:
				affordable = false
				
			cost_str += "[color=%s]%s %s[/color]\n" % [color, FormatUtils.format_number(qty), ElementDB.get_display_name(res)]
		
		cost_str += "[/center]"
		cost_lbl.text = cost_str
		
		btn.disabled = not affordable
		modulate = Color(1, 1, 1)

func _on_button_pressed():
	manager.construct_hull(hid)
