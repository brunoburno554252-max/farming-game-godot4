## ui/hud/hud.gd
## HUD — Interface principal do jogo (hotbar, energia, relógio, gold).
## Sempre visível durante gameplay. Esconde durante menus/diálogos.
## Equivalente ao Toolbar + DayTimeMoneyBox + EnergyBar do Stardew Valley.
extends Control


# =============================================================================
# CONSTANTS
# =============================================================================

const HOTBAR_SLOT_SIZE: int = 48
const HOTBAR_PADDING: int = 4
const HOTBAR_MARGIN_BOTTOM: int = 8
const ENERGY_BAR_WIDTH: int = 16
const ENERGY_BAR_HEIGHT: int = 120
const ENERGY_BAR_MARGIN: int = 12
const INFO_PANEL_WIDTH: int = 180
const INFO_PANEL_HEIGHT: int = 80
const INFO_PANEL_MARGIN: int = 8


# =============================================================================
# UI REFERENCES
# =============================================================================

var _hotbar_container: HBoxContainer
var _hotbar_slots: Array[Panel] = []
var _hotbar_labels: Array[Label] = []       ## Quantidade do item
var _hotbar_name_labels: Array[Label] = []  ## Ícone/nome placeholder
var _hotbar_bg: Panel

var _energy_bar_bg: Panel
var _energy_bar_fill: ColorRect
var _energy_label: Label

var _info_panel: Panel
var _clock_label: Label
var _date_label: Label
var _gold_label: Label
var _weather_label: Label

var _notification_label: Label
var _notification_timer: float = 0.0

var _item_tooltip: Panel
var _tooltip_name: Label
var _tooltip_desc: Label


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	name = "HUD"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	
	_build_hotbar()
	_build_energy_bar()
	_build_info_panel()
	_build_notification()
	_build_tooltip()
	
	# Conectar sinais
	EventBus.inventory_changed.connect(_update_hotbar)
	EventBus.hotbar_selection_changed.connect(_on_hotbar_selection_changed)
	EventBus.player_energy_changed.connect(_on_energy_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.time_tick.connect(_on_time_tick)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.show_notification.connect(_show_notification)
	EventBus.show_item_obtained.connect(_on_item_obtained)
	EventBus.menu_opened.connect(func(_n): visible = false)
	EventBus.all_menus_closed.connect(func(): visible = true)
	EventBus.dialogue_started.connect(func(_n): _hotbar_bg.visible = false)
	EventBus.dialogue_ended.connect(func(): _hotbar_bg.visible = true)
	
	# Update inicial
	call_deferred("_initial_update")


func _initial_update() -> void:
	_update_hotbar()
	_on_energy_changed(Constants.DEFAULT_MAX_ENERGY, Constants.DEFAULT_MAX_ENERGY)
	_on_gold_changed(InventorySystem.gold, 0)
	_update_clock()
	_update_weather()


func _process(delta: float) -> void:
	if _notification_timer > 0:
		_notification_timer -= delta
		if _notification_timer <= 0:
			_notification_label.visible = false
		elif _notification_timer < 0.5:
			_notification_label.modulate.a = _notification_timer / 0.5


# =============================================================================
# HOTBAR
# =============================================================================

func _build_hotbar() -> void:
	_hotbar_bg = Panel.new()
	_hotbar_bg.name = "HotbarBG"
	
	var total_width: int = Constants.HOTBAR_SIZE * (HOTBAR_SLOT_SIZE + HOTBAR_PADDING) - HOTBAR_PADDING + 16
	_hotbar_bg.custom_minimum_size = Vector2(total_width, HOTBAR_SLOT_SIZE + 16)
	_hotbar_bg.set_anchors_preset(PRESET_CENTER_BOTTOM)
	_hotbar_bg.position.y = -HOTBAR_MARGIN_BOTTOM
	_hotbar_bg.grow_horizontal = GROW_DIRECTION_BOTH
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.75)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	_hotbar_bg.add_theme_stylebox_override("panel", style)
	add_child(_hotbar_bg)
	
	_hotbar_container = HBoxContainer.new()
	_hotbar_container.name = "HotbarSlots"
	_hotbar_container.set_anchors_preset(PRESET_CENTER)
	_hotbar_container.grow_horizontal = GROW_DIRECTION_BOTH
	_hotbar_container.grow_vertical = GROW_DIRECTION_BOTH
	_hotbar_container.add_theme_constant_override("separation", HOTBAR_PADDING)
	_hotbar_bg.add_child(_hotbar_container)
	
	for i in Constants.HOTBAR_SIZE:
		var slot := _create_hotbar_slot(i)
		_hotbar_container.add_child(slot)
		_hotbar_slots.append(slot)


