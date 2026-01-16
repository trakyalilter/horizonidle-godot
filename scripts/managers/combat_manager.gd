extends "res://scripts/core/skill.gd"

var in_combat = false
var current_zone = null
var current_enemy = null
var target_enemy_id = null

# Battle State
var player_hp = 0
var player_max_hp = 100
var player_shield = 0.0
var player_max_shield = 0.0

var enemy_hp = 0
var enemy_max_hp = 100
var enemy_shield = 0.0
var enemy_max_shield = 0.0

var combat_timer = 0.0
var attack_interval = 1.0

# Log & Events
var combat_log: Array[String] = []
var combat_events: Array[Dictionary] = [] # [{type, text, color, side}]

# Consumables
var equipped_consumable_id = null
var auto_consume_enabled = false
var auto_consume_threshold = 0.3
var consumable_cooldown = 0.0
var consumable_cooldown_max = 10.0

signal enemy_defeated(enemy_id)

# Buffs
var active_buffs = {} # {buff_name: duration}

var zones = {
	"lunar_orbit": {
		"name": "Lunar Orbit",
		"desc": "Low threat sector populated by rogue mining drones.",
		"difficulty": 1,
		"enemies": ["lunar_drone", "dust_mite", "scrap_collector", "survey_probe"]
	},
	"asteroid_belt": {
		"name": "Asteroid Belt",
		"desc": "Dense field with pirate skiffs and kinetic hazards.",
		"difficulty": 2,
		"enemies": ["pirate_skiff", "rock_golem", "claim_jumper", "ore_hauler"]
	},
	"mars_debris": {
		"name": "Mars Debris Field",
		"desc": "Wreckage of the old Martian shipyards. Scavengers abound.",
		"difficulty": 3,
		"enemies": ["scavenger_mech", "martian_sentry", "derelict_frigate", "salvage_swarm"]
	},
	"titan_halo": {
		"name": "Titan's Halo",
		"desc": "Frozen rings around the gas giant. Extreme cold and pirate lords.",
		"difficulty": 4,
		"enemies": ["cryo_drone", "pirate_gunship", "frozen_hulk", "smuggler_cutter"]
	},
	"sector_alpha": {
		"name": "Sector Alpha",
		"desc": "Uncharted region rich in Titanium. High threat.",
		"difficulty": 5,
		"enemies": ["alien_frigate", "xenon_corvette", "xenon_mothership"],
		"research_req": "sector_alpha_decryption"
	},
	"sector_beta": {
		"name": "Sector Beta - Mining Colony Ruins",
		"desc": "Abandoned mining colony. Automated defense systems hostile. Rich in industrial metals.",
		"difficulty": 6,
		"enemies": ["mining_sentinel", "defense_turret", "colony_overseer"],
		"research_req": "deep_space_nav"
	},
	"sector_gamma": {
		"name": "Sector Gamma - Radioactive Nebula",
		"desc": "Radioactive nebula. Mutated organisms detected. Extreme danger.",
		"difficulty": 7,
		"enemies": ["radiation_beast", "nebula_leviathan", "gamma_colossus"],
		"research_req": "radiation_shielding"
	},
	"sector_delta": {
		"name": "Sector Delta - Crystalline Fields",
		"desc": "Crystalline asteroid field. Unknown energy signatures. Ultimate challenge.",
		"difficulty": 8,
		"enemies": ["crystal_golem", "energy_wraith", "sentinel_prime"],
		"research_req": "exotic_matter_analysis"
	}
}

