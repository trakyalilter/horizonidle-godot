extends PanelContainer

var eid
var data
var parent_ui

@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var stats_lbl = $MarginContainer/VBoxContainer/StatsLabel
@onready var loot_lbl = $MarginContainer/VBoxContainer/LootLabel

func setup(p_eid, p_data, p_parent):
	eid = p_eid
	data = p_data
	parent_ui = p_parent
	
	name_lbl.text = data["name"]
	stats_lbl.text = "HP: %d | ATK: %d | DEF: %d" % [data["stats"]["hp"], data["stats"]["atk"], data["stats"]["def"]]
	
	var loot_txt = "Drops: "
	for entry in data["loot"]:
		loot_txt += entry[0] + ", "
	loot_lbl.text = loot_txt.trim_suffix(", ")

func _on_fight_btn_pressed():
	parent_ui.request_fight(eid)

func _on_info_btn_pressed():
	parent_ui.show_enemy_info(data)
