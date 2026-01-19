extends Control

@onready var zone_list = $Dashboard/TopRow/SectorPanel/VBox/ZoneList
@onready var enemy_container = $Dashboard/TopRow/TargetingPanel/VBox/Scroll/EnemyList
@onready var log_list = $Dashboard/BottomPanel/VBox/LogList

# Arena Refs
# Visualizer Path: Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer
@onready var visualizer = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer
@onready var radar_lines = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/Background/RadarLines
@onready var threat_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/CenterInfo/SectorThreat
@onready var scan_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/CenterInfo/ScanningStatus

@onready var p_hp_bar = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/PlayerStats/HPBar
@onready var p_shield_bar = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/PlayerStats/ShieldBar
@onready var p_name_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/PlayerStats/NameLabel
@onready var p_stat_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/PlayerStats/StatsLabel
@onready var weapon_battery = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/PlayerStats/WeaponBattery
@onready var p_buff_container = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/PlayerStats/BuffContainer

var player_weapon_bars = []

@onready var e_hp_bar = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/EnemyStats/HPBar
@onready var e_shield_bar = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/EnemyStats/ShieldBar
@onready var e_name_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/EnemyStats/NameLabel
@onready var e_stat_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/EnemyStats/StatsLabel
@onready var e_attack_pb = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/EnemyStats/E_AttackBar

@onready var scanner_overlay = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/ScannerOverlay
@onready var loot_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/ScannerOverlay/VBox/LootText

@onready var ammo_overlay = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/AmmoOverlay
@onready var ammo_lbl = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/AmmoOverlay/VBox/AmmoText

# Controls
@onready var btn_retreat = $Dashboard/TopRow/LiveFeedPanel/VBox/ViewportFooter/Margin/HBox/RetreatBtn
@onready var cons_opt = $Dashboard/TopRow/LiveFeedPanel/VBox/ViewportFooter/Margin/HBox/ConsumableBay/OptionButton
@onready var cons_btn = $Dashboard/TopRow/LiveFeedPanel/VBox/ViewportFooter/Margin/HBox/ConsumableBay/UseBtn
@onready var auto_btn = $Dashboard/TopRow/LiveFeedPanel/VBox/ViewportFooter/Margin/HBox/ConsumableBay/AutoToggle

var manager: RefCounted

# Enemy List Item Prefab
# Enemy List Item Prefab
var enemy_card_scene = preload("res://scenes/ui/combat_enemy_card.tscn")
var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")
var enemy_info_scene = preload("res://scenes/ui/enemy_info_modal.tscn")

func _ready():
	manager = GameState.combat_manager
	call_deferred("refresh_zones")
	GameState.game_loaded.connect(refresh_zones)
	
	# Premium Styling
	UITheme.apply_card_style($Dashboard/TopRow/SectorPanel, "shipyard") # Map is high-tech
	UITheme.apply_card_style($Dashboard/TopRow/TargetingPanel, "combat")
	UITheme.apply_card_style($Dashboard/TopRow/LiveFeedPanel, "combat")
	UITheme.apply_card_style($Dashboard/BottomPanel, "engineering") # System log is tech-heavy
	
	UITheme.apply_panel_style($Dashboard/TopRow/LiveFeedPanel/VBox/ViewportHeader)
	UITheme.apply_panel_style($Dashboard/TopRow/LiveFeedPanel/VBox/ViewportFooter)
	UITheme.apply_modal_style(scanner_overlay) # Use modal style for the scanner
	
	UITheme.apply_premium_button_style(btn_retreat, "combat")
	UITheme.apply_premium_button_style(cons_btn, "engineering")
	
	UITheme.apply_progress_bar_style(p_hp_bar, "combat")
	UITheme.apply_progress_bar_style(p_shield_bar, "engineering")
	UITheme.apply_progress_bar_style(e_hp_bar, "combat")
	UITheme.apply_progress_bar_style(e_shield_bar, "engineering")
	UITheme.apply_progress_bar_style(e_attack_pb, "combat")
	
	$Dashboard/BottomPanel/VBox/Label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4)) # Terminal Green
	
	cons_opt.clear()
	cons_opt.add_item("Select Item...", 0)
	cons_opt.add_item("Nanoweave (Shield)", 1)
	cons_opt.set_item_metadata(1, "Mesh")
	cons_opt.add_item("Sealant (Hull)", 2)
	cons_opt.set_item_metadata(2, "Seal")

	# Explicit Signal Connections (Defensive)
	if not btn_retreat.is_connected("pressed", _on_retreat_btn_pressed): btn_retreat.pressed.connect(_on_retreat_btn_pressed)
	if not cons_btn.is_connected("pressed", _on_use_btn_pressed): cons_btn.pressed.connect(_on_use_btn_pressed)
	if not cons_opt.is_connected("item_selected", _on_option_button_item_selected): cons_opt.item_selected.connect(_on_option_button_item_selected)
	if not auto_btn.is_connected("toggled", _on_auto_btn_toggled): auto_btn.toggled.connect(_on_auto_btn_toggled)

