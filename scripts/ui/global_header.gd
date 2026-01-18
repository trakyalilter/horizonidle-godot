extends PanelContainer

@onready var credits_lbl = $MarginContainer/HBoxContainer/CreditsLabel
@onready var task_lbl = $MarginContainer/HBoxContainer/TaskLabel

func _ready():
	UITheme.apply_panel_style(self)
	
	# Initial sync
	update_hud()
	
	# Connect signals for real-time updates
	if GameState.resources:
		GameState.resources.currency_added.connect(func(t, a): update_credits())
		GameState.resources.currency_removed.connect(func(t, a): update_credits())

func _process(_delta):
	# Poll for task status
	update_task_status()

func update_hud():
	update_credits()

func update_credits():
	var cr = GameState.resources.get_currency("credits")
	credits_lbl.text = "Credits: %s" % UITheme.format_num(cr)

# Removed _on_energy_changed as it's no longer displayed in the header

func update_task_status():
	var status_text = "Idle"
	
	if GameState.gathering_manager and GameState.gathering_manager.is_active:
		var gm = GameState.gathering_manager
		var action_name = gm.current_action.get("name", "Gathering")
		var speed_mult = gm.get_action_speed_multiplier(gm.current_action_id)
		var prog = (gm.action_progress / (gm.action_duration / speed_mult)) * 100.0
		status_text = "Gathering: %s (%d%%)" % [action_name, int(prog)]
		
	elif GameState.processing_manager and GameState.processing_manager.is_active:
		var pm = GameState.processing_manager
		var recipe_name = pm.current_recipe.get("name", "Processing")
		var speed_mult = pm.get_recipe_speed_multiplier(pm.current_recipe_id)
		var prog = (pm.action_progress / (pm.current_recipe["duration"] / speed_mult)) * 100.0
		status_text = "Engineering: %s (%d%%)" % [recipe_name, int(prog)]
		
	elif GameState.combat_manager and GameState.combat_manager.in_combat:
		var cm = GameState.combat_manager
		status_text = "Combat: %s" % cm.current_enemy.get("name", "Unknown")
		
	elif GameState.research_manager and GameState.research_manager.is_active:
		var rm = GameState.research_manager
		var tech_name = rm.tech_tree[rm.active_tech_id]["name"]
		var prog = (rm.action_progress / rm.calculate_effective_duration(rm.active_tech_id)) * 100.0
		status_text = "Researching: %s (%d%%)" % [tech_name, int(prog)]
		
	task_lbl.text = status_text
