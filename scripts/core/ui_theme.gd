extends Node

# Color Palette
const COLORS = {
	"background": Color(0.08, 0.08, 0.12),
	"sidebar": Color(0.12, 0.12, 0.18),
	"panel_bg": Color(0.15, 0.15, 0.22),
	"accent": Color(0.2, 0.4, 0.8),
	"accent_bright": Color(0.3, 0.6, 1.0),
	"text_main": Color(0.9, 0.9, 0.95),
	"text_dim": Color(0.6, 0.6, 0.7),
	"text_accent": Color(0.0, 0.8, 1.0),
	"positive": Color(0.3, 0.7, 0.3),
	"negative": Color(0.8, 0.3, 0.3),
	"warning": Color(1.0, 0.8, 0.2)
}

const CATEGORY_COLORS = {
	"ops": Color(1.0, 0.6, 0.2),         # Orange
	"engineering": Color(0.2, 0.8, 1.0),   # Cyan
	"infrastructure": Color(0.4, 0.9, 0.4),# Green
	"combat": Color(1.0, 0.3, 0.3),        # Red
	"inventory": Color(1.0, 0.8, 0.2),     # Gold
	"research": Color(0.9, 0.4, 1.0),      # Pink/Purple
	"shipyard": Color(0.3, 0.5, 1.0),      # Blue
	"mission": Color(0.2, 1.0, 0.6)        # Teal/Emerald
}

func setup_page_background(page: Control):
	pass

func apply_card_style(panel: Control, category: String = "ops") -> StyleBoxFlat:
	var accent = CATEGORY_COLORS.get(category, COLORS["accent"])
	
	var style = StyleBoxFlat.new()
	# Vertical Gradient
	style.bg_color = COLORS["panel_bg"]
	style.draw_center = true
	
	# Border
	style.set_border_width_all(1)
	style.border_color = accent.lerp(Color.BLACK, 0.4)
	style.border_blend = true
	
	# Glow effect (Top border)
	style.border_width_top = 2
	style.border_color = accent
	
	# Rounded corners
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	
	# Shadow
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	
	panel.add_theme_stylebox_override("panel", style)
	return style

func apply_premium_button_style(button: Button, category: String = "ops"):
	var accent = CATEGORY_COLORS.get(category, COLORS["accent"])
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = accent.lerp(Color.BLACK, 0.6)
	style_normal.set_border_width_all(1)
	style_normal.border_color = accent
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.corner_radius_bottom_left = 4
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = accent.lerp(Color.BLACK, 0.4)
	style_hover.border_color = accent.lightened(0.2)
	style_hover.shadow_color = accent.lerp(Color.BLACK, 0.5)
	style_hover.shadow_size = 2
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = accent
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.2, 0.2, 0.2)
	button.add_theme_stylebox_override("disabled", style_disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 13)

func apply_progress_bar_style(pb: ProgressBar, category: String = "ops"):
	var accent = CATEGORY_COLORS.get(category, COLORS["accent"])
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = COLORS["background"].lightened(0.05)
	style_bg.corner_radius_top_left = 2
	style_bg.corner_radius_top_right = 2
	style_bg.corner_radius_bottom_right = 2
	style_bg.corner_radius_bottom_left = 2
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = accent
	style_fill.corner_radius_top_left = 2
	style_fill.corner_radius_top_right = 2
	style_fill.corner_radius_bottom_right = 2
	style_fill.corner_radius_bottom_left = 2
	
	pb.add_theme_stylebox_override("background", style_bg)
	pb.add_theme_stylebox_override("fill", style_fill)

func apply_panel_style(panel: PanelContainer):
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS["panel_bg"]
	style.set_border_width_all(1)
	style.border_color = COLORS["accent"].lerp(Color.BLACK, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)