func _create_hotbar_slot(index: int) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(HOTBAR_SLOT_SIZE, HOTBAR_SLOT_SIZE)
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.4, 0.4, 0.4, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	slot.add_theme_stylebox_override("panel", style)
	
	# Nome/ícone placeholder (texto curto do item)
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.set_anchors_preset(PRESET_FULL_RECT)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	slot.add_child(name_label)
	_hotbar_name_labels.append(name_label)
	
	# Quantidade (canto inferior direito)
	var qty_label := Label.new()
	qty_label.name = "QtyLabel"
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	qty_label.set_anchors_preset(PRESET_FULL_RECT)
	qty_label.add_theme_font_size_override("font_size", 11)
	qty_label.add_theme_color_override("font_color", Color.WHITE)
	slot.add_child(qty_label)
	_hotbar_labels.append(qty_label)
	
	return slot


func _update_hotbar() -> void:
	for i in Constants.HOTBAR_SIZE:
		var slot_data := InventorySystem.get_slot(i)
		var name_label: Label = _hotbar_name_labels[i]
		var qty_label: Label = _hotbar_labels[i]
		
		if slot_data.item_id.is_empty():
			name_label.text = ""
			qty_label.text = ""
		else:
			var item := ItemDatabase.get_item(slot_data.item_id)
			if item:
				# Mostrar abreviação do nome (primeiras 4 letras)
				name_label.text = item.display_name.left(5)
			else:
				name_label.text = slot_data.item_id.left(5)
			
			if slot_data.quantity > 1:
				qty_label.text = str(slot_data.quantity)
			else:
				qty_label.text = ""
	
	_update_hotbar_selection()


func _update_hotbar_selection() -> void:
	for i in _hotbar_slots.size():
		var style: StyleBoxFlat = _hotbar_slots[i].get_theme_stylebox("panel").duplicate()
		if i == InventorySystem.hotbar_selected:
			style.border_color = Color(1.0, 0.85, 0.2, 1.0)  # Dourado = selecionado
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
		else:
			style.border_color = Color(0.4, 0.4, 0.4, 0.8)
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_width_left = 2
			style.border_width_right = 2
		_hotbar_slots[i].add_theme_stylebox_override("panel", style)


func _on_hotbar_selection_changed(_slot: int, _item_id: String) -> void:
	_update_hotbar_selection()
	# Mostrar tooltip do item selecionado
	var item_data := InventorySystem.get_selected_item_data()
	if item_data:
		_show_tooltip(item_data.display_name, item_data.description)
	else:
		_hide_tooltip()


# =============================================================================
# ENERGY BAR
# =============================================================================

