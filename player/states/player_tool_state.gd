## player/states/player_tool_state.gd
## PlayerToolState — Estado de uso de ferramenta.
## Para o jogador, executa animação e efeito no tile à frente.
## Retorna para Idle ao terminar.
class_name PlayerToolState
extends State


var _player: PlayerController
var _tool_timer: float = 0.0
var _tool_duration: float = 0.4  ## Duração da animação de uso


func _enter(_args: Dictionary) -> void:
	_player = owner as PlayerController
	if not _player:
		transition_to("Idle")
		return
	
	_player.can_move = false
	_player.velocity = Vector2.ZERO
	_tool_timer = 0.0
	
	# Usar a ferramenta no tile à frente
	var facing_tile := _player.get_facing_tile()
	var result := _player.tool_system.use_tool_at(facing_tile, _player.facing_direction)
	
	if result.success:
		_player.play_animation("tool_%s" % _player.get_direction_suffix())
		_tool_duration = 0.4
	else:
		# Ferramenta não teve efeito — voltar rápido para Idle
		_tool_duration = 0.15
		_player.play_animation("idle_%s" % _player.get_direction_suffix())


func _update(delta: float) -> void:
	_tool_timer += delta
	if _tool_timer >= _tool_duration:
		_player.can_move = true
		transition_to("Idle")
