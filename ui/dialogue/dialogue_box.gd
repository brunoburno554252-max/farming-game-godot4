## ui/dialogue/dialogue_box.gd
## DialogueBox — Caixa de diálogo com nome do falante, texto paginado e choices.
## Equivalente ao DialogueBox do Stardew Valley.
## Conecta-se ao DialogueManager para exibir o diálogo atual.
extends Control


# =============================================================================
# CONSTANTS
# =============================================================================

const BOX_HEIGHT: int = 120
const BOX_MARGIN: int = 20
const TEXT_SPEED: float = 30.0  ## Caracteres por segundo
const CHARS_PER_TICK: float = 1.0


# =============================================================================
# STATE
# =============================================================================

var _is_typing: bool = false
var _full_text: String = ""
var _visible_chars: float = 0.0
var _choices_active: bool = false
var _selected_choice: int = 0

var _bg_panel: Panel
var _speaker_label: Label
var _text_label: RichTextLabel
var _continue_indicator: Label

var _choices_container: VBoxContainer
var _choice_buttons: Array[Button] = []


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	name = "DialogueBox"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_build_ui()
	
	# Conectar ao DialogueManager
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)


func _build_ui() -> void:
	# Touch blocker (captura toque na área fora da caixa para avançar)
	var touch_area := ColorRect.new()
	touch_area.color = Color(0, 0, 0, 0)
	touch_area.set_anchors_preset(PRESET_FULL_RECT)
	touch_area.mouse_filter = Control.MOUSE_FILTER_STOP
	touch_area.gui_input.connect(_on_touch_area_input)
	add_child(touch_area)
	
	# Painel da caixa de diálogo
	_bg_panel = Panel.new()
	_bg_panel.anchor_left = 0.0
	_bg_panel.anchor_right = 1.0
	_bg_panel.anchor_bottom = 1.0
	_bg_panel.anchor_top = 1.0
	_bg_panel.offset_left = BOX_MARGIN
	_bg_panel.offset_right = -BOX_MARGIN
	_bg_panel.offset_top = -(BOX_HEIGHT + BOX_MARGIN)
	_bg_panel.offset_bottom = -BOX_MARGIN
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.45, 0.35, 0.55, 0.8)
	_bg_panel.add_theme_stylebox_override("panel", style)
	add_child(_bg_panel)
	
	# Nome do falante
	_speaker_label = Label.new()
	_speaker_label.position = Vector2(16, -24)
	_speaker_label.add_theme_font_size_override("font_size", 14)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_speaker_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_speaker_label.add_theme_constant_override("shadow_offset_x", 1)
	_speaker_label.add_theme_constant_override("shadow_offset_y", 1)
	_bg_panel.add_child(_speaker_label)
	
	# Texto do diálogo
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.set_anchors_preset(PRESET_FULL_RECT)
	_text_label.offset_left = 16
	_text_label.offset_right = -16
	_text_label.offset_top = 12
	_text_label.offset_bottom = -12
	_text_label.add_theme_font_size_override("normal_font_size", 14)
	_text_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.92))
	_bg_panel.add_child(_text_label)
	
	# Indicador de "continuar" (seta/triângulo)
	_continue_indicator = Label.new()
	_continue_indicator.text = "▼"
	_continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_indicator.anchor_right = 1.0
	_continue_indicator.anchor_bottom = 1.0
	_continue_indicator.offset_right = -12
	_continue_indicator.offset_bottom = -8
	_continue_indicator.offset_left = -30
	_continue_indicator.offset_top = -20
	_continue_indicator.add_theme_font_size_override("font_size", 14)
	_continue_indicator.add_theme_color_override("font_color", Color(0.7, 0.65, 0.8, 0.8))
	_continue_indicator.visible = false
	_bg_panel.add_child(_continue_indicator)
	
	# Container de choices (aparece acima da caixa de diálogo)
	_choices_container = VBoxContainer.new()
	_choices_container.anchor_left = 0.5
	_choices_container.anchor_right = 0.5
	_choices_container.anchor_bottom = 1.0
	_choices_container.anchor_top = 1.0
	_choices_container.offset_top = -(BOX_HEIGHT + BOX_MARGIN + 10)
	_choices_container.offset_bottom = -(BOX_HEIGHT + BOX_MARGIN + 10)
	_choices_container.grow_horizontal = GROW_DIRECTION_BOTH
	_choices_container.add_theme_constant_override("separation", 6)
	_choices_container.visible = false
	add_child(_choices_container)