var enemy_db = {
	"lunar_drone": {
		"name": "Lunar Drone",
		"stats": {"hp": 50, "max_shield": 0, "atk": 5, "def": 20},
		"loot": [["Scrap", 1, 3], ["Fe", 1, 3]],
		"rare_loot": [["Cu", 0.4, 1, 2], ["Chip", 0.05, 1, 1]],
		"xp": 10
	},
	"dust_mite": {
		"name": "Space Dust Mite",
		"stats": {"hp": 30, "max_shield": 0, "atk": 2, "def": 0},
		"loot": [["C", 1, 2]],
		"rare_loot": [["Scrap", 0.2, 1, 1]],
		"xp": 5
	},
	# New Lunar Orbit Enemies
	"scrap_collector": {
		"name": "Scrap Collector",
		"stats": {"hp": 35, "max_shield": 0, "atk": 4, "def": 8},
		"loot": [["Scrap", 3, 6]],  # Best Scrap farm (for recycling)
		"rare_loot": [["Fe", 0.4, 2, 4]],  # Bonus Iron
		"xp": 7
	},
	"survey_probe": {
		"name": "Derelict Survey Probe",
		"stats": {"hp": 70, "max_shield": 30, "atk": 8, "def": 30},
		"loot": [["Si", 3, 5]],  # Best early Silicon farm
		"rare_loot": [["NavData", 0.08, 1, 1], ["Chip", 0.05, 1, 1]],
		"xp": 15
	},
	# New Asteroid Belt Enemies
	"claim_jumper": {
		"name": "Claim Jumper",
		"stats": {"hp": 120, "max_shield": 40, "atk": 14, "def": 8},
		"loot": [["credits", 50, 100]],  # Best credits farm in D2
		"rare_loot": [["Cu", 0.5, 2, 4], ["NavData", 0.1, 1, 1]],  # Cu as rare keeps Lunar Drone relevant
		"xp": 22
	},
	"ore_hauler": {
		"name": "Ore Hauler Wreck",
		"stats": {"hp": 250, "max_shield": 0, "atk": 6, "def": 50},
		"loot": [["Fe", 8, 15], ["C", 5, 10]],  # Best Fe+C bulk farm
		"rare_loot": [["W", 0.15, 1, 2]],  # Tungsten introduction
		"xp": 28
	},
	# New Mars Debris Enemies
	"derelict_frigate": {
		"name": "Derelict Frigate",
		"stats": {"hp": 550, "max_shield": 180, "atk": 20, "def": 35},
		"loot": [["Steel", 2, 5], ["Scrap", 8, 15]],  # Steel source
		"rare_loot": [["Circuit", 0.25, 1, 2], ["Chip", 0.15, 1, 1]],
		"xp": 55
	},
	"salvage_swarm": {
		"name": "Salvage Swarm",
		"stats": {"hp": 90, "max_shield": 0, "atk": 40, "def": 0},
		"loot": [["Scrap", 10, 20]],  # Glass cannon, massive Scrap
		"rare_loot": [["Resin", 0.3, 1, 2], ["Cu", 0.2, 1, 2]],
		"xp": 35
	},
	# New Titan's Halo Enemies
	"frozen_hulk": {
		"name": "Frozen Hulk",
		"stats": {"hp": 650, "max_shield": 250, "atk": 18, "def": 70},
		"loot": [["C", 10, 20]],  # Best Carbon farm
		"rare_loot": [["Graphite", 0.35, 1, 3], ["W", 0.15, 1, 2]],
		"xp": 75
	},
	"smuggler_cutter": {
		"name": "Smuggler Cutter",
		"stats": {"hp": 450, "max_shield": 180, "atk": 32, "def": 25},
		"loot": [["credits", 100, 200]],  # Best credits in D4
		"rare_loot": [["Li", 0.25, 1, 3], ["Ti", 0.2, 1, 2]],  # Rare Li/Ti
		"xp": 95
	},
	"pirate_skiff": {
		"name": "Pirate Skiff",
		"stats": {"hp": 150, "max_shield": 50, "atk": 15, "def": 10},
		"loot": [["credits", 20, 60], ["Scrap", 3, 6]],
		"rare_loot": [["Cu", 0.6, 2, 4], ["NavData", 0.1, 1, 1]],
		"xp": 25
	},
	"rock_golem": {
		"name": "Silicate Golem",
		"stats": {"hp": 300, "max_shield": 0, "atk": 8, "def": 100},
		"loot": [["Si", 10, 20]],
		"rare_loot": [["Ti", 0.1, 1, 2]],
		"xp": 30
	},
	"scavenger_mech": {
		"name": "Scavenger Mech",
		"stats": {"hp": 400, "max_shield": 100, "atk": 25, "def": 60},
		"loot": [["Fe", 5, 10], ["Scrap", 5, 10]],
		"rare_loot": [["Cu", 0.3, 2, 5], ["W", 0.1, 1, 2]],
		"xp": 55
	},
	"martian_sentry": {
		"name": "Martian Sentry",
		"stats": {"hp": 250, "max_shield": 250, "atk": 30, "def": 10},
		"loot": [["C", 5, 10]],
		"rare_loot": [["Resin", 0.1, 1, 2], ["Chip", 0.5, 1, 2]],
		"xp": 60
	},
	"cryo_drone": {
		"name": "Cryo Drone",
		"stats": {"hp": 300, "max_shield": 400, "atk": 20, "def": 20},
		"loot": [["H", 5, 15], ["Water", 5, 10]],
		"rare_loot": [["Mesh", 0.05, 1, 1]],
		"xp": 75
	},
	"pirate_gunship": {
		"name": "Pirate Gunship",
		"stats": {"hp": 800, "max_shield": 300, "atk": 45, "def": 40},
		"loot": [["credits", 50, 150], ["Ti", 1, 3]],
		"rare_loot": [["Seal", 0.05, 1, 1], ["NavData", 0.2, 1, 3]],
		"xp": 120
	},
	"alien_frigate": {
		"name": "Xenon Patrol Frigate",
		"stats": {"hp": 600, "max_shield": 1000, "atk": 25, "def": 5},
		"loot": [["Ti", 5, 10], ["Scrap", 5, 10]],
		"rare_loot": [["NavData", 0.2, 1, 2], ["Chip", 0.2, 1, 2], ["VoidArtifact", 0.1, 1, 1]],
		"xp": 100
	},
	"xenon_corvette": {
		"name": "Xenon Corvette",
		"stats": {"hp": 600, "max_shield": 3000, "atk": 40, "def": 40},
		"loot": [["Ti", 2, 5], ["U", 2, 5]],
		"rare_loot": [["NavData", 0.2, 1, 2], ["VoidArtifact", 0.2, 1, 1]],
		"xp": 100
	},
	"xenon_mothership": {
		"name": "XENON MOTHERSHIP",
		"stats": {"hp": 5000, "max_shield": 10000, "atk": 160, "def": 120},
		"loot": [["Ti", 50, 100], ["Chip", 10, 20]],
		"rare_loot": [["QuantumCore", 1.0, 1, 1], ["VoidArtifact", 1.0, 2, 5]],
		"xp": 1000
	},
	# Sector Beta Enemies (Difficulty 6) - HP ~8k-15k
	"mining_sentinel": {
		"name": "Mining Sentinel MK-VII",
		"stats": {"hp": 8000, "max_shield": 5000, "atk": 80, "def": 50},
		"loot": [["Al", 3, 8], ["Bronze", 2, 5], ["Steel", 5, 10]],
		"rare_loot": [["Co", 0.4, 1, 3], ["Ni", 0.4, 1, 3], ["Circuit", 0.3, 1, 2]],
		"xp": 200
	},
	"defense_turret": {
		"name": "Automated Defense Turret",
		"stats": {"hp": 15000, "max_shield": 0, "atk": 120, "def": 80},
		"loot": [["Steel", 10, 20], ["Circuit", 2, 5], ["Hydraulics", 1, 3]],
		"rare_loot": [["Cr", 0.3, 1, 2], ["AdvCircuit", 0.2, 1, 1]],
		"xp": 250
	},
	"colony_overseer": {
		"name": "Colony Overseer AI",
		"stats": {"hp": 12000, "max_shield": 8000, "atk": 100, "def": 60},
		"loot": [["AdvCircuit", 2, 4], ["Co", 2, 5], ["Ni", 2, 5]],
		"rare_loot": [["Pd", 0.15, 1, 1], ["AICore", 0.1, 1, 1]],
		"xp": 300
	},
	# Sector Gamma Enemies (Difficulty 7) - HP ~20k-80k
	"radiation_beast": {
		"name": "Gamma Radiation Beast",
		"stats": {"hp": 20000, "max_shield": 12000, "atk": 150, "def": 70},
		"loot": [["U", 5, 10], ["Zn", 3, 6], ["Resin", 2, 4]],
		"rare_loot": [["Pt", 0.15, 1, 2], ["ReactiveCore", 0.2, 1, 1]],
		"xp": 500
	},
	"nebula_leviathan": {
		"name": "Nebula Leviathan",
		"stats": {"hp": 35000, "max_shield": 20000, "atk": 200, "def": 90},
		"loot": [["U", 10, 20], ["Graphite", 15, 25], ["credits", 300, 600]],
		"rare_loot": [["Pt", 0.25, 1, 3], ["Pd", 0.2, 1, 2], ["ExoticMatter", 0.1, 1, 1]],
		"xp": 800
	},
	"gamma_colossus": {
		"name": "GAMMA COLOSSUS",
		"stats": {"hp": 80000, "max_shield": 40000, "atk": 300, "def": 150},
		"loot": [["Pt", 5, 10], ["Pd", 3, 6], ["QuantumCore", 1, 2]],
		"rare_loot": [["Ir", 0.3, 1, 2], ["ExoticIsotope", 0.2, 1, 1]],
		"xp": 2000
	},
	# Sector Delta Enemies (Difficulty 8) - HP ~50k-150k
	"crystal_golem": {
		"name": "Crystalline Golem",
		"stats": {"hp": 50000, "max_shield": 0, "atk": 180, "def": 200},
		"loot": [["Si", 50, 100], ["Graphite", 20, 40], ["Diamond", 1, 3]],
		"rare_loot": [["Ir", 0.2, 1, 2], ["SyntheticCrystal", 0.15, 1, 1]],
		"xp": 1500
	},
	"energy_wraith": {
		"name": "Energy Wraith",
		"stats": {"hp": 30000, "max_shield": 50000, "atk": 250, "def": 50},
		"loot": [["ExoticMatter", 2, 5], ["H", 20, 40], ["Resin", 5, 10]],
		"rare_loot": [["AntimatterParticle", 0.1, 1, 1], ["VoidCrystal", 0.15, 1, 1]],
		"xp": 1800
	},
	"sentinel_prime": {
		"name": "SENTINEL PRIME",
		"stats": {"hp": 150000, "max_shield": 80000, "atk": 400, "def": 180},
		"loot": [["Ir", 10, 20], ["Diamond", 5, 10], ["QuantumCore", 2, 4]],
		"rare_loot": [["Os", 0.25, 1, 3], ["AncientTech", 0.2, 1, 1]],
		"xp": 5000
	}
}


