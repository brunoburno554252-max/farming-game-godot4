## npcs/monster_controller.gd
## MonsterController — Controla um monstro na mina.
## AI: patrol → detect player → chase → attack → return.
class_name MonsterController
extends CharacterBody2D


# =============================================================================
# CONFIG
# =============================================================================

var monster_data: Dictionary = {}
var hp: int = 20
var max_hp: int = 20
var damage: int = 5
var move_speed: float = 40.0
var xp_reward: int = 5
var loot: Array[Dictionary] = []
var monster_type: String = "green_slime"


# =============================================================================
# STATE
# =============================================================================

enum AIState { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var _state: AIState = AIState.PATROL
var _player: Node2D = null
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _hurt_timer: float = 0.0

const DETECT_RANGE: float = 96.0
const ATTACK_RANGE: float = 20.0
const LOSE_RANGE: float = 160.0
const ATTACK_COOLDOWN: float = 1.2

var _sprite: ColorRect  ## Placeholder visual
var _hp_bar_bg: ColorRect
var _hp_bar_fill: ColorRect


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	add_to_group("monsters")
	add_to_group("interactable")
	
	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)
	
	# Visual placeholder (colored rect)
	_sprite = ColorRect.new()
	_sprite.size = Vector2(14, 14)
	_sprite.position = Vector2(-7, -10)
	add_child(_sprite)
	_update_color()
	
	# HP bar
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	_hp_bar_bg.size = Vector2(16, 3)
	_hp_bar_bg.position = Vector2(-8, -16)
	add_child(_hp_bar_bg)
	
	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.color = Color(0.8, 0.2, 0.2)
	_hp_bar_fill.size = Vector2(16, 3)
	_hp_bar_fill.position = Vector2(-8, -16)
	add_child(_hp_bar_fill)


func initialize(data: Dictionary) -> void:
	monster_data = data
	monster_type = data.get("type", "green_slime")
	hp = data.get("hp", 20)
	max_hp = hp
	damage = data.get("damage", 5)
	move_speed = data.get("speed", 40.0)
	xp_reward = data.get("xp", 5)
	
	var loot_raw: Array = data.get("loot", [])
	loot.clear()
	for l in loot_raw:
		loot.append(l)
	
	var tile := data.get("tile", Vector2i(5, 5))
	global_position = Vector2(tile) * Constants.TILE_SIZE_F
	
	_update_color()
	_patrol_target = global_position + Vector2(randf_range(-48, 48), randf_range(-48, 48))


# =============================================================================
# AI
# =============================================================================

func _physics_process(delta: float) -> void:
	if _state == AIState.DEAD:
		return
	
	# Find player
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	
	_attack_cooldown = maxf(0, _attack_cooldown - delta)
	
	match _state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.PATROL:
			_process_patrol(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)
		AIState.HURT:
			_process_hurt(delta)
	
	_update_hp_bar()


func _process_idle(delta: float) -> void:
	_patrol_timer -= delta
	if _patrol_timer <= 0:
		_patrol_target = global_position + Vector2(randf_range(-48, 48), randf_range(-48, 48))
		_state = AIState.PATROL
	
	if _player and global_position.distance_to(_player.global_position) < DETECT_RANGE:
		_state = AIState.CHASE


func _process_patrol(delta: float) -> void:
	var dir := (_patrol_target - global_position)
	if dir.length() < 4.0:
		_state = AIState.IDLE
		_patrol_timer = randf_range(1.0, 3.0)
		return
	
	velocity = dir.normalized() * move_speed * 0.5
	move_and_slide()
	
	if _player and global_position.distance_to(_player.global_position) < DETECT_RANGE:
		_state = AIState.CHASE


func _process_chase(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_state = AIState.PATROL
		return
	
	var dist := global_position.distance_to(_player.global_position)
	if dist > LOSE_RANGE:
		_state = AIState.PATROL
		return
	
	if dist < ATTACK_RANGE and _attack_cooldown <= 0:
		_state = AIState.ATTACK
		return
	
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()


func _process_attack(_delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_state = AIState.PATROL
		return
	
	# Deal damage
	var combat := _player.get_node_or_null("PlayerCombat")
	if combat and combat.has_method("take_damage"):
		var knockback_dir := (_player.global_position - global_position)
		combat.take_damage(damage, knockback_dir)
	
	_attack_cooldown = ATTACK_COOLDOWN
	_state = AIState.CHASE


func _process_hurt(delta: float) -> void:
	_hurt_timer -= delta
	if _hurt_timer <= 0:
		_sprite.modulate = Color.WHITE
		if hp <= 0:
			_die()
		else:
			_state = AIState.CHASE


# =============================================================================
# DAMAGE
# =============================================================================

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	_state = AIState.HURT
	_hurt_timer = 0.2
	_sprite.modulate = Color(1.0, 0.3, 0.3)
	
	if knockback_dir.length_squared() > 0:
		velocity = knockback_dir.normalized() * 100.0
		move_and_slide()
	
	EventBus.play_sfx.emit("monster_hit")


func _die() -> void:
	_state = AIState.DEAD
	MineSystem.on_monster_killed(monster_data)
	SkillSystem.add_xp(Constants.SkillType.COMBAT, xp_reward)
	queue_free()


# =============================================================================
# VISUAL
# =============================================================================

func _update_color() -> void:
	match monster_type:
		"green_slime": _sprite.color = Color(0.2, 0.8, 0.2)
		"bug": _sprite.color = Color(0.4, 0.3, 0.1)
		"rock_crab": _sprite.color = Color(0.5, 0.5, 0.5)
		"frost_bat": _sprite.color = Color(0.4, 0.6, 1.0)
		"dust_sprite": _sprite.color = Color(0.3, 0.3, 0.5)
		"ghost": _sprite.color = Color(0.8, 0.8, 0.9, 0.6)
		"lava_bat": _sprite.color = Color(1.0, 0.3, 0.1)
		"shadow_brute": _sprite.color = Color(0.2, 0.1, 0.3)
		"serpent": _sprite.color = Color(0.6, 0.1, 0.1)
		_: _sprite.color = Color(0.7, 0.2, 0.2)


func _update_hp_bar() -> void:
	if max_hp <= 0:
		return
	var ratio := float(hp) / float(max_hp)
	_hp_bar_fill.size.x = 16.0 * ratio
	_hp_bar_bg.visible = hp < max_hp
	_hp_bar_fill.visible = hp < max_hp
