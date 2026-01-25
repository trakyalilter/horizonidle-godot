extends Control

@onready var net_lbl = $VBoxContainer/EnergyDash/HBoxContainer/NetLabel
@onready var gen_lbl = $VBoxContainer/EnergyDash/HBoxContainer/VBoxContainer/GenLabel
@onready var cons_lbl = $VBoxContainer/EnergyDash/HBoxContainer/VBoxContainer/ConsLabel
@onready var energy_grid = $VBoxContainer/ScrollContainer/BladeContainer/EnergyRack/Grid
@onready var mining_grid = $VBoxContainer/ScrollContainer/BladeContainer/MiningRack/Grid
@onready var production_grid = $VBoxContainer/ScrollContainer/BladeContainer/ProductionRack/Grid

@onready var blade_container = $VBoxContainer/ScrollContainer/BladeContainer

var manager: RefCounted
var building_widget_scene = preload("res://scenes/ui/building_widget.tscn")
var widgets = []

var category_tabs: TabBar
var logistics_grid: HFlowContainer
var logistics_rack: VBoxContainer

func _ready():
	manager = GameState.infrastructure_manager
	_setup_logistics_rack()
	_setup_tabs()
	call_deferred("refresh_list")

func _setup_logistics_rack():
	# Create a new rack for Command/Logistics since it's missing in .tscn
	logistics_rack = VBoxContainer.new()
	logistics_rack.name = "LogisticsRack"
	logistics_rack.add_theme_constant_override("separation", 10)
	
	var header = Label.new()
	header.text = "[ COMMAND & LOGISTICS ]"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0, 0.5))
	logistics_rack.add_child(header)
	
	logistics_grid = HFlowContainer.new()
	logistics_grid.add_theme_constant_override("h_separation", 15)
	logistics_grid.add_theme_constant_override("v_separation", 15)
	logistics_rack.add_child(logistics_grid)
	
	blade_container.add_child(logistics_rack)

func _setup_tabs():
	category_tabs = TabBar.new()
	category_tabs.add_tab("Power")
	category_tabs.add_tab("Extraction")
	category_tabs.add_tab("Industry")
	category_tabs.add_tab("Command")
	category_tabs.tab_changed.connect(_on_tab_changed)
	
	var container = $VBoxContainer
	container.add_child(category_tabs)
	container.move_child(category_tabs, 2) # After Title and EnergyDash

func _on_tab_changed(index):
	# Toggle rack visibility
	energy_grid.get_parent().visible = (index == 0)
	mining_grid.get_parent().visible = (index == 1)
	production_grid.get_parent().visible = (index == 2)
	logistics_rack.visible = (index == 3)
	
	# Scroll back to top
	$VBoxContainer/ScrollContainer.scroll_vertical = 0

func refresh_list():
	for grid in [energy_grid, mining_grid, production_grid, logistics_grid]:
		for child in grid.get_children():
			child.queue_free()
	widgets.clear()
	
	for bid in manager.building_db:
		var data = manager.building_db[bid]
		var w = building_widget_scene.instantiate()
		
		var cat = data.get("category", "industry")
		var target_grid = production_grid
		
		match cat:
			"power": target_grid = energy_grid
			"extraction": target_grid = mining_grid
			"industry": target_grid = production_grid
			"logistics": target_grid = logistics_grid
		
		target_grid.add_child(w)
		w.setup(bid, data, manager, self)
		widgets.append(w)
	
	# Set initial visibility
	_on_tab_changed(0)

func _process(delta):
	# Update UI elements
	update_ui()
	# Manager ticks handled by GameState process

func update_ui():
	if not manager: return
	
	manager.recalc_energy() # Ensure fresh stats? Process loop handles actual logic
	
	var net = manager.net_energy
	var gen = manager.generation
	var cons = manager.consumption
	
	net_lbl.text = "NET: %+.1f kW" % net
	gen_lbl.text = "GEN: %.1f kW" % gen
	cons_lbl.text = "CONS: %.1f kW" % cons
	
	if net >= 0:
		net_lbl.add_theme_color_override("font_color", Color.CYAN)
	else:
		net_lbl.add_theme_color_override("font_color", Color.ORANGE_RED)
	
	# Widgets update themselves in _process usually, or we can force it
	for w in widgets:
		w.update_state()