func _init():
	super._init("Combat")

func get_available_zones() -> Array:
	var available = []
	for zid in zones:
		var data = zones[zid]
		var req = data.get("research_req")
		if req:
			if GameState.research_manager.is_tech_unlocked(req):
				available.append({"id": zid, "data": data})
		else:
			available.append({"id": zid, "data": data})
	return available

func start_expedition(zone_id: String):
	if not zone_id in zones: return
	GameState.set_active_manager(self)
	current_zone = zones[zone_id]
	in_combat = true
	spawn_enemy()
	log_msg("Warped to %s." % current_zone["name"])
	target_enemy_id = null

func set_target_enemy(enemy_id):
	if enemy_id and enemy_id in enemy_db:
		GameState.set_active_manager(self)
		target_enemy_id = enemy_id
		if in_combat:
			spawn_enemy() # Respawn immediately
		else:
			in_combat = true
			spawn_enemy()
		log_msg("Targeting: %s" % enemy_db[enemy_id]["name"])
	else:
		target_enemy_id = null
		log_msg("Targeting cleared.")

func spawn_enemy():
	var eid = ""
	if target_enemy_id:
		eid = target_enemy_id
	else:
		if not current_zone: return
		var list_enemies = current_zone["enemies"]
		eid = list_enemies[randi() % list_enemies.size()]
		
	var e_data = enemy_db[eid]
	
	current_enemy = {
		"id": eid,
		"name": e_data["name"],
		"max_hp": e_data["stats"]["hp"],
		"atk": e_data["stats"]["atk"],
		"def": e_data["stats"]["def"],
		"max_shield": e_data["stats"].get("max_shield", 0),
		"loot": e_data["loot"],
		"rare_loot": e_data.get("rare_loot", []),
		"xp": e_data["xp"]
	}
	
	enemy_hp = current_enemy["max_hp"]
	enemy_max_hp = current_enemy["max_hp"]
	enemy_shield = float(current_enemy["max_shield"])
	enemy_max_shield = float(current_enemy["max_shield"])
	
	if player_hp <= 0:
		var sm = GameState.shipyard_manager
		player_max_hp = sm.max_hp
		player_hp = player_max_hp
		player_max_shield = sm.max_shield
		player_shield = player_max_shield
		
	log_msg("Encountered: " + current_enemy["name"])

