## ui/menus/pause_menu.gd
## PauseMenu — Menu de pausa com opções de salvar, carregar, configurações e sair.
extends Control


# =============================================================================
# STATE
# =============================================================================

var _buttons: Array[Button] = []
var _bg_panel: Panel


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	name = "PauseMenu"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	
	_build_ui()


func _build_ui() -> void:
	# Fundo dimmer
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.set_anchors_preset(PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	# Painel central
	_bg_panel = Panel.new()
	_bg_panel.custom_minimum_size = Vector2(280, 320)
	_bg_panel.set_anchors_preset(PRESET_CENTER)
	_bg_panel.position = Vector2(-140, -160)
	_bg_panel.size = Vector2(280, 320)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.4, 0.35, 0.5, 0.7)
	_bg_panel.add_theme_stylebox_override("panel", style)
	add_child(_bg_panel)
	
	# Título
	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	title.position = Vector2(0, 15)
	title.size.x = 280
	_bg_panel.add_child(title)
	
	# Botões
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_CENTER)
	vbox.position = Vector2(50, 60)
	vbox.custom_minimum_size.x = 180
	vbox.add_theme_constant_override("separation", 10)
	_bg_panel.add_child(vbox)
	
	_add_button(vbox, "Continuar", _on_continue)
	_add_button(vbox, "Inventário", _on_inventory)
	_add_button(vbox, "Salvar", _on_save)
	_add_button(vbox, "Configurações", _on_settings)
	_add_button(vbox, "Sair ao Menu", _on_quit)


func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 40)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.18, 0.28, 0.9)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.border_width_bottom = 2
	normal.border_color = Color(0.35, 0.3, 0.45, 0.6)
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover := normal.duplicate()
	hover.bg_color = Color(0.3, 0.25, 0.4, 0.95)
	hover.border_color = Color(0.6, 0.5, 0.8, 0.8)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.15, 0.12, 0.2, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
	
	btn.pressed.connect(callback)
	parent.add_child(btn)
	_buttons.append(btn)


# =============================================================================
# CALLBACKS
# =============================================================================

func _on_continue() -> void:
	close()
	EventBus.play_sfx.emit("ui_click")


func _on_inventory() -> void:
	close()
	# Procurar o InventoryMenu no UIManager
	var inv_menu := get_tree().get_first_node_in_group("inventory_menu")
	if inv_menu and inv_menu.has_method("open"):
		inv_menu.open()
	EventBus.play_sfx.emit("ui_click")


func _on_save() -> void:
	GameManager.save_game()
	EventBus.show_notification.emit("Jogo salvo!", null)
	EventBus.play_sfx.emit("ui_click")


func _on_settings() -> void:
	# Será implementado futuramente
	EventBus.show_notification.emit("Em breve...", null)
	EventBus.play_sfx.emit("ui_click")


func _on_quit() -> void:
	close()
	GameManager.quit_to_menu()
	EventBus.play_sfx.emit("ui_click")


# =============================================================================
# OPEN / CLOSE
# =============================================================================

func open() -> void:
	UIManager.open_menu(self)


func close() -> void:
	UIManager.close_top_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
