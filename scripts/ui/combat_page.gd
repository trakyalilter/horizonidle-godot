extends Control

@onready var zone_list = $Dashboard/TopRow/SectorPanel/VBox/ZoneList
@onready var enemy_container = $Dashboard/TopRow/TargetingPanel/VBox/Scroll/EnemyList
@onready var log_list = $Dashboard/BottomPanel/VBox/LogList

# Arena Refs
# Visualizer Path: Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer
@onready var p_hp_bar = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/PlayerStats/HPBar
@onready var p_shield_bar = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/PlayerStats/ShieldBar
@onready var p_name_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/PlayerStats/NameLabel
@onready var p_stat_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/PlayerStats/StatsLabel

@onready var e_hp_bar = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/EnemyStats/HPBar
@onready var e_shield_bar = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/EnemyStats/ShieldBar
@onready var e_name_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/EnemyStats/NameLabel
@onready var e_stat_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/EnemyStats/StatsLabel

# Controls
@onready var btn_retreat = $Dashboard/TopRow/LiveFeedPanel/VBox/ControlRow/RetreatBtn
@onready var cons_opt = $Dashboard/TopRow/LiveFeedPanel/VBox/OptionButton
@onready var cons_btn = $Dashboard/TopRow/LiveFeedPanel/VBox/ControlRow/UseBtn
@onready var cons_check = $Dashboard/TopRow/LiveFeedPanel/VBox/AutoCheck

var manager: RefCounted

# Enemy List Item Prefab
# Enemy List Item Prefab
var enemy_card_scene = preload("res://scenes/ui/combat_enemy_card.tscn")
var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")
var enemy_info_scene = preload("res://scenes/ui/enemy_info_modal.tscn")

func _ready():
	manager = GameState.combat_manager
	call_deferred("refresh_zones")
	
	# Premium Styling
	UITheme.apply_card_style($Dashboard/TopRow/SectorPanel, "shipyard") # Map is high-tech
	UITheme.apply_card_style($Dashboard/TopRow/TargetingPanel, "combat")
	UITheme.apply_card_style($Dashboard/TopRow/LiveFeedPanel, "combat")
	UITheme.apply_card_style($Dashboard/BottomPanel, "engineering") # System log is tech-heavy
	
	UITheme.apply_premium_button_style(btn_retreat, "combat")
	UITheme.apply_premium_button_style(cons_btn, "engineering")
	
	UITheme.apply_progress_bar_style(p_hp_bar, "combat")
	UITheme.apply_progress_bar_style(p_shield_bar, "engineering")
	UITheme.apply_progress_bar_style(e_hp_bar, "combat")
	UITheme.apply_progress_bar_style(e_shield_bar, "engineering")
	
	$Dashboard/BottomPanel/VBox/Label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4)) # Terminal Green
	
	cons_opt.clear()
	cons_opt.add_item("Select Item...", 0)
	cons_opt.add_item("Nanoweave (Shield)", 1)
	cons_opt.set_item_metadata(1, "Mesh")
	cons_opt.add_item("Sealant (Hull)", 2)
	cons_opt.set_item_metadata(2, "Seal")

func refresh_zones():
	zone_list.clear()
	var zones = manager.get_available_zones()
	for z in zones:
		var idx = zone_list.add_item(z["data"]["name"])
		zone_list.set_item_metadata(idx, z["id"])

func _on_zone_list_item_selected(index):
	var zid = zone_list.get_item_metadata(index)
	refresh_enemies(zid)

func refresh_enemies(zone_id):
	if not enemy_container: return
	for child in enemy_container.get_children():
		child.queue_free()
		
	if not zone_id in manager.zones: return
	
	var enemies = manager.zones[zone_id]["enemies"]
	for eid in enemies:
		var card = enemy_card_scene.instantiate()
		enemy_container.add_child(card)
		var edata = manager.enemy_db[eid]
		card.setup(eid, edata, self)

func get_enemy_card(enemy_id: String) -> Control:
	for child in enemy_container.get_children():
		if child.get("eid") == enemy_id:
			return child
	return null

func focus_zone(zone_id: String):
	for i in range(zone_list.item_count):
		if zone_list.get_item_metadata(i) == zone_id:
			zone_list.select(i)
			_on_zone_list_item_selected(i)
			return

