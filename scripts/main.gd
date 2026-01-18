extends Control

@onready var page_container = $HBoxContainer/Content/PageContainer
# Sidebar Buttons
@onready var gathering_btn = $HBoxContainer/Sidebar/VBoxContainer/GatheringBtn
@onready var processing_btn = $HBoxContainer/Sidebar/VBoxContainer/ProcessingBtn
@onready var infrastructure_btn = $HBoxContainer/Sidebar/VBoxContainer/InfrastructureBtn
@onready var shipyard_btn = $HBoxContainer/Sidebar/VBoxContainer/ShipyardBtn
@onready var research_btn = $HBoxContainer/Sidebar/VBoxContainer/ResearchBtn
@onready var combat_btn = $HBoxContainer/Sidebar/VBoxContainer/CombatBtn
@onready var mission_btn = $HBoxContainer/Sidebar/VBoxContainer/MissionBtn
@onready var designer_btn = $HBoxContainer/Sidebar/VBoxContainer/DesignerBtn
@onready var inventory_btn = $HBoxContainer/Sidebar/VBoxContainer/InventoryBtn
@onready var options_btn = $HBoxContainer/Sidebar/VBoxContainer/OptionsBtn
@onready var sidebar_list = $HBoxContainer/Sidebar/VBoxContainer
@onready var modal_layer = $ModalLayer
var offline_modal

@onready var background = $Background

var pages = {}
var current_page_name = ""
var header_widget: Control

func _ready():
	_init_pages()
	_apply_global_styles()
	
	GameState.game_resetted.connect(_on_game_resetted)
	
	if not GameState.mission_manager.has_progress():
		switch_to("mission")
	else:
		switch_to("gathering")

func _apply_global_styles():
	background.color = UITheme.COLORS["background"]
	_update_sidebar_styling()

func _init_pages():
	# ... (same as before)
	var p_gathering = preload("res://scenes/ui/gathering_page.tscn").instantiate()
	page_container.add_child(p_gathering)
	p_gathering.visible = false
	pages["gathering"] = p_gathering
	
	var p_processing = preload("res://scenes/ui/processing_page.tscn").instantiate()
	page_container.add_child(p_processing)
	p_processing.visible = false
	pages["processing"] = p_processing
	
	var p_infrastructure = preload("res://scenes/ui/infrastructure_page.tscn").instantiate()
	page_container.add_child(p_infrastructure)
	p_infrastructure.visible = false
	pages["infrastructure"] = p_infrastructure
	
	var p_shipyard = preload("res://scenes/ui/shipyard_page.tscn").instantiate()
	page_container.add_child(p_shipyard)
	p_shipyard.visible = false
	pages["shipyard"] = p_shipyard
	
	var p_research = preload("res://scenes/ui/research_page.tscn").instantiate()
	page_container.add_child(p_research)
	p_research.visible = false
	pages["research"] = p_research
	
	var p_combat = preload("res://scenes/ui/combat_page.tscn").instantiate()
	page_container.add_child(p_combat)
	p_combat.visible = false
	pages["combat"] = p_combat
	
	var p_mission = preload("res://scenes/ui/mission_page.tscn").instantiate()
	page_container.add_child(p_mission)
	p_mission.visible = false
	pages["mission"] = p_mission
	
	var p_designer = preload("res://scenes/ui/designer_page.tscn").instantiate()
	page_container.add_child(p_designer)
	p_designer.visible = false
	pages["designer"] = p_designer
	
	var p_inventory = preload("res://scenes/ui/inventory_page.tscn").instantiate()
	page_container.add_child(p_inventory)
	p_inventory.visible = false
	pages["inventory"] = p_inventory
	
	var p_options = preload("res://scenes/ui/options_page.tscn").instantiate()
	page_container.add_child(p_options)
	p_options.visible = false
	pages["options"] = p_options

	if modal_layer:
		offline_modal = preload("res://scenes/ui/offline_modal.tscn").instantiate()
		modal_layer.add_child(offline_modal)
		offline_modal.visible = false
		offline_modal.check_and_show()
		
	# 3. Create & Inject Global HUD
	header_widget = preload("res://scenes/ui/global_header.tscn").instantiate()
	$HBoxContainer/Content.add_child(header_widget)
	$HBoxContainer/Content.move_child(header_widget, 0) # Top of VBox

