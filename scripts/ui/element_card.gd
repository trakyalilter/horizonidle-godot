extends PanelContainer

signal clicked(element_data)

var element_data
var amount

@onready var symbol_lbl = $MarginContainer/VBoxContainer/SymbolLabel
@onready var name_lbl = $MarginContainer/VBoxContainer/NameLabel
@onready var amt_lbl = $MarginContainer/VBoxContainer/AmountLabel

func setup(p_data, p_amount):
	element_data = p_data
	amount = p_amount
	
	symbol_lbl.text = element_data["symbol"]
	name_lbl.text = element_data["name"]
	amt_lbl.text = str(amount)
	
	# Color based on category?
	# Using some hardcoded colors for now based on atomic number or category
	if amount <= 0:
		modulate = Color(0.5, 0.5, 0.5, 0.4) # Dimmed
	else:
		modulate = Color.WHITE
		
	# Category Color Logic
	var cat = element_data.get("category", "")
	var bg = get_theme_stylebox("panel", "PanelContainer").duplicate()
	
	if amount <= 0:
		bg.bg_color = Color(0.1, 0.1, 0.1) # Darker
	elif cat == "Solid":
		bg.bg_color = Color(0.2, 0.2, 0.25)
	elif cat == "Liquid":
		bg.bg_color = Color(0.2, 0.25, 0.3)
	elif cat == "Gas":
		bg.bg_color = Color(0.25, 0.2, 0.25)
	else:
		bg.bg_color = Color(0.2, 0.2, 0.2)
		
	add_theme_stylebox_override("panel", bg)

func update_amount(new_amt):
	amount = new_amt
	amt_lbl.text = str(amount)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(element_data)
