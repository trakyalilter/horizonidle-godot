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
	symbol_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS["inventory"])
	name_lbl.text = ElementDB.get_display_name(element_data["symbol"])
	amt_lbl.text = str(amount)
	
	UITheme.apply_card_style(self, "inventory")

func update_amount(new_amt):
	amount = new_amt
	amt_lbl.text = str(amount)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(element_data)