func retreat():
	in_combat = false
	current_enemy = null
	combat_timer = 0.0
	log_msg("Emergency Warp engaged! Expedition aborted.")

func stop_action():
	retreat()

func process_tick(delta: float):
	if not in_combat or not current_enemy: return
	
	combat_timer += delta
	if combat_timer >= attack_interval:
		combat_turn()
		combat_timer = 0.0
		
	# Cooldowns tick per second conceptually, so here we do it per tick (delta)
	if consumable_cooldown > 0:
		consumable_cooldown -= delta

func combat_turn():
	var sm = GameState.shipyard_manager
	
	# Auto-Consume
	if auto_consume_enabled and equipped_consumable_id:
		var hp_thresh = auto_consume_threshold * player_max_hp
		if player_hp < hp_thresh:
			use_consumable()
		elif equipped_consumable_id == "Mesh": # Shield Item
			var s_thresh = auto_consume_threshold * player_max_shield
			if player_shield < s_thresh:
				use_consumable()

	# Buff Duration Logic
	if "dmg_bonus_duration" in active_buffs:
		active_buffs["dmg_bonus_duration"] -= 1
		if active_buffs["dmg_bonus_duration"] <= 0:
			if "dmg_bonus_k" in active_buffs: active_buffs.erase("dmg_bonus_k")
			if "dmg_bonus_e" in active_buffs: active_buffs.erase("dmg_bonus_e")
			active_buffs.erase("dmg_bonus_duration")
			log_msg("Ammo depleted.")

	# Shield Regen
	if player_shield < player_max_shield:
		player_shield = min(player_max_shield, player_shield + sm.shield_regen)
		
	if enemy_shield < enemy_max_shield:
		enemy_shield = min(enemy_max_shield, enemy_shield + (enemy_max_shield * 0.05))

	# --- Player Turn ---
	var p_atk_k = sm.attack_kinetic
	var p_atk_e = sm.attack_energy
	
	# Ammo Logic
	var ammo_bonus_k = 0
	var ammo_bonus_e = 0
	var can_fire = true
	
	if sm.active_ammo and sm.active_ammo != "":
		var qty = GameState.resources.get_element_amount(sm.active_ammo)
		if qty > 0:
			GameState.resources.remove_element(sm.active_ammo, 1)
			# Tiered ammo bonuses
			if sm.active_ammo == "SlugT1": ammo_bonus_k = 5
			elif sm.active_ammo == "SlugT2": ammo_bonus_k = 15
			elif sm.active_ammo == "SlugT3": ammo_bonus_k = 30
			elif sm.active_ammo == "CellT1": ammo_bonus_e = 5
			elif sm.active_ammo == "CellT2": ammo_bonus_e = 15
			elif sm.active_ammo == "CellT3": ammo_bonus_e = 30
		else:
			can_fire = false
			log_msg("Out of Ammo: %s!" % sm.active_ammo)

	
	if not can_fire:
		log_msg("WEAPONS OFFLINE (No Ammo)")
		return
		
	if p_atk_k == 0 and p_atk_e == 0: p_atk_k = sm.attack
	
	# Buff Application
	p_atk_k += ammo_bonus_k + active_buffs.get("dmg_bonus_k", 0)
	p_atk_e += ammo_bonus_e + active_buffs.get("dmg_bonus_e", 0)
	
	var e_def = current_enemy.get("def", 0)
	var res = resolve_damage(p_atk_k, p_atk_e, enemy_shield, e_def)
	# res = [shield_dmg, hull_dmg, is_crit]
	
	# Targeting Computer Logic
	# Force crit check if not already crit
	if not res[2]: 
		var crit_chance_bonus = 0.0
		# Check Ship Loadout for 'targeting_computer'
		# ShipyardManager exposes loadout?
		if "loadout" in sm: # Dictionary
			for slot in sm.loadout:
				if sm.loadout[slot] == "targeting_computer":
					crit_chance_bonus += 0.15 # 15% Crit
					
		if crit_chance_bonus > 0 and randf() < crit_chance_bonus:
			res[2] = true # Force Crit
			res[0] = int(res[0] * 1.5)
			res[1] = int(res[1] * 1.5)
	
	enemy_shield = max(0, enemy_shield - res[0])
	enemy_hp -= res[1]
	
	if res[0] > 0:
		combat_events.append({"type": "dmg_shield", "text": "-%d" % res[0], "color": Color.CYAN, "side": "enemy"})
	if res[1] > 0:
		combat_events.append({"type": "dmg_hull", "text": "-%d" % res[1], "color": Color.RED, "side": "enemy"})
		
	var msg = "PLAYER: -%d Shield, -%d Hull" % [res[0], res[1]]
	if res[2]: msg += " (CRIT!)"
	if ammo_bonus_k > 0 or ammo_bonus_e > 0: msg += " [AMMO]"
	log_msg(msg)
	
	if enemy_hp <= 0:
		win_fight()
		return

	# --- Enemy Turn ---
	var e_atk = current_enemy["atk"]
	var e_atk_k = e_atk
	var e_atk_e = 0
	if "alien" in current_enemy["id"]: # Simple check
		e_atk_k = 0
		e_atk_e = e_atk
		
	# Dodge
	if randf() * 100 < sm.evasion:
		log_msg("Player Dodged!")
		combat_events.append({"type": "miss", "text": "MISS", "color": Color.WHITE, "side": "player"})
	else:
		var p_def = sm.defense
		var eres = resolve_damage(e_atk_k, e_atk_e, player_shield, p_def)
		
		player_shield = max(0, player_shield - eres[0])
		player_hp -= eres[1]
		
		if eres[0] > 0:
			combat_events.append({"type": "dmg_shield", "text": "-%d" % eres[0], "color": Color.CYAN, "side": "player"})
		if eres[1] > 0:
			combat_events.append({"type": "dmg_hull", "text": "-%d" % eres[1], "color": Color.RED, "side": "player"})

		log_msg("ENEMY: -%d Shield, -%d Hull" % [eres[0], eres[1]])

	if player_hp <= 0:
		lose_fight()

