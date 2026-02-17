## ui/menus/day_end_summary.gd
## DayEndSummary — Tela de resumo do fim do dia.
## Mostra itens vendidos na caixa de shipping, total de ganhos, e avanço de skills.
## Equivalente ao ShippingMenu do Stardew Valley.
extends Control


# =============================================================================
# STATE
# =============================================================================

var _shipped_items: Array[Dictionary] = []  ## [{item_id, quantity, price}]
var _total_earnings: int = 0

var _bg_panel: Panel
var _title_label: Label
var _items_container: VBoxContainer
var _total_label: Label
var _continue_button: Button


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	name = "DayEndSummary"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_build_ui()


func _build_ui() -> void:
	# Fundo escuro
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.05, 0.95)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Painel central
	_bg_panel = Panel.new()
	var pw: int = 360
	var ph: int = 400
	_bg_panel.set_anchors_preset(PRESET_CENTER)
	_bg_panel.position = Vector2(-pw / 2.0, -ph / 2.0)
	_bg_panel.size = Vector2(pw, ph)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.35, 0.3, 0.5, 0.7)
	_bg_panel.add_theme_stylebox_override("panel", style)
	add_child(_bg_panel)
	
	# Título
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_title_label.position = Vector2(0, 15)
	_title_label.size.x = pw
	_bg_panel.add_child(_title_label)
	
	# Lista de itens shipped
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 50)
	scroll.size = Vector2(pw - 40, 260)
	_bg_panel.add_child(scroll)
	
	_items_container = VBoxContainer.new()
	_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_container.add_theme_constant_override("separation", 4)
	scroll.add_child(_items_container)
	
	# Total
	_total_label = Label.new()
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total_label.add_theme_font_size_override("font_size", 18)
	_total_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_total_label.position = Vector2(0, 320)
	_total_label.size.x = pw
	_bg_panel.add_child(_total_label)
	
	# Botão continuar
	_continue_button = Button.new()
	_continue_button.text = "Continuar"
	_continue_button.custom_minimum_size = Vector2(120, 36)
	_continue_button.position = Vector2(pw / 2.0 - 60, 355)
	_continue_button.pressed.connect(_on_continue)
	_bg_panel.add_child(_continue_button)


# =============================================================================
# SHOW SUMMARY
# =============================================================================

## Mostra o resumo do dia.
## [param items] Array de dicts: [{item_id, quantity, price}]
func show_summary(items: Array[Dictionary]) -> void:
	_shipped_items = items
	_total_earnings = 0
	
	# Limpar lista
	for child in _items_container.get_children():
		child.queue_free()
	
	_title_label.text = "Resumo do Dia %d" % TimeSystem.current_day
	
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhum item enviado hoje."
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_items_container.add_child(empty_label)
	else:
		for item_dict in items:
			var item_data := ItemDatabase.get_item(item_dict.item_id)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			
			var name_label := Label.new()
			name_label.text = item_data.display_name if item_data else item_dict.item_id
			name_label.add_theme_font_size_override("font_size", 13)
			name_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_label)
			
			var qty_label := Label.new()
			qty_label.text = "x%d" % item_dict.quantity
			qty_label.add_theme_font_size_override("font_size", 12)
			qty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
			row.add_child(qty_label)
			
			var price_label := Label.new()
			var line_total: int = item_dict.price * item_dict.quantity
			price_label.text = "%dG" % line_total
			price_label.add_theme_font_size_override("font_size", 13)
			price_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			price_label.custom_minimum_size.x = 60
			price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(price_label)
			
			_items_container.add_child(row)
			_total_earnings += line_total
	
	_total_label.text = "Total: %dG" % _total_earnings
	
	visible = true


func _on_continue() -> void:
	# Adicionar ganhos ao gold do jogador
	if _total_earnings > 0:
		InventorySystem.earn_gold(_total_earnings)
	
	visible = false
	EventBus.play_sfx.emit("ui_click")
	
	# Sinalizar que o resumo foi fechado (GameManager pode ouvir)
	EventBus.day_ended.emit()
