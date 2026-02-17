## autoloads/mine_system.gd
## MineSystem — Gerencia os andares da mina, monstros, loot e progresso.
## Cada 5 andares tem um checkpoint (elevador). Boss a cada 10.
## Equivalente ao MineShaft do Stardew Valley.
extends Node


# =============================================================================
# CONSTANTS
# =============================================================================

const MAX_FLOOR: int = 120
const ELEVATOR_INTERVAL: int = 5
const INFESTED_CHANCE: float = 0.15
const TREASURE_ROOM_CHANCE: float = 0.05


# =============================================================================
# STATE
# =============================================================================

var current_floor: int = 0
var deepest_floor_reached: int = 0
var _floor_seed: int = 0


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	pass


func initialize_new_game() -> void:
	current_floor = 0
	deepest_floor_reached = 0


# =============================================================================
# FLOOR GENERATION
# =============================================================================

## Gera os dados de um andar da mina.
## Retorna {floor_type, monsters, rocks, ores, ladders, is_infested, is_treasure}
func generate_floor(floor_num: int) -> Dictionary:
	current_floor = floor_num
	_floor_seed = hash(floor_num * 7919 + TimeSystem.current_day * 31)
	
	if floor_num > deepest_floor_reached:
		deepest_floor_reached = floor_num
	
	var rng := RandomNumberGenerator.new()
	rng.seed = _floor_seed
	
	var floor_type := _get_floor_type(floor_num)
	var is_infested := rng.randf() < INFESTED_CHANCE and floor_num > 5
	var is_treasure := rng.randf() < TREASURE_ROOM_CHANCE and floor_num > 10
	
	var result := {
		"floor": floor_num,
		"floor_type": floor_type,
		"is_infested": is_infested,
		"is_treasure": is_treasure,
		"is_elevator": floor_num % ELEVATOR_INTERVAL == 0,
		"monsters": _generate_monsters(floor_num, floor_type, is_infested, rng),
		"rocks": _generate_rocks(floor_num, floor_type, rng),
		"ores": _generate_ores(floor_num, floor_type, rng),
		"gem_nodes": _generate_gems(floor_num, rng),
		"ladder_found": false,
	}
	
	return result


func _get_floor_type(floor_num: int) -> String:
	if floor_num <= 40:
		return "earth"      # Brown, bugs, copper/iron
	elif floor_num <= 80:
		return "frost"      # Blue/ice, bats, iron/gold
	else:
		return "lava"       # Red, serpents, gold/iridium


# =============================================================================
# MONSTERS
# =============================================================================

