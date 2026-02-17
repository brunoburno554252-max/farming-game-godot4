## autoloads/skill_system.gd
## SkillSystem — Gerencia 5 habilidades com XP e níveis.
## Farming, Mining, Foraging, Fishing, Combat.
## Equivalente ao Farmer.experiencePoints do Stardew Valley.
extends Node


# =============================================================================
# STATE
# =============================================================================

## {SkillType: {xp: int, level: int}}
var _skills: Dictionary = {}


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.crop_harvested.connect(_on_crop_harvested)


func initialize_new_game() -> void:
	_skills.clear()
	for skill in Constants.SkillType.values():
		_skills[skill] = {"xp": 0, "level": 0}


# =============================================================================
# XP & LEVELING
# =============================================================================

func add_xp(skill: Constants.SkillType, amount: int) -> void:
	if not _skills.has(skill):
		_skills[skill] = {"xp": 0, "level": 0}
	
	var old_level: int = _skills[skill].level
	_skills[skill].xp += amount
	
	EventBus.skill_xp_gained.emit(skill, amount)
	
	# Check for level up
	_check_level_up(skill, old_level)


func _check_level_up(skill: Constants.SkillType, old_level: int) -> void:
	var xp: int = _skills[skill].xp
	var new_level := old_level
	
	for i in range(old_level + 1, Constants.MAX_SKILL_LEVEL + 1):
		if i < Constants.SKILL_XP_TABLE.size() and xp >= Constants.SKILL_XP_TABLE[i]:
			new_level = i
		else:
			break
	
	if new_level > old_level:
		_skills[skill].level = new_level
		EventBus.skill_level_up.emit(skill, new_level)
		
		var skill_name := Constants.SkillType.keys()[skill]
		EventBus.show_notification.emit(
			"%s subiu para nível %d!" % [skill_name.capitalize(), new_level], null
		)


# =============================================================================
# QUERIES
# =============================================================================

func get_level(skill: Constants.SkillType) -> int:
	if _skills.has(skill):
		return _skills[skill].level
	return 0

func get_xp(skill: Constants.SkillType) -> int:
	if _skills.has(skill):
		return _skills[skill].xp
	return 0

func get_xp_for_next_level(skill: Constants.SkillType) -> int:
	var level := get_level(skill)
	if level >= Constants.MAX_SKILL_LEVEL:
		return 0
	if level + 1 < Constants.SKILL_XP_TABLE.size():
		return Constants.SKILL_XP_TABLE[level + 1]
	return 99999

func get_xp_progress(skill: Constants.SkillType) -> float:
	var level := get_level(skill)
	if level >= Constants.MAX_SKILL_LEVEL:
		return 1.0
	var current_threshold := Constants.SKILL_XP_TABLE[level] if level < Constants.SKILL_XP_TABLE.size() else 0
	var next_threshold := get_xp_for_next_level(skill)
	var range_size := next_threshold - current_threshold
	if range_size <= 0:
		return 1.0
	return clampf(float(get_xp(skill) - current_threshold) / float(range_size), 0.0, 1.0)


# =============================================================================
# AUTO XP FROM EVENTS
# =============================================================================

func _on_crop_harvested(_loc: String, _tile: Vector2i, crop_id: String, _item: String, _qty: int) -> void:
	var crop := ItemDatabase.get_crop(crop_id)
	if crop:
		add_xp(Constants.SkillType.FARMING, crop.harvest_xp)


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	for skill in _skills:
		DatabaseManager.query(
			"INSERT OR REPLACE INTO skills (skill_type, level, xp) VALUES (%d, %d, %d);" % [
				int(skill), _skills[skill].level, _skills[skill].xp
			]
		)

func load_data() -> void:
	_skills.clear()
	for skill in Constants.SkillType.values():
		_skills[skill] = {"xp": 0, "level": 0}
	
	var rows := DatabaseManager.query("SELECT * FROM skills;")
	for row in rows:
		var skill_type = row.get("skill_type", 0)
		_skills[skill_type] = {
			"xp": row.get("xp", 0),
			"level": row.get("level", 0),
		}