func start_fight(enemy_id, zone_id):
	# Zone ID is needed for start_expedition? 
	# Manager's start_expedition takes zone_id
	# Manager's set_target_enemy takes enemy_id
	# We need both.
	# But refresh_enemies only has zone_id context if we store it
	manager.set_target_enemy(enemy_id)
	
	# If we are viewing a zone, that is the zone we want to fight in.
	# But wait, start_expedition sets current_zone.
	# If we just click "Fight" on an enemy card, we imply starting expedition in that zone?
	# Implementation detail: card needs to know zone? Or we pass it.
	pass

func request_fight(eid):
	# Find which zone this is? 
	# We can just use the currently selected zone from the list
	var items = zone_list.get_selected_items()
	if items.size() == 0: return
	var zid = zone_list.get_item_metadata(items[0])
	
	manager.start_expedition(zid)
	manager.set_target_enemy(eid)

func _process(delta):
	update_ui()

func update_ui():
	# Player Stats
	p_hp_bar.max_value = manager.player_max_hp
	p_hp_bar.value = manager.player_hp
	p_shield_bar.max_value = max(1, manager.player_max_shield)
	p_shield_bar.value = manager.player_shield
	
	var sm = GameState.shipyard_manager
	p_stat_lbl.text = "ATK: %d | DEF: %d | EVA: %.1f%%" % [sm.attack, sm.defense, sm.evasion]
	
	# Enemy Stats
	if manager.in_combat and manager.current_enemy:
		e_name_lbl.text = manager.current_enemy["name"]
		e_hp_bar.max_value = manager.enemy_max_hp
		e_hp_bar.value = manager.enemy_hp
		e_shield_bar.max_value = max(1, manager.enemy_max_shield)
		e_shield_bar.value = manager.enemy_shield
		e_stat_lbl.text = "ATK: %d | DEF: %d" % [manager.current_enemy.get("atk",0), manager.current_enemy.get("def",0)]
	else:
		e_name_lbl.text = "No Target"
		e_hp_bar.value = 0
		e_shield_bar.value = 0
		e_stat_lbl.text = "ATK: - | DEF: -"

	# Log
	# Inefficient to clear every frame, check size or dirty flag?
	# Using delta check or just simple dirty check
	if log_list.item_count != manager.combat_log.size():
		log_list.clear() # Primitive sync
		for msg in manager.combat_log:
			log_list.add_item(msg)
		log_list.ensure_current_is_visible() # scroll to bottom roughly
		if log_list.item_count > 0:
			log_list.select(log_list.item_count - 1)

	# Retreat Btn
	btn_retreat.disabled = not manager.in_combat

	# Consumables
	if manager.consumable_cooldown > 0:
		cons_btn.disabled = true
		cons_btn.text = "%.1fs" % manager.consumable_cooldown
	else:
		cons_btn.disabled = false
		cons_btn.text = "USE"

	# Process Combat Events (Floating Text)
	while manager.combat_events.size() > 0:
		var ev = manager.combat_events.pop_front()
		spawn_floating_text(ev)

func show_enemy_info(data):
	var dlg = enemy_info_scene.instantiate()
	self.add_child(dlg)
	dlg.setup(data)

func spawn_floating_text(ev):
	var txt = floating_text_scene.instantiate()
	self.add_child(txt)
	
	var pos = Vector2.ZERO
	if ev["side"] == "player":
		# Spawn on Player side (Left)
		pos = p_hp_bar.global_position + Vector2(p_hp_bar.size.x / 2, 0)
	else:
		# Spawn on Enemy side (Right or center of enemy panel)
		if manager.current_enemy:
			pos = e_hp_bar.global_position + Vector2(e_hp_bar.size.x / 2, 0)
		else:
			pos = e_hp_bar.global_position # Fallback
			
	# Randomize slightly
	pos += Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	txt.setup(ev["text"], ev["color"], pos)

func _on_retreat_btn_pressed():
	manager.retreat()

func _on_use_btn_pressed():
	manager.use_consumable()

func _on_option_button_item_selected(index):
	var id = cons_opt.get_item_metadata(index)
	manager.equip_consumable(id)

func _on_auto_check_toggled(button_pressed):
	manager.toggle_auto_consume(button_pressed)