func refresh_zones():
	zone_list.clear()
	var zones = manager.get_available_zones()
	for z in zones:
		var idx = zone_list.add_item(z["data"]["name"])
		zone_list.set_item_metadata(idx, z["id"])

func _on_zone_list_item_selected(index):
	var zid = zone_list.get_item_metadata(index)
	refresh_enemies(zid)

var last_refreshed_zone = ""

func refresh_enemies(zone_id):
	if last_refreshed_zone == zone_id and enemy_container.get_child_count() > 0:
		return
	last_refreshed_zone = zone_id
	
	if not enemy_container: return
	for child in enemy_container.get_children():
		child.queue_free()
		
	if not zone_id in manager.zones: return
	
	var enemies = manager.zones[zone_id]["enemies"].duplicate()
	
	# Sort by HP (weakest to strongest)
	enemies.sort_custom(func(a, b):
		var hp_a = manager.enemy_db[a]["stats"].get("hp", 0)
		var hp_b = manager.enemy_db[b]["stats"].get("hp", 0)
		return hp_a < hp_b
	)
	
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
			if not zone_list.is_selected(i):
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
	_update_atmosphere(delta)

func update_ui():
	# Player Stats
	var sm = GameState.shipyard_manager
	# Player Stats
	p_hp_bar.max_value = sm.max_hp
	p_hp_bar.value = sm.current_hp
	p_shield_bar.max_value = max(1, manager.player_max_shield)
	p_shield_bar.value = manager.player_shield
	
	p_stat_lbl.text = "ATK: %s | DEF: %s | EVA: %.1f%%" % [UITheme.format_num(sm.attack), UITheme.format_num(sm.defense), sm.evasion]
	
	# Enemy Stats
	if manager.in_combat and manager.current_enemy:
		e_name_lbl.text = manager.current_enemy["name"]
		e_hp_bar.max_value = manager.enemy_max_hp
		e_hp_bar.value = manager.enemy_hp
		e_shield_bar.max_value = max(1, manager.enemy_max_shield)
		e_shield_bar.value = manager.enemy_shield
		e_stat_lbl.text = "ATK: %s | DEF: %s" % [UITheme.format_num(manager.current_enemy.get("atk",0)), UITheme.format_num(manager.current_enemy.get("def",0))]
		btn_retreat.disabled = false
	else:
		e_name_lbl.text = "No Target"
		e_hp_bar.max_value = 100
		e_hp_bar.value = 0
		e_shield_bar.value = 0
		e_stat_lbl.text = "ATK: - | DEF: -"
		btn_retreat.disabled = true
	
	# Attack Timers
	if manager.in_combat:
		# Sync Weapon Battery
		var w_states = manager.player_weapon_states
		if player_weapon_bars.size() != w_states.size():
			_rebuild_weapon_battery(w_states)
		
		for i in range(w_states.size()):
			var w = w_states[i]
			var pb = player_weapon_bars[i]
			pb.max_value = w["interval"]
			pb.value = w["timer"]
			pb.visible = true
		
		if manager.current_enemy:
			e_attack_pb.visible = true
			e_attack_pb.max_value = manager.current_enemy.get("atk_interval", 3.0)
			e_attack_pb.value = manager.enemy_attack_timer
		else:
			e_attack_pb.visible = false
		# Expedition Yield
		_update_session_loot()
		scanner_overlay.visible = true
		
		# Ammo Tracking
		_update_ammo_display()
		ammo_overlay.visible = true
	else:
		for pb in player_weapon_bars: pb.visible = false
		e_attack_pb.visible = false
		scanner_overlay.visible = false
		ammo_overlay.visible = false
		scan_lbl.text = "SCANNING FOR ANOMALIES..."

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

	# Auto Toggle Styling (The "Lamp" Effect)
	if manager.auto_consume_enabled:
		auto_btn.text = "AUTO [ON]"
		auto_btn.modulate = Color(0, 1, 1) # Cyan glow
	else:
		auto_btn.text = "AUTO [OFF]"
		auto_btn.modulate = Color(0.5, 0.5, 0.5) # Dim grey

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
	# Parent to Visualizer to keep it contained in the middle area
	var visualizer = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer
	visualizer.add_child(txt)
	
	var local_pos = Vector2.ZERO
	if ev["side"] == "player":
		# Position relative to visualizer: PlayerStats is top-left in HUD
		local_pos = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/PlayerStats.position 
		local_pos += p_hp_bar.position + Vector2(p_hp_bar.size.x / 2, 0)
	else:
		if manager.current_enemy:
			# Position relative to visualizer: EnemyStats is top-right in HUD
			local_pos = $Dashboard/TopRow/LiveFeedPanel/VBox/Visualizer/HUD/StatsHBox/EnemyStats.position
			local_pos += e_hp_bar.position + Vector2(e_hp_bar.size.x / 2, 0)
		else:
			local_pos = Vector2(visualizer.size.x / 2, visualizer.size.y / 2)
			
	# Randomize slightly
	local_pos += Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt.setup(ev["text"], ev["color"], local_pos)