func switch_to(page_name):
	if current_page_name == page_name: return
	
	for p_name in pages:
		pages[p_name].visible = (p_name == page_name)
		
	if page_name in pages:
		current_page_name = page_name
		_update_sidebar_styling()

func _update_sidebar_styling():
	UITheme.apply_sidebar_button_style(gathering_btn, current_page_name == "gathering")
	UITheme.apply_sidebar_button_style(processing_btn, current_page_name == "processing")
	UITheme.apply_sidebar_button_style(infrastructure_btn, current_page_name == "infrastructure")
	UITheme.apply_sidebar_button_style(shipyard_btn, current_page_name == "shipyard")
	UITheme.apply_sidebar_button_style(research_btn, current_page_name == "research")
	UITheme.apply_sidebar_button_style(combat_btn, current_page_name == "combat")
	UITheme.apply_sidebar_button_style(mission_btn, current_page_name == "mission")
	UITheme.apply_sidebar_button_style(designer_btn, current_page_name == "designer")
	UITheme.apply_sidebar_button_style(inventory_btn, current_page_name == "inventory")
	UITheme.apply_sidebar_button_style(options_btn, current_page_name == "options")
	
	UITheme.apply_sidebar_button_style(options_btn, current_page_name == "options")

func _process(delta):
	# 1. Tutorial Navigation Guidance
	_update_navigation_hints()
	
	# 2. Sidebar/Background Automation
	# ... (existing or inherited)

func _update_navigation_hints():
	var mm = GameState.mission_manager
	if not mm: return
	
	var target_to_pulse: Control = null
	
	# 1. Claim Reminder (Top Priority)
	var can_claim_tutorial = false
	for mid in ["m001", "m002", "m003", "m004", "m005", "m006", "m007", "m008", "m009", "m010", "m011", "m012"]:
		if mid in mm.missions and mm.missions[mid]["completed"] and not mm.missions[mid]["claimed"]:
			can_claim_tutorial = true
			break
	
	if can_claim_tutorial:
		if current_page_name != "mission":
			target_to_pulse = mission_btn
	
	# 2. Contextual Guidance based on Active Mission
	elif "m001" in mm.active_missions:
		# Gather Dirt
		if current_page_name != "gathering": target_to_pulse = gathering_btn
		else:
			var widget = pages["gathering"].get_widget_by_aid("gather_dirt")
			if widget and not (GameState.gathering_manager.is_active and GameState.gathering_manager.current_action_id == "gather_dirt"):
				target_to_pulse = widget.btn
				
	elif "m002" in mm.active_missions:
		# Research Basic Engineering
		if current_page_name != "research": target_to_pulse = research_btn
		else:
			var widget = pages["research"].get_node_widget("basic_engineering")
			if widget: target_to_pulse = widget
			
	elif "m003" in mm.active_missions:
		# Research Fluid Dynamics
		if current_page_name != "research": target_to_pulse = research_btn
		else:
			var widget = pages["research"].get_node_widget("fluid_dynamics")
			if widget: target_to_pulse = widget
			
	elif "m004" in mm.active_missions:
		# Gather Water & Spodumene
		if current_page_name != "gathering": target_to_pulse = gathering_btn
		else:
			var gm = GameState.gathering_manager
			var target_id = "collect_water"
			# If already collecting water, guide to spodumene
			if gm.is_active and gm.current_action_id == "collect_water":
				target_id = "extract_salts"
			
			var widget = pages["gathering"].get_widget_by_aid(target_id)
			if widget and not (gm.is_active and gm.current_action_id == target_id):
				target_to_pulse = widget.btn
				
	elif "m005" in mm.active_missions:
		# Processing: Si, Fe, Li
		if current_page_name != "processing": target_to_pulse = processing_btn
		else:
			var pm = GameState.processing_manager
			var target_id = "centrifuge_dirt" # For Si/Fe
			# If already mineral washing, guide to Lithium
			if pm.is_active and pm.current_recipe_id == "centrifuge_dirt":
				target_id = "refine_lithium"
				
			var page = pages["processing"]
			page.focus_tab(target_id)
			var widget = page.get_widget_by_aid(target_id)
			if widget and not (pm.is_active and pm.current_recipe_id == target_id):
				target_to_pulse = widget.btn
				
	elif "m006" in mm.active_missions:
		# Shipyard: Ion Thrusters
		if current_page_name != "shipyard": target_to_pulse = shipyard_btn
		else:
			var page = pages["shipyard"]
			page.focus_module_tab("basic_thruster")
			target_to_pulse = page.get_module_widget("basic_thruster")
		
	elif "m007" in mm.active_missions:
		# Research: Energy Shields
		if current_page_name != "research": target_to_pulse = research_btn
		else:
			var widget = pages["research"].get_node_widget("energy_shields")
			if widget: target_to_pulse = widget
			
	elif "m008" in mm.active_missions:
		# Shipyard: Deflector Shield
		if current_page_name != "shipyard": target_to_pulse = shipyard_btn
		else:
			var page = pages["shipyard"]
			page.focus_module_tab("basic_shield")
			target_to_pulse = page.get_module_widget("basic_shield")
		
	elif "m009" in mm.active_missions:
		# Shipyard: Battery
		if current_page_name != "shipyard": target_to_pulse = shipyard_btn
		else:
			var page = pages["shipyard"]
			page.focus_module_tab("battery_t1")
			target_to_pulse = page.get_module_widget("battery_t1")
		
	elif "m010" in mm.active_missions:
		# Shipyard: Mass Driver
		if current_page_name != "shipyard": target_to_pulse = shipyard_btn
		else:
			var page = pages["shipyard"]
			page.focus_module_tab("railgun_mk1")
			target_to_pulse = page.get_module_widget("railgun_mk1")
		
	elif "m011" in mm.active_missions:
		# Processing: Ferrite Rounds
		if current_page_name != "processing": target_to_pulse = processing_btn
		else:
			var pm = GameState.processing_manager
			var page = pages["processing"]
			page.focus_tab("craft_slug_t1")
			var widget = page.get_widget_by_aid("craft_slug_t1")
			if widget and not (pm.is_active and pm.current_recipe_id == "craft_slug_t1"):
				target_to_pulse = widget.btn
				
	elif "m012" in mm.active_missions:
		# Combat: Lunar Drone
		if current_page_name != "combat": target_to_pulse = combat_btn
		else:
			var page = pages["combat"]
			page.focus_zone("lunar_orbit")
			target_to_pulse = page.get_enemy_card("lunar_drone")

	# Apply final decision
	if target_to_pulse:
		start_hint_pulse(target_to_pulse)
	else:
		stop_hint_pulse()


