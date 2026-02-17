## ui/menus/elevator_menu.gd
## ElevatorMenu — Seleção de andares da mina via elevador.
## Mostra apenas andares desbloqueados (múltiplos de 5).
extends Control


var _buttons: Array[Button] = []
var _bg_panel: Panel


func _ready() -> void:
	name = "ElevatorMenu"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.set_anchors_preset(PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	_bg_panel = Panel.new()
	_bg_panel.set_anchors_preset(PRESET_CENTER)
	_bg_panel.position = Vector2(-150, -200)
	_bg_panel.size = Vector2(300, 400)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.3, 0.3, 0.45, 0.7)
	_bg_panel.add_theme_stylebox_override("panel", style)
	add_child(_bg_panel)
	
	var title := Label.new()
	title.text = "Elevador da Mina"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	title.position = Vector2(0, 12)
	title.size.x = 300
	_bg_panel.add_child(title)


func open() -> void:
	_refresh_floors()
	UIManager.open_menu(self)


func close() -> void:
	UIManager.close_top_menu()


func _refresh_floors() -> void:
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()
	
	var floors := MineSystem.get_unlocked_elevator_floors()
	
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 48)
	scroll.size = Vector2(260, 320)
	_bg_panel.add_child(scroll)
	
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	
	for floor_num in floors:
		var btn := Button.new()
		btn.text = str(floor_num) if floor_num > 0 else "Entrada"
		btn.custom_minimum_size = Vector2(55, 36)
		btn.add_theme_font_size_override("font_size", 12)
		
		var is_current := floor_num == MineSystem.current_floor
		if is_current:
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		
		btn.pressed.connect(_on_floor_selected.bind(floor_num))
		grid.add_child(btn)
		_buttons.append(btn)


func _on_floor_selected(floor_num: int) -> void:
	close()
	MineSystem.generate_floor(floor_num)
	EventBus.play_sfx.emit("elevator")
	EventBus.show_notification.emit("Andar %d" % floor_num if floor_num > 0 else "Entrada da Mina", null)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		close()
		get_viewport().set_input_as_handled()
