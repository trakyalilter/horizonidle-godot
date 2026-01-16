extends PanelContainer

var mid: String
var data: Dictionary

@onready var name_lbl = $Margin/VBox/HBox/NameLabel
@onready var stats_lbl = $Margin/VBox/StatsLabel
@onready var count_lbl = $Margin/VBox/HBox/CountLabel

var count: int = 0

func setup(p_mid: String, p_data: Dictionary, p_count: int):
	mid = p_mid
	data = p_data
	count = p_count
	
	if is_inside_tree():
		_update_ui()

func _ready():
	_update_ui()

func _update_ui():
	if not data or not is_inside_tree(): return
	if not name_lbl or not stats_lbl or not count_lbl: return
	
	name_lbl.text = data.get("name", "Unknown")
	name_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS.get("shipyard", Color.WHITE))
	count_lbl.text = "x%d" % count
	
	UITheme.apply_card_style(self, "shipyard")
	
	var s_txt = ""
	var stats = data.get("stats", {})
	for k in stats:
		if k == "energy_load":
			s_txt += "Energy: %d | " % stats[k]
		else:
			s_txt += "%s: %s | " % [k.substr(0,3).to_upper(), str(stats[k])]
	stats_lbl.text = s_txt.trim_suffix(" | ")

func _get_drag_data(_at_position):
	if not data or not mid: return null
	
	var drag_data = {
		"type": "ammo" if data.get("slot_type") == "ammo" else "module",
		"mid": mid,
		"ammo_id": mid, # For ease of use in drop
		"slot_type": data.get("slot_type", "")
	}
	
	# Visual Preview: Use a real card instance
	var preview = load("res://scenes/ui/module_card.tscn").instantiate()
	preview.setup(mid, data, count)
	# Scale down slightly and make semi-transparent
	preview.modulate.a = 0.7
	preview.custom_minimum_size = Vector2(200, 60) # Smaller than full width
	
	set_drag_preview(preview)
	return drag_data
