extends PanelContainer

var bid: String
var data: Dictionary
var manager: RefCounted
var parent_ui: Node

@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var stats_lbl = $MarginContainer/VBoxContainer/StatsLabel
@onready var desc_lbl = $MarginContainer/VBoxContainer/DescLabel
@onready var cost_lbl = $MarginContainer/VBoxContainer/CostLabel
@onready var count_lbl = $MarginContainer/VBoxContainer/CountLabel
@onready var buy_btn = $MarginContainer/VBoxContainer/BuyButton

func setup(p_bid: String, p_data: Dictionary, p_manager, p_parent):
	bid = p_bid
	data = p_data
	manager = p_manager
	parent_ui = p_parent
	
	name_lbl.text = data["name"]
	desc_lbl.text = data["description"]
	
	var gen = data.get("energy_gen", 0.0)
	var cons = data.get("energy_cons", 0.0)
	var stats_text = ""
	if gen > 0: 
		stats_text = "+%.1f kW" % gen
		stats_lbl.add_theme_color_override("font_color", Color.YELLOW)
	elif cons > 0:
		stats_text = "-%.1f kW" % cons
		stats_lbl.add_theme_color_override("font_color", Color.TOMATO)
	stats_lbl.text = stats_text
	
	var cost_str = ""
	for res in data["cost"]:
		cost_str += "%d %s\n" % [data["cost"][res], res.capitalize()]
	cost_lbl.text = cost_str.strip_edges()

func _process(delta):
	# Refresh buildability
	update_state()

func update_state():
	var count = manager.get_building_count(bid)
	var max_count = data.get("max", 999)
	count_lbl.text = "Owned: %d / %d" % [count, max_count]
	
	var affordable = manager.can_afford(bid)
	
	if count >= max_count:
		buy_btn.text = "Maxed"
		buy_btn.disabled = true
	else:
		buy_btn.text = "Build"
		buy_btn.disabled = not affordable

func _on_buy_button_pressed():
	if manager.build(bid):
		parent_ui.update_ui()
		# UI update via signal or poll loop handled by GameState/Page
