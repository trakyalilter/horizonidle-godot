extends Control

@onready var ship_name_lbl = $VBoxContainer/MainLayout/LeftPanel/InfoPanel/Margin/VBox/ShipNameLabel
@onready var stats_lbl = $VBoxContainer/MainLayout/LeftPanel/InfoPanel/Margin/VBox/StatsLabel
@onready var w_box = $VBoxContainer/MainLayout/CenterPanel/ScrollContainer/SlotTabs/Weapons/WeaponBox
@onready var s_box = $VBoxContainer/MainLayout/CenterPanel/ScrollContainer/SlotTabs/Shields/ShieldBox
@onready var e_box = $VBoxContainer/MainLayout/CenterPanel/ScrollContainer/SlotTabs/Engines/EngineBox
@onready var b_box = $VBoxContainer/MainLayout/CenterPanel/ScrollContainer/SlotTabs/Batteries/BatteryGrid # Reused battery grid for systems/batteries
@onready var ammo_slot_box = $VBoxContainer/MainLayout/CenterPanel/ScrollContainer/SlotTabs/Ammunition/AmmoSlotBox

# Storage Grids
@onready var weapon_grid = $VBoxContainer/MainLayout/RightPanel/ModuleTabs/Weapons/WeaponGrid
@onready var shield_grid = $VBoxContainer/MainLayout/RightPanel/ModuleTabs/Shields/ShieldGrid
@onready var engine_grid = $VBoxContainer/MainLayout/RightPanel/ModuleTabs/Engines/EngineGrid
@onready var battery_grid = $VBoxContainer/MainLayout/RightPanel/ModuleTabs/Batteries/BatteryGrid
@onready var ammo_grid = $VBoxContainer/MainLayout/RightPanel/ModuleTabs/Ammunition/AmmoGrid

var manager: RefCounted
var slot_widget_scene = preload("res://scenes/ui/designer_slot_widget.tscn")
var ammo_slot_scene = preload("res://scenes/ui/designer_ammo_slot_widget.tscn")
var draggable_icon_scene = preload("res://scenes/ui/module_card.tscn") 

func _ready():
	manager = GameState.shipyard_manager
	visibility_changed.connect(_on_visibility_changed)
	
	# Premium Styling
	UITheme.apply_card_style($VBoxContainer/MainLayout/LeftPanel/InfoPanel, "shipyard")
	UITheme.apply_card_style($VBoxContainer/MainLayout/RightPanel/ModuleTabs, "shipyard")
	UITheme.apply_tab_style($VBoxContainer/MainLayout/CenterPanel/ScrollContainer/SlotTabs, "shipyard")
	UITheme.apply_tab_style($VBoxContainer/MainLayout/RightPanel/ModuleTabs, "shipyard")
	
	$VBoxContainer/Label.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS["shipyard"])
	$VBoxContainer/MainLayout/CenterPanel/Label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	
	trigger_refresh()

func _on_visibility_changed():
	if visible:
		trigger_refresh()

func trigger_refresh():
	update_header()
	rebuild_slots()
	rebuild_ammo_slots()
	rebuild_storage()
	rebuild_ammo_storage()

func update_header():
	if manager.active_hull and manager.active_hull in manager.hulls:
		var h = manager.hulls[manager.active_hull]
		ship_name_lbl.text = h["name"]
		var e_max = GameState.resources.max_energy
		var e_used = manager.energy_used
		stats_lbl.text = "HP: %d | SHIELD: %d\nENERGY: %d/%d\nATK: %d | DEF: %d" % [manager.max_hp, manager.max_shield, e_used, e_max, manager.attack, manager.defense]
		stats_lbl.modulate = Color(1, 0.3, 0.3) if e_used > e_max else Color(0.8, 0.8, 0.8)
	else:
		ship_name_lbl.text = "No Structure"
		stats_lbl.text = "Escape Pod Active"

func rebuild_slots():
	for box in [w_box, s_box, e_box, b_box]:
		if box:
			for child in box.get_children(): child.queue_free()
			
	if not manager.active_hull in manager.hulls: return
	
	var h_data = manager.hulls[manager.active_hull]
	var slots = h_data["slots"]
	for i in range(slots.size()):
		var s_type = slots[i]
		var w = slot_widget_scene.instantiate()
		var target = w_box
		match s_type:
			"weapon": target = w_box
			"shield": target = s_box
			"engine": target = e_box
			"battery": target = b_box
		
		if target:
			target.add_child(w)
			w.setup(i, s_type, self, manager)

func rebuild_ammo_slots():
	for child in ammo_slot_box.get_children(): child.queue_free()
	var slot = ammo_slot_scene.instantiate()
	ammo_slot_box.add_child(slot)
	slot.setup(self, manager)

func rebuild_storage():
	for grid in [weapon_grid, shield_grid, engine_grid, battery_grid]:
		for child in grid.get_children(): child.queue_free()
	
	var inv = manager.module_inventory
	for mid in inv:
		var count = inv[mid]
		if count > 0 and mid in manager.modules:
			var data = manager.modules[mid]
			var type = data.get("slot_type", "weapon")
			var target = weapon_grid
			match type:
				"weapon": target = weapon_grid
				"shield": target = shield_grid
				"engine": target = engine_grid
				"battery": target = battery_grid
			
			if target:
				var item = draggable_icon_scene.instantiate()
				target.add_child(item)
				item.setup(mid, data, count)

func rebuild_ammo_storage():
	for child in ammo_grid.get_children(): child.queue_free()
	
	var ammo_list = [
		{"name": "Ferrite Rounds", "id": "SlugT1"},
		{"name": "Tungsten Sabot", "id": "SlugT2"},
		{"name": "Focus Crystal", "id": "CellT1"},
		{"name": "Plasma Cell", "id": "CellT2"}
	]
	
	for ammo in ammo_list:
		var qty = GameState.resources.get_element_amount(ammo["id"])
		if qty > 0:
			var card = draggable_icon_scene.instantiate()
			ammo_grid.add_child(card)
			var fake_data = {
				"name": ammo["name"],
				"slot_type": "ammo",
				"stats": {}
			}
			card.setup(ammo["id"], fake_data, qty)
