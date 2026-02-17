## player/states/player_walk_state.gd
## PlayerWalkState — Estado de caminhada do jogador.
## Move o CharacterBody2D e atualiza animação de direção.
## Transições: → Idle (sem input), → UseTool (use_tool), → Interact (interact)
class_name PlayerWalkState
extends State


var _player: PlayerController


func _enter(_args: Dictionary) -> void:
	_player = owner as PlayerController


func _physics_update(delta: float) -> void:
	if not _player or not _player.can_move:
		transition_to("Idle")
		return
	
	var move_dir := _player.get_movement_input()
	
	if move_dir == Vector2.ZERO:
		transition_to("Idle")
		return
	
	# Atualizar direção
	_player.update_facing(move_dir)
	
	# Mover
	_player.velocity = move_dir * _player.move_speed
	_player.move_and_slide()
	
	# Animação
	_player.play_animation("walk_%s" % _player.get_direction_suffix())


func _handle_input(event: InputEvent) -> void:
	if not _player or not _player.can_interact:
		return
	
	if event.is_action_pressed("use_tool"):
		transition_to("UseTool")
	
	elif event.is_action_pressed("interact"):
		transition_to("Interact")
