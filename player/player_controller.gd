## player/player_controller.gd
## PlayerController — Personagem principal do jogador.
## CharacterBody2D com StateMachine para gerenciar estados (Idle, Walk, UseTool, etc.)
## Integra com ToolSystem para uso de ferramentas e interações.
class_name PlayerController
extends CharacterBody2D


# =============================================================================
# EXPORTS
# =============================================================================

@export var move_speed: float = Constants.DEFAULT_MOVE_SPEED


# =============================================================================
# COMPONENTS
# =============================================================================

## Máquina de estados (adicionada como filho)
var state_machine: StateMachine = null

## Sistema de ferramentas
var tool_system: ToolSystem = null

## Sprite animado
var _animated_sprite: AnimatedSprite2D = null

## Collision shape
var _collision: CollisionShape2D = null

## Interaction raycast (detecta o que está à frente)
var _interaction_ray: RayCast2D = null


# =============================================================================
# STATE
# =============================================================================

## Direção que o jogador está olhando
var facing_direction: Constants.Direction = Constants.Direction.DOWN

## Tile atual do jogador
var current_tile: Vector2i = Vector2i.ZERO

## Se o jogador pode se mover (false durante tool use, diálogo, etc.)
var can_move: bool = true

## Se o jogador pode interagir
var can_interact: bool = true

## Input direction (atualizado por _process_input ou joystick virtual)
var input_direction: Vector2 = Vector2.ZERO


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Criar collision shape
	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 8)
	_collision.shape = shape
	_collision.position = Vector2(0, 4)  # Offset para pés do personagem
	add_child(_collision)
	
	# Criar AnimatedSprite2D
	_animated_sprite = AnimatedSprite2D.new()
	_animated_sprite.name = "AnimatedSprite"
	add_child(_animated_sprite)
	
	# Criar interaction raycast
	_interaction_ray = RayCast2D.new()
	_interaction_ray.name = "InteractionRay"
	_interaction_ray.target_position = Vector2(0, Constants.TILE_SIZE)
	_interaction_ray.enabled = true
	add_child(_interaction_ray)
	
	# Criar StateMachine
	state_machine = StateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)
	
	# Adicionar estados
	var idle_state := PlayerIdleState.new()
	idle_state.name = "Idle"
	state_machine.add_child(idle_state)
	
	var walk_state := PlayerWalkState.new()
	walk_state.name = "Walk"
	state_machine.add_child(walk_state)
	
	var tool_state := PlayerToolState.new()
	tool_state.name = "UseTool"
	state_machine.add_child(tool_state)
	
	var interact_state := PlayerInteractState.new()
	interact_state.name = "Interact"
	state_machine.add_child(interact_state)
	
	# Inicializar ferramenta system
	tool_system = ToolSystem.new()
	tool_system.initialize(Constants.DEFAULT_MAX_ENERGY, Constants.DEFAULT_MAX_ENERGY)
	
	# Conectar sinais
	SceneTransition.spawn_player.connect(_on_spawn)
	EventBus.player_passed_out.connect(_on_passed_out)
	
	# State machine começa em Idle
	state_machine.initialize("Idle")


func _process(delta: float) -> void:
	_update_current_tile()
	_check_warp()


func _unhandled_input(event: InputEvent) -> void:
	# Scroll da hotbar com mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			InventorySystem.hotbar_prev()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			InventorySystem.hotbar_next()
	
	# Teclas numéricas para hotbar (1-9, 0)
	if event is InputEventKey and event.pressed:
		var key := event.keycode
		if key >= KEY_1 and key <= KEY_9:
			InventorySystem.select_hotbar(key - KEY_1)
		elif key == KEY_0:
			InventorySystem.select_hotbar(9)


# =============================================================================
# MOVEMENT
# =============================================================================

## Lê input de movimento (WASD ou joystick virtual).
func get_movement_input() -> Vector2:
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	
	# Se houver input do joystick virtual, priorizar
	if input_direction != Vector2.ZERO:
		dir = input_direction
	
	return dir.normalized() if dir.length() > 0.1 else Vector2.ZERO


