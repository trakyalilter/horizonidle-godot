extends Control

@onready var anim = $AnimationPlayer
@onready var panel = $Panel
@onready var title_lbl = $Panel/VBoxContainer/TitleLabel
@onready var stats_lbl = $Panel/VBoxContainer/StatsLabel
@onready var loot_container = $Panel/VBoxContainer/ScrollContainer/LootContainer
@onready var btn_close = $Panel/VBoxContainer/CloseBtn

var enemy_data = {}

func _ready():
	visible = false
	btn_close.pressed.connect(close)

func setup(data):
	enemy_data = data
	
	# Title
	title_lbl.text = "Intel: " + data["name"]
	
	# Stats
	var hp = data["stats"]["hp"]
	var atk = data["stats"]["atk"]
	var df = data["stats"]["def"]
	var shield = data["stats"].get("max_shield", 0)
	
	stats_lbl.text = "HP: %d | Shield: %d\nATK: %d | DEF: %d" % [hp, shield, atk, df]
	
	# Clear Loot
	for c in loot_container.get_children():
		c.queue_free()
		
	# Guaranteed Loot Header
	add_header("Guaranteed Drops", Color.ORANGE)
	
	for item in data["loot"]:
		# format: [name, min, max]
		var txt = "• %s: %d-%d" % [item[0], item[1], item[2]]
		add_item_label(txt, Color.WHITE)
		
	# Rare Loot
	if "rare_loot" in data and not data["rare_loot"].is_empty():
		add_header("Rare Drops", Color.MAGENTA)
		for item in data["rare_loot"]:
			# format: [name, chance, min, max]
			var chance = item[1] * 100.0
			var txt = "• %s: %.1f%% (%d-%d)" % [item[0], chance, item[2], item[3]]
			add_item_label(txt, Color.LIGHT_BLUE)
			
	visible = true
	# Animation pop in?
	# anim.play("pop_in") 

func add_header(text, color):
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 14)
	loot_container.add_child(l)
	
func add_item_label(text, color):
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 12)
	loot_container.add_child(l)

func close():
	visible = false
	queue_free()
