extends "res://scripts/core/skill.gd"

# Prestige Manager: Warp-Core Reset
# Grants "Exotic Matter" (Warp Shards) based on total progress.

signal warped(shards_gained)

var total_warps: int = 0
var warp_shards: float = 0.0 # Permanent prestige currency

func _init():
	super._init("Warp")

func calculate_warp_gains() -> int:
	# Formula based on LIFETIME credits earned + total buildings
	# Logarithmic scaling to prevent infinite shard inflation
	var total_credits = GameState.resources.lifetime_credits
	var building_count = 0
	for bid in GameState.infrastructure_manager.buildings:
		building_count += GameState.infrastructure_manager.buildings[bid]
	
	var progress_score = total_credits + (building_count * 1000.0)
	if progress_score < 1000000: return 0
	
	# Shards = sqrt(score / 1M)
	var shards = floor(sqrt(progress_score / 1000000.0))
	return int(shards)

func execute_warp():
	var gains = calculate_warp_gains()
	if gains <= 0: return
	
	warp_shards += gains
	total_warps += 1
	
	# Award Starting Bonus before reset? No, usually after to ensure clean state.
	# But we need to cache the shard count.
	var current_bonus_shards = warp_shards
	
	# RESET WORLD
	GameState.resources.reset()
	GameState.infrastructure_manager.reset()
	
	# Reset Skill Levels with Partial Decay (Prestige Tier 1: Keep 30% XP)
	var decay = 0.7
	GameState.gathering_manager.reset(decay)
	GameState.processing_manager.reset(decay)
	GameState.infrastructure_manager.reset(decay)
	GameState.research_manager.reset(decay)
	GameState.shipyard_manager.reset(decay)
	GameState.fleet_manager.reset(decay)
	GameState.combat_manager.reset(decay)
	
	# Award Starting Credits based on SHARDS (Exotic Starting Kit)
	GameState.resources.add_currency("credits", current_bonus_shards * 1000.0)
	
	warped.emit(gains)
	GameState.save_game()

# GLOBAL BUFFS
func get_production_multiplier() -> float:
	return 1.0 + (warp_shards * 0.02) # 2% per shard

func get_combat_multiplier() -> float:
	return 1.0 + (warp_shards * 0.01) # 1% per shard

func get_save_data_manager() -> Dictionary:
	var data = get_save_data()
	data["total_warps"] = total_warps
	data["warp_shards"] = warp_shards
	return data

func load_save_data_manager(data: Dictionary):
	load_save_data(data)
	total_warps = data.get("total_warps", 0)
	warp_shards = data.get("warp_shards", 0.0)
