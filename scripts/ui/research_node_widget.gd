extends Panel

var nid: String
var data: Dictionary
var manager: RefCounted
var parent_graph: Node

@onready var name_lbl = $VBoxContainer/NameLabel
@onready var cost_lbl = $VBoxContainer/CostLabel
@onready var desc_tip = $TooltipPanel
@onready var desc_lbl = $TooltipPanel/MarginContainer/Label

# Colors
const COL_LOCKED = Color(0.2, 0.2, 0.2)
const COL_AVAILABLE = Color(0.3, 0.3, 0.3)
const COL_UNLOCKED = Color(0.1, 0.4, 0.2)
const BORDER_LOCKED = Color(0.4, 0.4, 0.4)
const BORDER_AVAILABLE = Color(1.0, 0.8, 0.2)
const BORDER_UNLOCKED = Color(0.0, 0.8, 0.4)

func setup(p_nid: String, p_data: Dictionary, p_manager, p_parent):
	nid = p_nid
	data = p_data
	manager = p_manager
	parent_graph = p_parent
	
	name_lbl.text = data["name"]
	cost_lbl.text = "%d Cr" % data.get("cost", 0)
	desc_lbl.text = data["description"]
	
	scale = Vector2(1,1) # Reset logic
	
	update_state()

func update_state():
	var is_unlocked = manager.is_tech_unlocked(nid)
	var can_unlock = manager.can_unlock(nid)
	
	name_lbl.add_theme_color_override("font_color", UITheme.CATEGORY_COLORS["research"])
	var style = UITheme.apply_card_style(self, "research")
	
	if is_unlocked:
		style.bg_color = COL_UNLOCKED
		style.border_color = BORDER_UNLOCKED
		cost_lbl.text = "Researched"
		cost_lbl.add_theme_color_override("font_color", Color.GREEN)
	elif can_unlock:
		style.bg_color = COL_AVAILABLE
		style.border_color = BORDER_AVAILABLE
		cost_lbl.text = "%d Cr" % data.get("cost", 0)
		cost_lbl.add_theme_color_override("font_color", Color.GOLD)
	else:
		style.bg_color = COL_LOCKED
		style.border_color = BORDER_LOCKED
		cost_lbl.text = "%d Cr" % data.get("cost", 0)
		cost_lbl.add_theme_color_override("font_color", Color.GRAY)
		
	add_theme_stylebox_override("panel", style)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not manager.is_tech_unlocked(nid):
			if manager.unlock_tech(nid):
				parent_graph.refresh_all()

func _on_mouse_entered():
	desc_tip.visible = true
	# move to front
	z_index = 10

func _on_mouse_exited():
	desc_tip.visible = false
	z_index = 0
