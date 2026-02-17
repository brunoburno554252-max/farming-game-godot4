## ui/components/mobile_action_buttons.gd
## MobileActionButtons — Botões de ação para dispositivos mobile.
## Posicionados na metade direita da tela.
## Botões: Usar Ferramenta (A), Interagir (B), Inventário, Pause.
class_name MobileActionButtons
extends Control


# =============================================================================
# EXPORTS
# =============================================================================

@export var button_size: float = 56.0
@export var button_color: Color = Color(1, 1, 1, 0.3)
@export var button_pressed_color: Color = Color(1, 1, 1, 0.6)
@export var mobile_only: bool = true


# =============================================================================
# BUTTONS
# =============================================================================

var _btn_tool: TouchScreenButton = null
var _btn_interact: TouchScreenButton = null
var _btn_inventory: TouchScreenButton = null
var _btn_pause: TouchScreenButton = null


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	if mobile_only and not _is_mobile():
		visible = false
		return
	
	_create_buttons()


func _create_buttons() -> void:
	var viewport_size := get_viewport_rect().size
	var margin := 20.0
	var right_x := viewport_size.x - margin
	var bottom_y := viewport_size.y - margin
	
	# Botão A (Usar ferramenta) — grande, canto inferior direito
	_btn_tool = _create_touch_button(
		"use_tool",
		Vector2(right_x - button_size, bottom_y - button_size * 2.2),
		button_size,
		"A"
	)
	
	# Botão B (Interagir) — à esquerda do A
	_btn_interact = _create_touch_button(
		"interact",
		Vector2(right_x - button_size * 2.5, bottom_y - button_size * 1.2),
		button_size * 0.85,
		"B"
	)
	
	# Botão Inventário — menor, canto superior direito
	_btn_inventory = _create_touch_button(
		"open_inventory",
		Vector2(right_x - button_size * 0.7, margin),
		button_size * 0.6,
		"INV"
	)
	
	# Botão Pause — ao lado do inventário
	_btn_pause = _create_touch_button(
		"pause_menu",
		Vector2(right_x - button_size * 1.6, margin),
		button_size * 0.6,
		"II"
	)


func _create_touch_button(
	action_name: String,
	pos: Vector2,
	size: float,
	label: String
) -> TouchScreenButton:
	var btn := TouchScreenButton.new()
	btn.action = action_name
	btn.position = pos
	btn.shape = CircleShape2D.new()
	(btn.shape as CircleShape2D).radius = size / 2
	btn.shape_centered = true
	btn.shape_visible = true
	add_child(btn)
	
	# Adicionar label visual
	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-size / 2, -size / 2)
	lbl.size = Vector2(size, size)
	btn.add_child(lbl)
	
	return btn


# =============================================================================
# HELPERS
# =============================================================================

func _is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
