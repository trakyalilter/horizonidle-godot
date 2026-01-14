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

var pages = {}
var current_page_name = ""

func _ready():
	_init_pages()
	switch_to("gathering")

func _init_pages():
	# Gathering Page
	var p_gathering = preload("res://scenes/ui/gathering_page.tscn").instantiate()
	page_container.add_child(p_gathering)
	p_gathering.visible = false
	pages["gathering"] = p_gathering
	
	# Future pages...
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

	# Init Offline Modal
	if modal_layer:
		offline_modal = preload("res://scenes/ui/offline_modal.tscn").instantiate()
		modal_layer.add_child(offline_modal)
		offline_modal.visible = false
		offline_modal.check_and_show()

func switch_to(page_name):
	if current_page_name == page_name: return
	
	if current_page_name in pages:
		pages[current_page_name].visible = false
	
	if page_name in pages:
		pages[page_name].visible = true
		current_page_name = page_name

func _on_gathering_btn_pressed():
	switch_to("gathering")

func _on_processing_btn_pressed():
	switch_to("processing")

func _on_infrastructure_btn_pressed():
	switch_to("infrastructure")

func _on_shipyard_btn_pressed():
	switch_to("shipyard")

func _on_research_btn_pressed():
	switch_to("research")

func _on_combat_btn_pressed():
	switch_to("combat")

func _on_mission_btn_pressed():
	switch_to("mission")

func _on_designer_btn_pressed():
	switch_to("designer")

func _on_inventory_btn_pressed():
	switch_to("inventory")

func _on_options_btn_pressed():
	switch_to("options")
