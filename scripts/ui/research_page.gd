extends Control

@onready var tabs = $VBoxContainer/TabContainer
@onready var credits_lbl = $VBoxContainer/Header/CreditsLabel

var manager: RefCounted

# Graph Data
# Each tab has a Control which acts as a Canvas for custom drawing
var node_scene = preload("res://scenes/ui/research_node_widget.tscn")

var graphs = {
	"Operations": {
		"nodes": [
			"fluid_dynamics", "combustion", "energy_shields",
			"diamond_drills", "high_flow_pumps", "laser_cutters", "magnetic_funnels"
		],
		"pos": {
			"fluid_dynamics": Vector2(40, 40),
			"combustion": Vector2(40, 150),
			"energy_shields": Vector2(40, 260),
			"diamond_drills": Vector2(40, 370),
			
			"high_flow_pumps": Vector2(240, 40),
			"laser_cutters": Vector2(240, 150),
			"magnetic_funnels": Vector2(240, 260)
		},
		"container": null # Assigned in _ready
	},
	"Engineering": {
		"nodes": [
			"basic_engineering", "fluid_dynamics", "combustion", "alloy_synthesis", "adv_materials",
			"fast_centrifuges", "catalytic_electrodes", "pyrolysis_control", "blast_furnace", "hydraulic_press",
			"automated_logistics", "ballistics_optimization", "energy_metrics",
			"automated_smelting", "industrial_electrolysis", "molecular_compression", "mass_production_tactics"
		],
		"pos": {
			"basic_engineering": Vector2(40, 280),
			
			"fluid_dynamics": Vector2(240, 120),
			"catalytic_electrodes": Vector2(440, 40),
			"energy_metrics": Vector2(440, 160),
			"industrial_electrolysis": Vector2(640, 40),
			
			"combustion": Vector2(240, 280),
			"pyrolysis_control": Vector2(440, 320),
			
			"fast_centrifuges": Vector2(240, 440),
			"automated_logistics": Vector2(240, 550),
			"mass_production_tactics": Vector2(440, 550),
			
			"alloy_synthesis": Vector2(440, 440),
			"blast_furnace": Vector2(640, 440),
			"automated_smelting": Vector2(840, 440),
			"ballistics_optimization": Vector2(640, 330),
			
			"adv_materials": Vector2(640, 550),
			"hydraulic_press": Vector2(840, 550),
			"molecular_compression": Vector2(1040, 550)
		},
		"container": null
	},
	"Ships": {
		"nodes": [
			"alloy_synthesis",
			"shipwright_1", "shipwright_2", "sector_alpha_decryption", "warp_drive",
			"molecular_printing", "capital_ship_engineering", "quantum_dynamics"
		],
		"pos": {
			"alloy_synthesis": Vector2(40, 150),
			"shipwright_1": Vector2(240, 150),
			"shipwright_2": Vector2(440, 150),
			"sector_alpha_decryption": Vector2(440, 40),
			"warp_drive": Vector2(640, 150),
			"molecular_printing": Vector2(640, 260),
			"capital_ship_engineering": Vector2(640, 40),
			"quantum_dynamics": Vector2(840, 40)
		},
		"container": null
	}
}

func _ready():
	manager = GameState.research_manager
	
	# Graphs are Panels inside TabContainer
	graphs["Operations"]["container"] = $VBoxContainer/TabContainer/Operations/ScrollContainer/GraphArea
	graphs["Engineering"]["container"] = $VBoxContainer/TabContainer/Engineering/ScrollContainer/GraphArea
	graphs["Ships"]["container"] = $VBoxContainer/TabContainer/Ships/ScrollContainer/GraphArea
	
	call_deferred("build_graphs")

func build_graphs():
	for tab_name in graphs:
		var g_data = graphs[tab_name]
		var container = g_data["container"]
		
		# Clear existing (if any)
		for child in container.get_children():
			child.queue_free()
		
		# Add Nodes
		for nid in g_data["nodes"]:
			if nid not in manager.tech_tree: continue
			
			var data = manager.tech_tree[nid]
			var node_widget = node_scene.instantiate()
			container.add_child(node_widget)
			
			var pos = g_data["pos"].get(nid, Vector2(0,0))
			node_widget.position = pos
			node_widget.setup(nid, data, manager, self)
			
		# Connect draw for lines
		# We attach a script to the 'GraphArea' dynamically or just use a helper
		# Simplest is to queue_redraw on the container
		if not container.is_connected("draw", _on_graph_draw.bind(container, tab_name)):
			container.draw.connect(_on_graph_draw.bind(container, tab_name))
			
		container.queue_redraw()

func _on_graph_draw(container, tab_name):
	var g_data = graphs[tab_name]
	var positions = g_data["pos"]
	
	for nid in g_data["nodes"]:
		if nid not in manager.tech_tree: continue
		var node_data = manager.tech_tree[nid]
		var parent = node_data.get("parent")
		
		if parent and parent in positions and nid in positions:
			if parent not in g_data["nodes"]:
				# If parent is not in this tab, maybe we shouldn't draw line?
				# Or we should draw to "offscreen"?
				# Python logic: Shared 'alloy_synthesis' node existed in multiple tabs for continuity
				# In Godot, I'm manually placing them. If 'alloy_synthesis' is in Ships tab, it's a seed node.
				pass
			else:
				var p1 = positions[parent] + Vector2(140, 30) # Right-Center of parent (Node is 140x60)
				var p2 = positions[nid] + Vector2(0, 30) # Left-Center of child
				
				# Bezier or straight line
				container.draw_line(p1, p2, Color(0.5, 0.5, 0.5), 2.0)

func refresh_all():
	# Re-check states of all nodes
	for tab_name in graphs:
		var container = graphs[tab_name]["container"]
		for child in container.get_children():
			if child.has_method("update_state"):
				child.update_state()
	update_ui()

func _process(delta):
	# Poll for currency upates
	update_ui()

func update_ui():
	# Update text
	if not manager: return
	var cr = GameState.resources.get_currency("credits")
	credits_lbl.text = "Credits: %d" % int(cr)