func _update_session_loot():
	var tt = "[center]"
	
	if manager.session_loot.is_empty():
		tt += "[color=#666666][ NO YIELD ][/color]"
	else:
		for item_id in manager.session_loot:
			var qty = manager.session_loot[item_id]
			var item_name = ElementDB.get_display_name(item_id)
			tt += "[color=#32cd32]%s[/color] x %s\n" % [item_name, UITheme.format_num(qty)]
			
	tt += "[/center]"
	loot_lbl.text = tt

func _update_ammo_display():
	var sm = GameState.shipyard_manager
	var tt = "[center]"
	
	var ammos = []
	for slot in sm.ammo_loadout:
		var aid = sm.ammo_loadout[slot]
		if aid and aid != "" and not aid in ammos:
			ammos.append(aid)
	
	if ammos.is_empty():
		tt += "[color=#666666]NO AMMO LOADED[/color]"
	else:
		for active in ammos:
			var qty = GameState.resources.get_element_amount(active)
			var item_name = ElementDB.get_display_name(active)
			
			var color = "#00ccff" # Cyan normal
			if qty == 0: color = "#ff4444" # Red empty
			elif qty < 20: color = "#ffcc00" # Yellow low
			
			tt += "[color=%s]%s[/color]: %s\n" % [color, item_name, UITheme.format_num(qty)]
		
	tt += "[/center]"
	ammo_lbl.text = tt

func _rebuild_weapon_battery(w_states):
	for child in weapon_battery.get_children(): child.queue_free()
	player_weapon_bars.clear()
	
	for w in w_states:
		var pb = ProgressBar.new()
		pb.custom_minimum_size = Vector2(0, 4)
		pb.show_percentage = false
		
		# Set style based on type
		var fill_color = Color("#00ccff") if w["type"] == "energy" else Color("#ffcc00")
		var sb_fill = StyleBoxFlat.new()
		sb_fill.bg_color = fill_color
		sb_fill.set_corner_radius_all(2)
		pb.add_theme_stylebox_override("fill", sb_fill)
		
		var sb_bg = StyleBoxFlat.new()
		sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.6)
		sb_bg.set_corner_radius_all(2)
		pb.add_theme_stylebox_override("background", sb_bg)
		
		weapon_battery.add_child(pb)
		player_weapon_bars.append(pb)

func _update_atmosphere(delta):
	# Pulse scanning label
	var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
	scan_lbl.modulate.a = 0.2 + (pulse * 0.4)
	
	if manager.in_combat:
		scan_lbl.text = "TARGET LOCK CONFIRMED"
		threat_lbl.text = "SECTOR THREAT: ENGAGED"
		threat_lbl.modulate = Color(1, 0.3, 0.3, 0.8) # Red alert
	else:
		threat_lbl.text = "SCANNING SECTOR..."
		threat_lbl.text = "SECTOR THREAT: NOMINAL"
		threat_lbl.modulate = Color(1, 0.8, 0, 0.5) # Yellow cautious

func _on_retreat_btn_pressed():
	manager.retreat()

func _on_use_btn_pressed():
	manager.use_consumable()

func _on_option_button_item_selected(index):
	var id = cons_opt.get_item_metadata(index)
	manager.equip_consumable(id)

func _on_auto_btn_toggled(button_pressed):
	manager.toggle_auto_consume(button_pressed)