func resolve_damage(atk_k, atk_e, c_shield, c_armor):
	var shield_dmg_pot = (atk_k * 0.5) + (atk_e * 1.5)
	
	var damage_to_shield = 0.0
	var bleed_ratio = 1.0
	
	if c_shield > 0:
		if shield_dmg_pot >= c_shield:
			damage_to_shield = c_shield
			var remaining = shield_dmg_pot - c_shield
			bleed_ratio = remaining / shield_dmg_pot if shield_dmg_pot > 0 else 0.0
		else:
			damage_to_shield = shield_dmg_pot
			bleed_ratio = 0.0
			
	var damage_to_hull = 0.0
	if bleed_ratio > 0:
		var hull_dmg_pot = ((atk_k * 1.2) + (atk_e * 0.5)) * bleed_ratio
		var mitigation = float(c_armor) / (float(c_armor) + 20.0)
		damage_to_hull = hull_dmg_pot * (1.0 - mitigation)
		
	var variance = randf_range(0.9, 1.1)
	var is_crit = false
	if randf() < 0.05:
		variance *= 1.5
		is_crit = true
		
	return [int(damage_to_shield * variance), int(damage_to_hull * variance), is_crit]

func win_fight():
	log_msg("Destroyed %s!" % current_enemy["name"])
	
	# Loot
	var loot = current_enemy["loot"]
	for entry in loot:
		# entry = [item, min, max]
		var item = entry[0]
		var qty = randi_range(entry[1], entry[2])
		if item == "credits":
			GameState.resources.add_currency("credits", qty)
		else:
			GameState.resources.add_element(item, qty)
		log_msg("Looted: %d %s" % [qty, item])
		
	# Rare Loot
	var rare = current_enemy["rare_loot"]
	for entry in rare:
		# entry = [item, chance, min, max]
		if randf() < entry[1]:
			var qty = randi_range(entry[2], entry[3])
			GameState.resources.add_element(entry[0], qty)
			log_msg("RARE DROP: %d %s!" % [qty, entry[0]])
			
	add_xp(current_enemy["xp"])
	enemy_defeated.emit(current_enemy["id"])
	spawn_enemy()