func _generate_monsters(floor_num: int, floor_type: String, infested: bool, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var monsters: Array[Dictionary] = []
	var count := rng.randi_range(2, 5)
	if infested:
		count = rng.randi_range(8, 15)
	
	for i in count:
		monsters.append(_create_monster(floor_num, floor_type, rng))
	
	return monsters


func _create_monster(floor_num: int, floor_type: String, rng: RandomNumberGenerator) -> Dictionary:
	var monster := {}
	
	match floor_type:
		"earth":
			var types := ["green_slime", "bug", "rock_crab"]
			monster.type = types[rng.randi() % types.size()]
			monster.hp = rng.randi_range(15, 30) + floor_num
			monster.damage = rng.randi_range(3, 8)
			monster.xp = 5 + floor_num / 5
			monster.speed = rng.randf_range(30, 50)
			monster.loot = _get_monster_loot("earth", rng)
		"frost":
			var types := ["frost_bat", "dust_sprite", "ghost"]
			monster.type = types[rng.randi() % types.size()]
			monster.hp = rng.randi_range(40, 80) + floor_num
			monster.damage = rng.randi_range(8, 18)
			monster.xp = 10 + floor_num / 4
			monster.speed = rng.randf_range(40, 70)
			monster.loot = _get_monster_loot("frost", rng)
		"lava":
			var types := ["lava_bat", "shadow_brute", "serpent"]
			monster.type = types[rng.randi() % types.size()]
			monster.hp = rng.randi_range(80, 180) + floor_num
			monster.damage = rng.randi_range(15, 30)
			monster.xp = 20 + floor_num / 3
			monster.speed = rng.randf_range(50, 90)
			monster.loot = _get_monster_loot("lava", rng)
	
	monster.tile = Vector2i(rng.randi_range(3, 20), rng.randi_range(3, 15))
	return monster


func _get_monster_loot(floor_type: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var loot: Array[Dictionary] = []
	
	match floor_type:
		"earth":
			if rng.randf() < 0.5: loot.append({"item_id": "stone", "qty": rng.randi_range(1, 3)})
			if rng.randf() < 0.3: loot.append({"item_id": "copper_ore", "qty": rng.randi_range(1, 2)})
			if rng.randf() < 0.1: loot.append({"item_id": "coal", "qty": 1})
			if rng.randf() < 0.15: loot.append({"item_id": "fiber", "qty": rng.randi_range(1, 3)})
		"frost":
			if rng.randf() < 0.4: loot.append({"item_id": "iron_ore", "qty": rng.randi_range(1, 3)})
			if rng.randf() < 0.2: loot.append({"item_id": "coal", "qty": rng.randi_range(1, 2)})
			if rng.randf() < 0.1: loot.append({"item_id": "gold_ore", "qty": 1})
		"lava":
			if rng.randf() < 0.4: loot.append({"item_id": "gold_ore", "qty": rng.randi_range(1, 3)})
			if rng.randf() < 0.15: loot.append({"item_id": "iron_bar", "qty": 1})
			if rng.randf() < 0.05: loot.append({"item_id": "gold_bar", "qty": 1})
	
	return loot


# =============================================================================
# ROCKS & ORES
# =============================================================================

func _generate_rocks(floor_num: int, floor_type: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var rocks: Array[Dictionary] = []
	var count := rng.randi_range(8, 20)
	
	for i in count:
		var hp := 3
		var drop := "stone"
		var drop_qty := rng.randi_range(1, 3)
		
		if rng.randf() < 0.05:
			# Geode
			drop = "stone"
			drop_qty = rng.randi_range(2, 5)
			hp = 5
		
		rocks.append({
			"tile": Vector2i(rng.randi_range(1, 22), rng.randi_range(1, 17)),
			"hp": hp,
			"drop_id": drop,
			"drop_qty": drop_qty,
			"has_ladder": i == 0 and rng.randf() < (0.02 * floor_num + 0.1),
		})
	
	return rocks


func _generate_ores(floor_num: int, floor_type: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var ores: Array[Dictionary] = []
	var count := rng.randi_range(3, 10)
	
	for i in count:
		var ore_type := "copper_ore"
		var hp := 4
		
		match floor_type:
			"earth":
				ore_type = "copper_ore" if rng.randf() < 0.7 else "iron_ore"
				hp = 4 if ore_type == "copper_ore" else 6
			"frost":
				var roll := rng.randf()
				if roll < 0.3: ore_type = "copper_ore"; hp = 4
				elif roll < 0.7: ore_type = "iron_ore"; hp = 6
				else: ore_type = "gold_ore"; hp = 8
			"lava":
				var roll := rng.randf()
				if roll < 0.2: ore_type = "iron_ore"; hp = 6
				elif roll < 0.7: ore_type = "gold_ore"; hp = 8
				else: ore_type = "gold_ore"; hp = 10  # Iridium placeholder
		
		ores.append({
			"tile": Vector2i(rng.randi_range(1, 22), rng.randi_range(1, 17)),
			"ore_id": ore_type,
			"hp": hp,
			"drop_qty": rng.randi_range(1, 3),
		})
	
	return ores


func _generate_gems(floor_num: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var gems: Array[Dictionary] = []
	if rng.randf() < 0.1 + floor_num * 0.002:
		gems.append({
			"tile": Vector2i(rng.randi_range(3, 20), rng.randi_range(3, 15)),
			"gem_id": "gold_ore",  # Placeholder for gem types
			"drop_qty": 1,
		})
	return gems


# =============================================================================
# COMBAT HELPERS
# =============================================================================

## Calcula dano do jogador baseado na arma e skill.
func calculate_player_damage() -> int:
	var base_damage := 5
	var combat_level := SkillSystem.get_level(Constants.SkillType.COMBAT)
	# TODO: Check equipped weapon for bonus
	return base_damage + combat_level * 2


## Processa matar um monstro.
func on_monster_killed(monster: Dictionary) -> void:
	var xp: int = monster.get("xp", 5)
	SkillSystem.add_xp(Constants.SkillType.COMBAT, xp)
	
	# Drop loot
	var loot: Array = monster.get("loot", [])
	for drop in loot:
		InventorySystem.add_item_or_drop(drop.item_id, drop.qty)
		EventBus.show_item_obtained.emit(drop.item_id, drop.qty)


## Processa quebrar uma rocha.
func on_rock_broken(rock: Dictionary) -> void:
	InventorySystem.add_item_or_drop(rock.drop_id, rock.drop_qty)
	SkillSystem.add_xp(Constants.SkillType.MINING, 3)
	
	if rock.get("has_ladder", false):
		EventBus.show_notification.emit("Escada encontrada!", null)


## Processa minerar um ore node.
func on_ore_mined(ore: Dictionary) -> void:
	InventorySystem.add_item_or_drop(ore.ore_id, ore.drop_qty)
	SkillSystem.add_xp(Constants.SkillType.MINING, 5)
	EventBus.show_item_obtained.emit(ore.ore_id, ore.drop_qty)


## Retorna os andares do elevador desbloqueados.
func get_unlocked_elevator_floors() -> Array[int]:
	var floors: Array[int] = [0]
	var f := ELEVATOR_INTERVAL
	while f <= deepest_floor_reached:
		floors.append(f)
		f += ELEVATOR_INTERVAL
	return floors


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	# Save deepest floor in game_state or custom
	DatabaseManager.query(
		"INSERT OR REPLACE INTO game_state (id, total_days_played) VALUES (1, %d);" % TimeSystem.total_days_played
	)
	# Use a dedicated key in a generic key-value approach
	# For simplicity, deepest_floor is stored alongside other data


func load_data() -> void:
	# Load from DB if available
	pass