var hint_tween: Tween
var pulsing_button: Control = null

func start_hint_pulse(control: Control):
	if pulsing_button == control: return
	
	stop_hint_pulse()
	pulsing_button = control
	
	# Set pivot to center for scale pulse
	control.pivot_offset = control.size / 2
	
	hint_tween = create_tween().set_loops()
	# Vivid Golden Glow + Scale Pulse
	var pulse_color = Color(1.2, 0.9, 0.2) # Over-bright for HDR/Glow feel
	hint_tween.parallel().tween_property(control, "modulate", pulse_color, 0.4).set_trans(Tween.TRANS_SINE)
	hint_tween.parallel().tween_property(control, "scale", Vector2(1.05, 1.05), 0.4).set_trans(Tween.TRANS_SINE)
	
	hint_tween.parallel().tween_property(control, "modulate", Color.WHITE, 0.4).set_trans(Tween.TRANS_SINE).set_delay(0.4)
	hint_tween.parallel().tween_property(control, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE).set_delay(0.4)

func stop_hint_pulse():
	if hint_tween:
		hint_tween.kill()
		hint_tween = null
	
	if pulsing_button:
		pulsing_button.modulate = Color.WHITE
		pulsing_button.scale = Vector2(1.0, 1.0)
		pulsing_button = null

func _on_gathering_btn_pressed(): switch_to("gathering")
func _on_processing_btn_pressed(): switch_to("processing")
func _on_infrastructure_btn_pressed(): switch_to("infrastructure")
func _on_shipyard_btn_pressed(): switch_to("shipyard")
func _on_research_btn_pressed(): switch_to("research")
func _on_combat_btn_pressed(): switch_to("combat")
func _on_mission_btn_pressed(): switch_to("mission")
func _on_designer_btn_pressed(): switch_to("designer")
func _on_inventory_btn_pressed(): switch_to("inventory")
func _on_options_btn_pressed(): switch_to("options")

func _on_game_resetted():
	switch_to("mission")
