## player/states/player_idle_state.gd
## PlayerIdleState — Estado padrão quando o jogador está parado.
## Transições: → Walk (input de movimento), → UseTool (use_tool), → Interact (interact)
class_name PlayerIdleState
extends State


var _player: PlayerController


func _enter(_args: Dictionary) -> void:
	_player = owner as PlayerController
	if _player:
		_player.can_move = true
		_player.can_interact = true
		_player.velocity = Vector2.ZERO
		_player.play_animation("idle_%s" % _player.get_direction_suffix())


func _update(delta: float) -> void:
	if not _player:
		return
	
	var move_dir := _player.get_movement_input()
	if move_dir != Vector2.ZERO:
		transition_to("Walk")
		return


func _handle_input(event: InputEvent) -> void:
	if not _player or not _player.can_interact:
		return
	
	if event.is_action_pressed("use_tool"):
		transition_to("UseTool")
	
	elif event.is_action_pressed("interact"):
		transition_to("Interact")