func _build_energy_bar() -> void:
	_energy_bar_bg = Panel.new()
	_energy_bar_bg.name = "EnergyBar"
	_energy_bar_bg.custom_minimum_size = Vector2(ENERGY_BAR_WIDTH + 8, ENERGY_BAR_HEIGHT + 8)
	_energy_bar_bg.anchor_right = 1.0
	_energy_bar_bg.anchor_bottom = 1.0
	_energy_bar_bg.anchor_left = 1.0
	_energy_bar_bg.anchor_top = 1.0
	_energy_bar_bg.offset_left = -(ENERGY_BAR_WIDTH + 8 + ENERGY_BAR_MARGIN)
	_energy_bar_bg.offset_top = -(ENERGY_BAR_HEIGHT + 8 + ENERGY_BAR_MARGIN + 60)
	_energy_bar_bg.offset_right = -ENERGY_BAR_MARGIN
	_energy_bar_bg.offset_bottom = -(ENERGY_BAR_MARGIN + 60)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_energy_bar_bg.add_theme_stylebox_override("panel", style)
	add_child(_energy_bar_bg)
	
	# Fill (cresce de baixo para cima)
	_energy_bar_fill = ColorRect.new()
	_energy_bar_fill.name = "Fill"
	_energy_bar_fill.color = Color(0.2, 0.8, 0.3)
	_energy_bar_fill.anchor_left = 0.0
	_energy_bar_fill.anchor_right = 1.0
	_energy_bar_fill.anchor_bottom = 1.0
	_energy_bar_fill.anchor_top = 0.0  # Ajustado dinamicamente
	_energy_bar_fill.offset_left = 4
	_energy_bar_fill.offset_right = -4
	_energy_bar_fill.offset_top = 4
	_energy_bar_fill.offset_bottom = -4
	_energy_bar_bg.add_child(_energy_bar_fill)
	
	# Label de energia
	_energy_label = Label.new()
	_energy_label.name = "EnergyLabel"
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.set_anchors_preset(PRESET_CENTER_BOTTOM)
	_energy_label.position.y = 4
	_energy_label.add_theme_font_size_override("font_size", 10)
	_energy_label.add_theme_color_override("font_color", Color.WHITE)
	_energy_bar_bg.add_child(_energy_label)


func _on_energy_changed(current: float, maximum: float) -> void:
	var ratio := current / maxf(maximum, 1.0)
	# anchor_top: 1.0 = vazio, 0.0 = cheio
	_energy_bar_fill.anchor_top = 1.0 - ratio
	
	# Cor baseada no nível
	if ratio > 0.5:
		_energy_bar_fill.color = Color(0.2, 0.8, 0.3)  # Verde
	elif ratio > 0.25:
		_energy_bar_fill.color = Color(0.9, 0.7, 0.1)  # Amarelo
	else:
		_energy_bar_fill.color = Color(0.9, 0.2, 0.2)  # Vermelho
	
	_energy_label.text = "%d" % int(current)


# =============================================================================
# INFO PANEL (relógio, data, gold, clima)
# =============================================================================

func _build_info_panel() -> void:
	_info_panel = Panel.new()
	_info_panel.name = "InfoPanel"
	_info_panel.custom_minimum_size = Vector2(INFO_PANEL_WIDTH, INFO_PANEL_HEIGHT)
	_info_panel.anchor_right = 1.0
	_info_panel.offset_left = -INFO_PANEL_WIDTH - INFO_PANEL_MARGIN
	_info_panel.offset_right = -INFO_PANEL_MARGIN
	_info_panel.offset_top = INFO_PANEL_MARGIN
	_info_panel.offset_bottom = INFO_PANEL_HEIGHT + INFO_PANEL_MARGIN
	_info_panel.anchor_left = 1.0
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.25, 0.4, 0.6)
	_info_panel.add_theme_stylebox_override("panel", style)
	add_child(_info_panel)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_right = -8
	vbox.offset_top = 6
	vbox.offset_bottom = -6
	vbox.add_theme_constant_override("separation", 2)
	_info_panel.add_child(vbox)
	
	# Relógio
	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 18)
	_clock_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_clock_label)
	
	# Data
	_date_label = Label.new()
	_date_label.add_theme_font_size_override("font_size", 11)
	_date_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_date_label)
	
	# Clima
	_weather_label = Label.new()
	_weather_label.add_theme_font_size_override("font_size", 11)
	_weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_weather_label)
	
	# Gold
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 13)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_gold_label)


func _update_clock() -> void:
	_clock_label.text = TimeSystem.get_time_string()
	_date_label.text = "Dia %d, %s" % [TimeSystem.current_day, TimeSystem.get_season_name()]
	
	# Cor do relógio muda à noite
	if TimeSystem.is_late_night():
		_clock_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif TimeSystem.is_night():
		_clock_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0))
	else:
		_clock_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))