func apply_sidebar_button_style(button: Button, is_active: bool):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = COLORS["sidebar"] if not is_active else COLORS["accent"]
	style_normal.draw_center = true
	style_normal.set_border_width_all(1)
	style_normal.border_color = COLORS["accent"] if is_active else Color.TRANSPARENT
	style_normal.content_margin_left = 15
	
	button.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = COLORS["accent"].lerp(Color.BLACK, 0.5)
	button.add_theme_stylebox_override("hover", style_hover)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = COLORS["accent"]
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	if is_active:
		button.add_theme_color_override("font_color", Color.WHITE)
	else:
		button.add_theme_color_override("font_color", COLORS["text_dim"])

func apply_modal_style(panel: PanelContainer):
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS["background"].lightened(0.02)
	style.set_border_width_all(2)
	style.border_color = COLORS["accent"]
	style.border_blend = true
	
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	
	# Heavy Shadow for depth
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 10)
	
	panel.add_theme_stylebox_override("panel", style)

func apply_tab_style(tabs: TabContainer, category: String = "ops"):
	var accent = CATEGORY_COLORS.get(category, COLORS["accent"])
	
	# Tab Selected (Matches panel background)
	var style_selected = StyleBoxFlat.new()
	style_selected.bg_color = COLORS["panel_bg"]
	style_selected.set_border_width_all(1)
	style_selected.border_color = COLORS["panel_bg"] # Seamless
	style_selected.border_width_top = 2
	style_selected.border_color = accent
	style_selected.corner_radius_top_left = 4
	style_selected.corner_radius_top_right = 4
	style_selected.content_margin_left = 12
	style_selected.content_margin_right = 12
	
	# Tab Unselected
	var style_unselected = StyleBoxFlat.new()
	style_unselected.bg_color = COLORS["sidebar"].lerp(Color.BLACK, 0.2)
	style_unselected.set_border_width_all(1)
	style_unselected.border_color = Color.TRANSPARENT
	style_unselected.corner_radius_top_left = 4
	style_unselected.corner_radius_top_right = 4
	style_unselected.content_margin_left = 10
	style_unselected.content_margin_right = 10
	
	# Tab Hover
	var style_hover = style_unselected.duplicate()
	style_hover.bg_color = COLORS["sidebar"]
	style_hover.border_width_top = 1
	style_hover.border_color = accent.lerp(Color.BLACK, 0.5)
	
	# Content Panel (The dashboard background)
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = COLORS["panel_bg"]
	style_panel.set_border_width_all(1)
	style_panel.border_color = accent.lerp(Color.BLACK, 0.5)
	style_panel.border_width_top = 2
	style_panel.border_color = accent
	style_panel.border_blend = true
	style_panel.shadow_color = Color(0, 0, 0, 0.3)
	style_panel.shadow_size = 10
	style_panel.shadow_offset = Vector2(0, 4)
	
	tabs.add_theme_stylebox_override("tab_selected", style_selected)
	tabs.add_theme_stylebox_override("tab_unselected", style_unselected)
	tabs.add_theme_stylebox_override("tab_hovered", style_hover)
	tabs.add_theme_stylebox_override("panel", style_panel)
	
	tabs.add_theme_color_override("font_selected_color", Color.WHITE)
	tabs.add_theme_color_override("font_unselected_color", COLORS["text_dim"])
	tabs.add_theme_font_size_override("font_size", 13)

func apply_sharp_button_style(button: Button, category: String = "ops"):
	var accent = CATEGORY_COLORS.get(category, COLORS["accent"])
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = accent.lerp(Color.BLACK, 0.7)
	style_normal.set_border_width_all(1)
	style_normal.border_color = accent.lerp(Color.BLACK, 0.3)
	style_normal.corner_radius_top_left = 0
	style_normal.corner_radius_top_right = 0
	style_normal.corner_radius_bottom_right = 0
	style_normal.corner_radius_bottom_left = 0
	
	# Added Padding to increase size
	style_normal.content_margin_left = 16
	style_normal.content_margin_right = 16
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = accent.lerp(Color.BLACK, 0.5)
	style_hover.border_color = accent
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = accent
	style_pressed.border_color = Color.WHITE
	
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.1, 0.1, 0.1)
	style_disabled.border_color = Color(0.2, 0.2, 0.2)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	button.add_theme_color_override("font_color", COLORS["text_dim"])
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 12)
