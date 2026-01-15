extends PanelContainer

var mid: String
var data: Dictionary
var manager: RefCounted
var parent_ui: Node

@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var stats_lbl = $MarginContainer/VBoxContainer/StatsLabel
@onready var cost_lbl = $MarginContainer/VBoxContainer/CostLabel
@onready var owned_lbl = $MarginContainer/VBoxContainer/OwnedLabel
@onready var btn = $MarginContainer/VBoxContainer/Button

func setup(p_mid: String, p_data: Dictionary, p_manager, p_parent):
	mid = p_mid
	data = p_data
	manager = p_manager
	parent_ui = p_parent
	
	name_lbl.text = data["name"]
	name_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS["shipyard"])
	
	UITheme.apply_card_style(self, "shipyard")
	UITheme.apply_premium_button_style(btn, "shipyard")
	
	var s_txt = ""
	for k in data["stats"]:
		s_txt += "%s: %s\n" % [k.to_upper(), str(data["stats"][k])]
	stats_lbl.text = s_txt.strip_edges()
	
	# Cost text handled dynamically in update_state
	cost_lbl.text = ""

func _process(delta):
	update_state()

func update_state():
	var owned = manager.module_inventory.get(mid, 0)
	owned_lbl.text = "In Storage: %d" % owned
	
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
			
		cost_str += "[color=%s]%d %s[/color]\n" % [color, qty, ElementDB.get_display_name(res)]
	
	cost_str += "[/center]"
	cost_lbl.text = cost_str
	
	btn.disabled = not affordable

func _on_button_pressed():
	if manager.craft_module(mid):
		parent_ui.update_ui()
