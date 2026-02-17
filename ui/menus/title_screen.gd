## ui/menus/title_screen.gd
## TitleScreen — Tela de título do jogo com New Game, Load, Quit.
extends Control


var _name_input: LineEdit
var _farm_input: LineEdit
var _new_game_panel: Panel
var _save_buttons: Array[Button] = []


func _ready() -> void:
	name = "TitleScreen"
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	_build_ui()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.1, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# Container central
	var center := VBoxContainer.new()
	center.set_anchors_preset(PRESET_CENTER)
	center.position = Vector2(-160, -180)
	center.custom_minimum_size = Vector2(320, 360)
	center.add_theme_constant_override("separation", 12)
	add_child(center)
	
	# Título do jogo
	var title := Label.new()
	title.text = "🌾 Farming Game"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	center.add_child(title)
	
	# Subtítulo
	var subtitle := Label.new()
	subtitle.text = "Uma aventura no campo"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.5))
	center.add_child(subtitle)
	
	# Espaçador
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	center.add_child(spacer)
	
	# Botão Novo Jogo
	var btn_new := _make_button("Novo Jogo")
	btn_new.pressed.connect(_show_new_game_form)
	center.add_child(btn_new)
	
	# Botão Carregar
	var btn_load := _make_button("Carregar Jogo")
	btn_load.pressed.connect(_show_load_menu)
	center.add_child(btn_load)
	
	# Botão Sair
	var btn_quit := _make_button("Sair")
	btn_quit.pressed.connect(func(): get_tree().quit())
	center.add_child(btn_quit)
	
	# === Painel de Novo Jogo (inicialmente oculto) ===
	_new_game_panel = Panel.new()
	_new_game_panel.visible = false
	_new_game_panel.set_anchors_preset(PRESET_CENTER)
	_new_game_panel.position = Vector2(-160, -120)
	_new_game_panel.size = Vector2(320, 240)
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.4, 0.35, 0.5, 0.7)
	_new_game_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_new_game_panel)
	
	var form_vbox := VBoxContainer.new()
	form_vbox.set_anchors_preset(PRESET_FULL_RECT)
	form_vbox.offset_left = 20
	form_vbox.offset_right = -20
	form_vbox.offset_top = 15
	form_vbox.offset_bottom = -15
	form_vbox.add_theme_constant_override("separation", 8)
	_new_game_panel.add_child(form_vbox)
	
	var form_title := Label.new()
	form_title.text = "Novo Jogo"
	form_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	form_title.add_theme_font_size_override("font_size", 18)
	form_title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	form_vbox.add_child(form_title)
	
	var name_label := Label.new()
	name_label.text = "Seu nome:"
	name_label.add_theme_font_size_override("font_size", 13)
	form_vbox.add_child(name_label)
	
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Fazendeiro"
	_name_input.max_length = 20
	form_vbox.add_child(_name_input)
	
	var farm_label := Label.new()
	farm_label.text = "Nome da fazenda:"
	farm_label.add_theme_font_size_override("font_size", 13)
	form_vbox.add_child(farm_label)
	
	_farm_input = LineEdit.new()
	_farm_input.placeholder_text = "Minha Fazenda"
	_farm_input.max_length = 24
	form_vbox.add_child(_farm_input)
	
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	form_vbox.add_child(btn_row)
	
	var btn_start := _make_button("Começar!", 130, 36)
	btn_start.pressed.connect(_start_new_game)
	btn_row.add_child(btn_start)
	
	var btn_cancel := _make_button("Voltar", 100, 36)
	btn_cancel.pressed.connect(func(): _new_game_panel.visible = false)
	btn_row.add_child(btn_cancel)


func _make_button(text: String, w: int = 220, h: int = 44) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(w, h)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.15, 0.25, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.25, 0.4, 0.6)
	btn.add_theme_stylebox_override("normal", style)
	
	var hover := style.duplicate()
	hover.bg_color = Color(0.28, 0.22, 0.4, 0.95)
	hover.border_color = Color(0.6, 0.5, 0.8, 0.8)
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
	
	return btn


func _show_new_game_form() -> void:
	_new_game_panel.visible = true
	_name_input.text = ""
	_farm_input.text = ""
	_name_input.grab_focus()


func _start_new_game() -> void:
	var p_name: String = _name_input.text.strip_edges()
	if p_name.is_empty():
		p_name = "Fazendeiro"
	var f_name: String = _farm_input.text.strip_edges()
	if f_name.is_empty():
		f_name = "Minha Fazenda"
	
	_new_game_panel.visible = false
	GameManager.start_new_game(p_name, f_name, 1)


func _show_load_menu() -> void:
	# Verificar slots disponíveis
	var has_save := false
	for slot in [1, 2, 3]:
		if DatabaseManager.save_exists(slot):
			has_save = true
			break
	
	if not has_save:
		# Nenhum save encontrado
		EventBus.show_notification.emit("Nenhum jogo salvo encontrado.", null)
		return
	
	# Carregar do slot 1 (simplificado por agora)
	for slot in [1, 2, 3]:
		if DatabaseManager.save_exists(slot):
			GameManager.load_game(slot)
			return