# =============================================================================
# DIALOGUE FLOW
# =============================================================================

func _on_dialogue_started(speaker_name: String) -> void:
	visible = true
	_speaker_label.text = speaker_name
	_show_current_line()


func _on_dialogue_ended() -> void:
	visible = false
	_choices_container.visible = false
	_is_typing = false


func _show_current_line() -> void:
	var line_data := DialogueManager.get_current_line()
	if line_data.is_empty():
		return
	
	_full_text = line_data.get("text", "")
	_text_label.text = ""
	_visible_chars = 0.0
	_is_typing = true
	_continue_indicator.visible = false
	_choices_container.visible = false
	_choices_active = false
	
	# Atualizar nome do falante se presente na linha
	if line_data.has("speaker"):
		_speaker_label.text = line_data.speaker


func _process(delta: float) -> void:
	if not _is_typing:
		# Piscar o indicador de continuar
		if _continue_indicator.visible:
			_continue_indicator.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
		return
	
	_visible_chars += TEXT_SPEED * delta
	var chars_to_show := int(_visible_chars)
	
	if chars_to_show >= _full_text.length():
		_text_label.text = _full_text
		_is_typing = false
		_on_typing_finished()
	else:
		_text_label.text = _full_text.left(chars_to_show)


func _on_typing_finished() -> void:
	# Verificar se há choices para mostrar
	var line_data := DialogueManager.get_current_line()
	if line_data.has("choices") and not line_data.choices.is_empty():
		_show_choices(line_data.choices)
	else:
		_continue_indicator.visible = true


func _advance() -> void:
	if _choices_active:
		return  # Esperando seleção de choice
	
	if _is_typing:
		# Skip: mostrar texto completo
		_text_label.text = _full_text
		_is_typing = false
		_on_typing_finished()
		return
	
	# Avançar para a próxima linha
	DialogueManager.advance_dialogue()
	if DialogueManager.is_dialogue_active:
		_show_current_line()


# =============================================================================
# CHOICES
# =============================================================================

func _show_choices(choices: Array) -> void:
	_choices_active = true
	_continue_indicator.visible = false
	
	# Limpar choices anteriores
	for child in _choices_container.get_children():
		child.queue_free()
	_choice_buttons.clear()
	
	_choices_container.visible = true
	
	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.custom_minimum_size = Vector2(250, 36)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.12, 0.22, 0.95)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.35, 0.5, 0.6)
		btn.add_theme_stylebox_override("normal", style)
		
		var hover_style := style.duplicate()
		hover_style.bg_color = Color(0.25, 0.2, 0.35, 0.95)
		hover_style.border_color = Color(0.7, 0.5, 0.9, 0.8)
		btn.add_theme_stylebox_override("hover", hover_style)
		
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
		
		btn.pressed.connect(_on_choice_selected.bind(i))
		_choices_container.add_child(btn)
		_choice_buttons.append(btn)
	
	_selected_choice = 0


func _on_choice_selected(index: int) -> void:
	_choices_active = false
	_choices_container.visible = false
	DialogueManager.select_choice(index)
	EventBus.play_sfx.emit("ui_click")
	
	if DialogueManager.is_dialogue_active:
		_show_current_line()


# =============================================================================
# INPUT
# =============================================================================

func _on_touch_area_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()
	
	# Navegação de choices com teclado
	if _choices_active:
		if event.is_action_pressed("ui_up"):
			_selected_choice = maxi(0, _selected_choice - 1)
			_choice_buttons[_selected_choice].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_selected_choice = mini(_choice_buttons.size() - 1, _selected_choice + 1)
			_choice_buttons[_selected_choice].grab_focus()
			get_viewport().set_input_as_handled()
