## ui/components/virtual_joystick.gd
## VirtualJoystick — Joystick virtual para controle em dispositivos mobile.
## Aparece onde o jogador toca na metade esquerda da tela.
## Retorna input normalizado usado pelo PlayerController.
##
## SETUP: Adicionar como filho do HUD. Configurar a área de toque.
class_name VirtualJoystick
extends Control


# =============================================================================
# EXPORTS
# =============================================================================

## Raio máximo do joystick (em pixels)
@export var joystick_radius: float = 64.0

## Dead zone (input menor que isso é ignorado)
@export var dead_zone: float = 0.15

## Cor do anel externo
@export var outer_color: Color = Color(1, 1, 1, 0.2)

## Cor do botão interno
@export var inner_color: Color = Color(1, 1, 1, 0.5)

## Raio do botão interno
@export var inner_radius: float = 24.0

## Se o joystick aparece fixo ou segue o toque
@export var is_dynamic: bool = true

## Se deve mostrar o joystick só em mobile
@export var mobile_only: bool = true


# =============================================================================
# STATE
# =============================================================================

## Direção atual normalizada (-1 a 1 em cada eixo)
var output: Vector2 = Vector2.ZERO

## Se o joystick está sendo tocado
var is_pressed: bool = false

## Posição central do joystick (onde o toque começou)
var _center: Vector2 = Vector2.ZERO

## Posição atual do "knob" (botão interno)
var _knob_position: Vector2 = Vector2.ZERO

## ID do toque atual (para multitouch)
var _touch_index: int = -1

## Referência ao player
var _player: PlayerController = null


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Em desktop, esconder se mobile_only
	if mobile_only and not _is_mobile():
		visible = false
		set_process_input(false)
		return
	
	# Ocupar metade esquerda da tela
	set_anchors_preset(Control.PRESET_LEFT_WIDE)
	size.x = get_viewport_rect().size.x * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	if is_pressed:
		_update_player_input()
	elif output != Vector2.ZERO:
		output = Vector2.ZERO
		_update_player_input()
	queue_redraw()


# =============================================================================
# INPUT HANDLING
# =============================================================================

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Só aceitar toques na metade esquerda da tela
		if event.position.x > get_viewport_rect().size.x * 0.5:
			return
		
		_touch_index = event.index
		is_pressed = true
		_center = event.position
		_knob_position = event.position
		_calculate_output()
	else:
		if event.index == _touch_index:
			_release()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _touch_index and is_pressed:
		_knob_position = event.position
		_calculate_output()


func _release() -> void:
	is_pressed = false
	_touch_index = -1
	output = Vector2.ZERO
	_update_player_input()


func _calculate_output() -> void:
	var delta := _knob_position - _center
	var distance := delta.length()
	
	if distance < dead_zone * joystick_radius:
		output = Vector2.ZERO
		return
	
	# Clampar no raio máximo
	if distance > joystick_radius:
		delta = delta.normalized() * joystick_radius
		_knob_position = _center + delta
	
	output = delta / joystick_radius


func _update_player_input() -> void:
	if not _player:
		# Buscar player na árvore
		_player = get_tree().get_first_node_in_group("player") as PlayerController
	
	if _player:
		_player.input_direction = output


# =============================================================================
# DRAWING
# =============================================================================

func _draw() -> void:
	if not is_pressed:
		return
	
	# Converter posições globais para locais
	var local_center := _center - global_position
	var local_knob := _knob_position - global_position
	
	# Desenhar anel externo
	draw_arc(local_center, joystick_radius, 0, TAU, 64, outer_color, 2.0)
	
	# Desenhar botão interno
	draw_circle(local_knob, inner_radius, inner_color)


# =============================================================================
# HELPERS
# =============================================================================

func _is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