func lose_fight():
	log_msg("CRITICAL FAILURE. Ship destroyed.")
	retreat()

func equip_consumable(item_id):
	equipped_consumable_id = item_id

func toggle_auto_consume(enabled):
	auto_consume_enabled = enabled

func use_consumable():
	if not in_combat or not equipped_consumable_id: return
	if consumable_cooldown > 0: return
	
	if GameState.resources.get_element_amount(equipped_consumable_id) < 1:
		log_msg("Out of %s!" % equipped_consumable_id)
		return
		
	GameState.resources.remove_element(equipped_consumable_id, 1)
	consumable_cooldown = consumable_cooldown_max
	
	# CONSUMABLES (Healing Items Only)
	# Note: Ammo items (SlugT1, CellT1, etc.) are handled in shipyard active_ammo slot
	
	if equipped_consumable_id == "Mesh":
		# Shield Repair
		var heal_amount = 50
		player_shield = min(player_max_shield, player_shield + heal_amount)
		combat_events.append({"type": "heal", "text": "+%d Shield" % heal_amount, "color": Color.GREEN, "side": "player"})
		log_msg("Used Nanoweave Mesh (+%d Shield)" % heal_amount)
		
	elif equipped_consumable_id == "Seal":
		# Hull Repair
		var heal_amount = 50
		player_hp = min(player_max_hp, player_hp + heal_amount)
		combat_events.append({"type": "heal", "text": "+%d HP" % heal_amount, "color": Color.GREEN, "side": "player"})
		log_msg("Used Hull Sealant (+%d HP)" % heal_amount)
		
	else:
		# Unknown consumable - just consume it silently
		log_msg("Used %s (no effect)" % equipped_consumable_id)


func log_msg(msg: String):
	combat_log.append(msg)
	if combat_log.size() > 20:
		combat_log.pop_front()
	# Signal?
	
func get_save_data_manager() -> Dictionary:
	var data = get_save_data()
	# Save XP is handled by base Skill.
	# We generally don't save mid-combat state for idle games usually, just reset to home.
	return data

func load_save_data_manager(data: Dictionary):
	load_save_data(data)

func reset():
	super.reset()
	retreat()
	log_msg("Combat Reset.")
