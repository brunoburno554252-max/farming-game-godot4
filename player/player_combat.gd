## player/player_combat.gd
## PlayerCombat — Componente de combate do jogador.
## Gerencia HP, dano recebido, invencibilidade, e ataque corpo-a-corpo.
## Anexado ao PlayerController como child node.
class_name PlayerCombat
extends Node


# =============================================================================
# CONSTANTS
# =============================================================================

const MAX_HP: int = 100
const INVINCIBILITY_DURATION: float = 1.0
const KNOCKBACK_FORCE: float = 200.0
const ATTACK_RANGE: float = 32.0


# =============================================================================
# STATE
# =============================================================================

var current_hp: int = MAX_HP
var is_invincible: bool = false
var _invincibility_timer: float = 0.0
var _player: CharacterBody2D


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_player = get_parent() as CharacterBody2D


func _process(delta: float) -> void:
	if _invincibility_timer > 0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			is_invincible = false
			# Restore sprite visibility
			var sprite := _player.get_node_or_null("Sprite")
			if sprite:
				sprite.modulate.a = 1.0
		else:
			# Flash effect
			var sprite := _player.get_node_or_null("Sprite")
			if sprite:
				sprite.modulate.a = 0.5 + 0.5 * sin(_invincibility_timer * 20.0)


# =============================================================================
# DAMAGE
# =============================================================================

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or current_hp <= 0:
		return
	
	current_hp = maxi(0, current_hp - amount)
	is_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	
	EventBus.play_sfx.emit("player_hurt")
	EventBus.show_notification.emit("-%d HP" % amount, null)
	
	# Knockback
	if knockback_dir.length_squared() > 0 and _player:
		_player.velocity = knockback_dir.normalized() * KNOCKBACK_FORCE
	
	if current_hp <= 0:
		_on_death()


func heal(amount: int) -> void:
	current_hp = mini(MAX_HP, current_hp + amount)


func _on_death() -> void:
	# Perder 10% do gold e alguns itens (como Stardew)
	var gold_lost := int(InventorySystem.gold * 0.1)
	if gold_lost > 0:
		InventorySystem.spend_gold(gold_lost)
	
	EventBus.show_notification.emit("Você desmaiou na mina...", null)
	EventBus.player_passed_out.emit("mine_death")
	
	# Restaurar HP para o próximo dia
	current_hp = MAX_HP


# =============================================================================
# ATTACK
# =============================================================================

## Executa um ataque na direção que o jogador está olhando.
## Retorna Array de monstros atingidos (para o sistema de combate processar).
func perform_attack() -> Array[Node]:
	var hit_targets: Array[Node] = []
	
	if not _player:
		return hit_targets
	
	var direction := _get_facing_vector()
	var attack_center: Vector2 = _player.global_position + direction * ATTACK_RANGE * 0.5
	
	# Find monsters in range
	var monsters := _player.get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		var dist: float = attack_center.distance_to(monster.global_position)
		if dist <= ATTACK_RANGE:
			hit_targets.append(monster)
	
	if not hit_targets.is_empty():
		EventBus.play_sfx.emit("sword_swing")
	
	return hit_targets


func _get_facing_vector() -> Vector2:
	if not _player or not _player.get("facing_direction"):
		return Vector2.DOWN
	match _player.facing_direction:
		Constants.Direction.UP: return Vector2.UP
		Constants.Direction.DOWN: return Vector2.DOWN
		Constants.Direction.LEFT: return Vector2.LEFT
		Constants.Direction.RIGHT: return Vector2.RIGHT
	return Vector2.DOWN


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> Dictionary:
	return {"current_hp": current_hp}

func load_data(data: Dictionary) -> void:
	current_hp = data.get("current_hp", MAX_HP)
