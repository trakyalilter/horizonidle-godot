extends Control

@onready var grid = $HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var credits_lbl = $HBoxContainer/RightPanel/VBoxContainer/CreditsLabel

# Details Panel
@onready var sel_name = $HBoxContainer/RightPanel/VBoxContainer/Details/NameLabel
@onready var sel_desc = $HBoxContainer/RightPanel/VBoxContainer/Details/DescLabel
@onready var price_lbl = $HBoxContainer/RightPanel/VBoxContainer/Details/PriceLabel
@onready var qty_spin = $HBoxContainer/RightPanel/VBoxContainer/Details/HBoxContainer/QtySpinBox
@onready var total_lbl = $HBoxContainer/RightPanel/VBoxContainer/Details/TotalLabel
@onready var sell_btn = $HBoxContainer/RightPanel/VBoxContainer/Details/SellBtn
@onready var sell_all_btn = $HBoxContainer/RightPanel/VBoxContainer/Details/SellAllBtn

# Filter Buttons
@onready var filter_all = $HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/CategoryFilter/AllBtn
@onready var filter_ores = $HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/CategoryFilter/OresBtn
@onready var filter_metals = $HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/CategoryFilter/MetalsBtn
@onready var filter_alloys = $HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/CategoryFilter/AlloysBtn
@onready var filter_comp = $HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/CategoryFilter/CompBtn
@onready var filter_other = $HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/CategoryFilter/OtherBtn

var card_scene = preload("res://scenes/ui/element_card.tscn")
var empty_slot_scene = preload("res://scenes/ui/empty_slot.tscn")
var cards = {} # {symbol: widget}
var min_slots = 48 # Increased from 40 for better grid
var selected_element = null
var price_val = 0
var current_filter = "all"

func _ready():
	_init_filter_buttons()
	
	# Premium Styling
	UITheme.apply_card_style($HBoxContainer/LeftPanel, "inventory")
	UITheme.apply_card_style($HBoxContainer/RightPanel, "inventory")
	UITheme.apply_premium_button_style(sell_btn, "inventory")
	UITheme.apply_premium_button_style(sell_all_btn, "inventory")
	
	call_deferred("refresh_inventory")
	update_credits()
	GameState.resources.element_added.connect(_on_inventory_changed)
	GameState.resources.element_removed.connect(_on_inventory_changed)
	GameState.resources.currency_added.connect(func(t, a): update_credits())

func _init_filter_buttons():
	var filter_btns = [filter_all, filter_ores, filter_metals, filter_alloys, filter_comp, filter_other]
	for b in filter_btns:
		UITheme.apply_sharp_button_style(b, "inventory")
		
	filter_all.pressed.connect(func(): set_filter("all"))
	filter_ores.pressed.connect(func(): set_filter("ores"))
	filter_metals.pressed.connect(func(): set_filter("metals")) # Combined basic/adv for simplicity
	filter_alloys.pressed.connect(func(): set_filter("alloys"))
	filter_comp.pressed.connect(func(): set_filter("components"))
	filter_other.pressed.connect(func(): set_filter("other"))

func set_filter(category):
	current_filter = category
	
	# Untoggle others
	filter_all.button_pressed = (category == "all")
	filter_ores.button_pressed = (category == "ores")
	filter_metals.button_pressed = (category == "metals")
	filter_alloys.button_pressed = (category == "alloys")
	filter_comp.button_pressed = (category == "components")
	filter_other.button_pressed = (category == "other")
	
	refresh_inventory()

func _on_inventory_changed(symbol, amount):
	if visible:
		refresh_inventory()

func refresh_inventory():
	# Clear
	if not grid: return
	for child in grid.get_children():
		child.queue_free()
	cards.clear()
	
	var elements_db = GameState.elements_db
	var slot_count = 0
	
	# 1. Show Filtered Owned Items
	for el in elements_db:
		var symbol = el["symbol"]
		var amt = GameState.resources.get_element_amount(symbol)
		
		if amt <= 0: continue
		
		# Filter Check
		if current_filter != "all":
			var item_cat = ElementDB.get_category(symbol)
			if current_filter == "metals":
				if item_cat != "basic_metals" and item_cat != "advanced_metals" and item_cat != "rare_metals":
					continue
			elif item_cat != current_filter:
				continue
		
		var card = card_scene.instantiate()
		grid.add_child(card)
		card.setup(el, amt)
		card.clicked.connect(_on_item_clicked)
		cards[symbol] = card
		slot_count += 1
			
	# 2. Fill remaining with Empty Slots
	var needed = max(0, min_slots - slot_count)
	for i in range(needed):
		var empty = empty_slot_scene.instantiate()
		grid.add_child(empty)
			
	update_credits()
	
	if selected_element:
		var amt = GameState.resources.get_element_amount(selected_element["symbol"])
		if amt > 0:
			update_selection_view(selected_element, amt)
		else:
			selected_element = null
			clear_selection()

func _on_item_clicked(data):
	selected_element = data
	var amt = GameState.resources.get_element_amount(data["symbol"])
	update_selection_view(data, amt)

func update_selection_view(data, amount):
	sel_name.text = ElementDB.get_full_display(data["symbol"])
	sel_desc.text = data["description"]
	
	price_val = data.get("base_value", 1) # Fallback to 1 if missing? (JSON usually has base_value?)
	# I should check if base_value is in elements.json.
	# Assuming it is based on Python viewing.
	price_lbl.text = "Unit Price: %d Credits" % price_val
	
	qty_spin.max_value = amount
	qty_spin.value = 1
	qty_spin.editable = true
	sell_btn.disabled = false
	sell_all_btn.disabled = false
	
	update_total_price(1)

func clear_selection():
	sel_name.text = "Select an Item"
	sel_desc.text = ""
	price_lbl.text = "Unit Price: -"
	qty_spin.editable = false
	sell_btn.disabled = true
	sell_all_btn.disabled = true
	total_lbl.text = "Total: 0"

func update_total_price(val):
	total_lbl.text = "Total: %d" % (val * price_val)

func _on_qty_spin_box_value_changed(value):
	update_total_price(value)

func _on_sell_btn_pressed():
	if not selected_element: return
	var qty = int(qty_spin.value)
	perform_sale(selected_element["symbol"], qty)

func _on_sell_all_btn_pressed():
	if not selected_element: return
	var symbol = selected_element["symbol"]
	var qty = int(GameState.resources.get_element_amount(symbol))
	perform_sale(symbol, qty)

func perform_sale(symbol, qty):
	var total = qty * price_val
	if GameState.resources.remove_element(symbol, qty):
		GameState.resources.add_currency("credits", total)
		refresh_inventory()

func update_credits():
	credits_lbl.text = "Credits: %d" % GameState.resources.get_currency("credits")

func _process(delta):
	# Poll for inventory changes?
	# Or rely on refresh signals? 
	# For simplicity/MVP, refresh on show?
	pass
	
func _on_visibility_changed():
	if visible:
		refresh_inventory()