## Atualiza a direção que o jogador está olhando baseado no input.
func update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	
	var old_dir := facing_direction
	
	# Determinar a direção predominante
	if abs(direction.x) > abs(direction.y):
		facing_direction = Constants.Direction.RIGHT if direction.x > 0 else Constants.Direction.LEFT
	else:
		facing_direction = Constants.Direction.DOWN if direction.y > 0 else Constants.Direction.UP
	
	if facing_direction != old_dir:
		_update_raycast_direction()
		EventBus.player_direction_changed.emit(facing_direction)


## Atualiza a direção do raycast de interação.
func _update_raycast_direction() -> void:
	var dir_vec: Vector2 = Constants.DIRECTION_VECTORS[facing_direction]
	_interaction_ray.target_position = dir_vec * Constants.TILE_SIZE


# =============================================================================
# TILE TRACKING & WARPS
# =============================================================================

func _update_current_tile() -> void:
	var new_tile := Vector2i(
		int(position.x) / Constants.TILE_SIZE,
		int(position.y) / Constants.TILE_SIZE
	)
	if new_tile != current_tile:
		current_tile = new_tile
		EventBus.player_tile_changed.emit(current_tile)


## Verifica se o jogador está em cima de um warp point.
func _check_warp() -> void:
	if SceneTransition.is_transitioning:
		return
	
	var warp_data := LocationManager.check_warp(
		LocationManager.current_location_id, current_tile
	)
	
	if not warp_data.is_empty():
		SceneTransition.warp_to(
			warp_data.target_location,
			warp_data.target_position,
			warp_data.target_direction
		)


# =============================================================================
# INTERACTION
# =============================================================================

## Retorna o tile à frente do jogador.
func get_facing_tile() -> Vector2i:
	var dir_vec: Vector2 = Constants.DIRECTION_VECTORS[facing_direction]
	return current_tile + Vector2i(int(dir_vec.x), int(dir_vec.y))


## Retorna o node com o qual o raycast está colidindo (se houver).
func get_interaction_target() -> Node:
	if _interaction_ray.is_colliding():
		return _interaction_ray.get_collider()
	return null


# =============================================================================
# ANIMATION
# =============================================================================

## Toca uma animação. Convenção: "idle_down", "walk_up", "tool_right", etc.
func play_animation(anim_name: String) -> void:
	if _animated_sprite and _animated_sprite.sprite_frames:
		if _animated_sprite.sprite_frames.has_animation(anim_name):
			_animated_sprite.play(anim_name)


## Retorna o sufixo de direção para animações.
func get_direction_suffix() -> String:
	match facing_direction:
		Constants.Direction.DOWN: return "down"
		Constants.Direction.UP: return "up"
		Constants.Direction.LEFT: return "left"
		Constants.Direction.RIGHT: return "right"
	return "down"


# =============================================================================
# SPAWN
# =============================================================================

func _on_spawn(spawn_pos: Vector2, direction: Constants.Direction) -> void:
	position = spawn_pos
	facing_direction = direction
	_update_raycast_direction()
	_update_current_tile()


func _on_passed_out(reason: String) -> void:
	can_move = false
	can_interact = false
	state_machine.transition_to("Idle")
	# GameManager vai processar a transição de dia


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	tool_system.save_data()
	DatabaseManager.query(
		"UPDATE player SET pos_x=%.1f, pos_y=%.1f, facing=%d, current_location='%s' WHERE id=1;" % [
			position.x, position.y, int(facing_direction),
			LocationManager.current_location_id
		]
	)


func load_data() -> void:
	tool_system.load_data()
	var data := DatabaseManager.query("SELECT * FROM player WHERE id=1;")
	if data.size() > 0:
		position.x = data[0].get("pos_x", 0.0)
		position.y = data[0].get("pos_y", 0.0)
		facing_direction = data[0].get("facing", 0) as Constants.Direction
		_update_raycast_direction()
