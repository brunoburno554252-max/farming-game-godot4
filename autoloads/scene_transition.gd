## autoloads/scene_transition.gd
## SceneTransitionManager — Gerencia transições entre locations com fade e loading.
## Lida com warp points, fade in/out, e tela de loading.
## Equivalente ao sistema de warps do Stardew Valley (Game1.warpFarmer).
##
## NOTA: Este script deve ser adicionado como Autoload APÓS o LocationManager.
## Adicione no project.godot: SceneTransition="*res://autoloads/scene_transition.gd"
extends CanvasLayer


# =============================================================================
# CONFIGURATION
# =============================================================================

const FADE_DURATION: float = 0.4  ## Duração do fade in/out em segundos
const MIN_LOADING_TIME: float = 0.3  ## Tempo mínimo na tela de loading


# =============================================================================
# STATE
# =============================================================================

var is_transitioning: bool = false

## ColorRect que cobre a tela toda para o fade
var _fade_rect: ColorRect

## Tween para animação de fade
var _tween: Tween


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	layer = 100  # Acima de tudo
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Criar o retângulo de fade que cobre toda a tela
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0, 0, 0, 0)  # Começa invisível
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)


# =============================================================================
# WARP / TRANSITION
# =============================================================================

## Realiza uma transição completa para outra location com fade.
## [param target_location] ID da location destino (ex: "town", "farm").
## [param spawn_position] Posição onde o jogador aparece (em pixels, não tiles).
## [param spawn_direction] Direção que o jogador olha ao chegar.
func warp_to(
	target_location: String,
	spawn_position: Vector2 = Vector2.ZERO,
	spawn_direction: Constants.Direction = Constants.Direction.DOWN
) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	var from_location := LocationManager.current_location_id
	
	EventBus.scene_transition_started.emit(from_location, target_location)
	
	# 1. Parar o tempo durante a transição
	TimeSystem.stop_time()
	
	# 2. Fade out (tela escurece)
	await _fade_out()
	
	# 3. Trocar a location
	await LocationManager.load_location(target_location)
	
	# 4. Posicionar o jogador (o PlayerController ouve location_ready)
	# Emitir dados de spawn para o player se posicionar
	_emit_spawn_data(spawn_position, spawn_direction)
	
	# 5. Esperar um frame para a location se estabilizar
	await get_tree().process_frame
	
	# 6. Fade in (tela clareia)
	await _fade_in()
	
	# 7. Retomar o tempo
	TimeSystem.start_time()
	
	is_transitioning = false
	
	EventBus.scene_transition_completed.emit(target_location)


## Transição especial para o início do dia (acordar).
## Fade mais lento, com possibilidade de mostrar resumo do dia anterior.
func day_start_transition() -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Tela já deve estar preta (fim do dia anterior)
	_fade_rect.color = Color(0, 0, 0, 1)
	
	# Esperar um momento (para dar tempo de processar o novo dia)
	await get_tree().create_timer(0.5).timeout
	
	# Fade in lento
	await _fade_in(0.8)
	
	is_transitioning = false


## Transição de fim de dia (dormir).
## Fade out lento para preto.
func day_end_transition() -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	
	await _fade_out(0.8)
	
	# A tela fica preta. O GameManager processa a transição de dia.
	# day_start_transition() será chamado quando o novo dia começar.
	
	is_transitioning = false


# =============================================================================
# FADE EFFECTS
# =============================================================================

## Fade out: tela vai para preto.
func _fade_out(duration: float = FADE_DURATION) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_fade_rect, "color:a", 1.0, duration)
	await _tween.finished


## Fade in: tela sai do preto.
func _fade_in(duration: float = FADE_DURATION) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_fade_rect, "color:a", 0.0, duration)
	await _tween.finished


## Flash branco (ex: para raios durante tempestade).
func flash_white(duration: float = 0.15) -> void:
	_kill_tween()
	_fade_rect.color = Color(1, 1, 1, 0.8)
	_tween = create_tween()
	_tween.tween_property(_fade_rect, "color:a", 0.0, duration)


## Fade para uma cor específica (útil para efeitos especiais).
func fade_to_color(color: Color, duration: float = FADE_DURATION) -> void:
	_kill_tween()
	_tween = create_tween()
	_fade_rect.color = Color(color.r, color.g, color.b, _fade_rect.color.a)
	_tween.tween_property(_fade_rect, "color:a", color.a, duration)
	await _tween.finished


func _kill_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()


# =============================================================================
# SPAWN DATA
# =============================================================================

## Signal temporário para passar dados de spawn ao PlayerController.
## O player ouve este sinal para se posicionar após um warp.
signal spawn_player(position: Vector2, direction: Constants.Direction)


func _emit_spawn_data(position: Vector2, direction: Constants.Direction) -> void:
	spawn_player.emit(position, direction)


# =============================================================================
# WARP POINT DATA
# =============================================================================

## Dados de um warp point definido no mapa.
## Cada location pode ter múltiplos warp points.
class WarpPoint:
	var from_tile: Vector2i          ## Tile onde o player pisa para warpar
	var target_location: String      ## ID da location destino
	var target_position: Vector2     ## Posição de spawn no destino (pixels)
	var target_direction: Constants.Direction = Constants.Direction.DOWN
	
	func _init(
		p_from_tile: Vector2i,
		p_target_location: String,
		p_target_position: Vector2,
		p_target_direction: Constants.Direction = Constants.Direction.DOWN
	) -> void:
		from_tile = p_from_tile
		target_location = p_target_location
		target_position = p_target_position
		target_direction = p_target_direction
