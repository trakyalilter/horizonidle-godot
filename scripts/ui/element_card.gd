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
	
	var display_name = ElementDB.get_display_name(element_data["symbol"])
	
	# If symbol is long (like BatteryT1), show name as primary text
	if element_data["symbol"].length() > 3:
		symbol_lbl.text = display_name
		symbol_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.text = element_data["symbol"] # Show ID as secondary
	else:
		symbol_lbl.text = element_data["symbol"]
		symbol_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.text = display_name
		
	symbol_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS.get("inventory", Color.WHITE))
	amt_lbl.text = str(amount)
	
	UITheme.apply_card_style(self, "inventory")

func update_amount(new_amt):
	amount = new_amt
	amt_lbl.text = str(amount)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(element_data)
