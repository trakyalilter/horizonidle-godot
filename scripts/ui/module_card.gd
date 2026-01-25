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
	_update_ui()
	
func _update_ui():
	if not data or not is_inside_tree(): return
	if not name_lbl or not stats_lbl or not count_lbl: return
	
	name_lbl.text = data.get("name", "Unknown")
	name_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS.get("shipyard", Color.WHITE))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.text = "x%d" % count
	
	UITheme.apply_card_style(self, "shipyard")
	
	var s_txt = ""
	var stats = data.get("stats", {})
	for k in stats:
		var label = FormatUtils.format_stat_label(k)
		var val = stats[k]
		s_txt += "%s: %s\n" % [label, FormatUtils.format_stat_value(k, val)]
			
	stats_lbl.text = s_txt.strip_edges()
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _ready():
	_update_ui()

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
	preview.custom_minimum_size = Vector2(100, 100)
	
	set_drag_preview(preview)
	return drag_data