func _update_weather() -> void:
	var weather_name := WeatherSystem.get_weather_name()
	var weather_color := Color.WHITE
	match WeatherSystem.current_weather:
		Constants.Weather.SUNNY: weather_color = Color(1.0, 0.9, 0.3)
		Constants.Weather.RAINY: weather_color = Color(0.5, 0.7, 1.0)
		Constants.Weather.STORMY: weather_color = Color(0.6, 0.4, 0.8)
		Constants.Weather.SNOWY: weather_color = Color(0.85, 0.9, 1.0)
		Constants.Weather.WINDY: weather_color = Color(0.7, 0.9, 0.7)
	_weather_label.text = weather_name
	_weather_label.add_theme_color_override("font_color", weather_color)


func _on_time_tick(_hour: int, _minute: int) -> void:
	_update_clock()

func _on_gold_changed(new_amount: int, _delta: int) -> void:
	_gold_label.text = "%d G" % new_amount

func _on_weather_changed(_w) -> void:
	_update_weather()

func _on_season_changed(_s) -> void:
	_update_clock()

func _on_day_started(_d, _s, _y) -> void:
	_update_clock()
	_update_weather()


# =============================================================================
# NOTIFICATIONS
# =============================================================================

func _build_notification() -> void:
	_notification_label = Label.new()
	_notification_label.name = "Notification"
	_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_label.set_anchors_preset(PRESET_CENTER_TOP)
	_notification_label.position.y = 40
	_notification_label.add_theme_font_size_override("font_size", 16)
	_notification_label.add_theme_color_override("font_color", Color.WHITE)
	_notification_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_notification_label.add_theme_constant_override("shadow_offset_x", 1)
	_notification_label.add_theme_constant_override("shadow_offset_y", 1)
	_notification_label.visible = false
	add_child(_notification_label)


func _show_notification(text: String, _icon: Texture2D = null) -> void:
	_notification_label.text = text
	_notification_label.visible = true
	_notification_label.modulate.a = 1.0
	_notification_timer = 3.0


func _on_item_obtained(item_id: String, quantity: int) -> void:
	var item := ItemDatabase.get_item(item_id)
	var item_name := item.display_name if item else item_id
	var text := "+%d %s" % [quantity, item_name] if quantity > 1 else "+%s" % item_name
	_show_notification(text)


# =============================================================================
# TOOLTIP
# =============================================================================

func _build_tooltip() -> void:
	_item_tooltip = Panel.new()
	_item_tooltip.name = "Tooltip"
	_item_tooltip.visible = false
	_item_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_tooltip.custom_minimum_size = Vector2(200, 50)
	_item_tooltip.set_anchors_preset(PRESET_CENTER_BOTTOM)
	_item_tooltip.position.y = -(HOTBAR_SLOT_SIZE + HOTBAR_MARGIN_BOTTOM + 80)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.35, 0.5, 0.5)
	_item_tooltip.add_theme_stylebox_override("panel", style)
	add_child(_item_tooltip)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_right = -8
	vbox.offset_top = 6
	vbox.offset_bottom = -6
	_item_tooltip.add_child(vbox)
	
	_tooltip_name = Label.new()
	_tooltip_name.add_theme_font_size_override("font_size", 14)
	_tooltip_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_tooltip_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_tooltip_name)
	
	_tooltip_desc = Label.new()
	_tooltip_desc.add_theme_font_size_override("font_size", 11)
	_tooltip_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_tooltip_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_tooltip_desc)


func _show_tooltip(item_name: String, description: String) -> void:
	_tooltip_name.text = item_name
	_tooltip_desc.text = description
	_item_tooltip.visible = true
	# Auto-hide após 2 segundos
	get_tree().create_timer(2.0).timeout.connect(func(): _item_tooltip.visible = false)


func _hide_tooltip() -> void:
	_item_tooltip.visible = false
