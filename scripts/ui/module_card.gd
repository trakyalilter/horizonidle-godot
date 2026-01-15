extends PanelContainer

var mid: String
var data: Dictionary

@onready var name_lbl = $Margin/VBox/NameLabel
@onready var stats_lbl = $Margin/VBox/StatsLabel
@onready var count_lbl = $Margin/VBox/HBox/CountLabel

func setup(p_mid: String, p_data: Dictionary, p_count: int):
	mid = p_mid
	data = p_data
	
	name_lbl.text = data["name"]
	name_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS["shipyard"])
	count_lbl.text = "x%d" % p_count
	
	UITheme.apply_card_style(self, "shipyard")
	
	var s_txt = ""
	for k in data["stats"]:
		if k == "energy_load":
			s_txt += "Energy: %d | " % data["stats"][k]
		else:
			s_txt += "%s: %s | " % [k.substr(0,3).to_upper(), str(data["stats"][k])]
	stats_lbl.text = s_txt.trim_suffix(" | ")

func _get_drag_data(at_position):
	var drag_data = {
		"type": "ammo" if data.get("slot_type") == "ammo" else "module",
		"mid": mid,
		"ammo_id": mid, # For ease of use in drop
		"slot_type": data["slot_type"]
	}
	
	# Visual Preview
	var preview = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0.5, 0.8, 0.7) # Semi-transparent blue
	style.set_content_margin_all(5)
	preview.add_theme_stylebox_override("panel", style)
	
	var prev_label = Label.new()
	prev_label.text = data["name"]
	prev_label.add_theme_font_size_override("font_size", 12)
	preview.add_child(prev_label)
	
	set_drag_preview(preview)
	return drag_data
