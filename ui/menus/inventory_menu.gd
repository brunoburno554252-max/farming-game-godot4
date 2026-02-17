## ui/menus/inventory_menu.gd
## InventoryMenu — Tela completa de inventário com grid de slots.
## Suporta seleção, swap entre slots, info do item, e separação hotbar/backpack.
## Equivalente ao InventoryPage do Stardew Valley.
extends Control


# =============================================================================
# CONSTANTS
# =============================================================================

const SLOT_SIZE: int = 52
const SLOT_GAP: int = 4
const SECTION_GAP: int = 16
const MARGIN: int = 20


# =============================================================================
# STATE
# =============================================================================

var _selected_slot: int = -1
var _held_slot: int = -1  ## Slot sendo "segurado" para swap

var _slot_panels: Array[Panel] = []
var _slot_name_labels: Array[Label] = []
var _slot_qty_labels: Array[Label] = []

var _item_info_name: Label
var _item_info_desc: Label
var _item_info_type: Label
var _item_info_value: Label

var _bg_panel: Panel


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	name = "InventoryMenu"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	
	_build_ui()
	
	EventBus.inventory_changed.connect(_refresh_all_slots)


func _build_ui() -> void:
	# Fundo semi-transparente
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.set_anchors_preset(PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	# Painel central
	_bg_panel = Panel.new()
	_bg_panel.name = "BG"
	var total_cols := Constants.INVENTORY_COLS
	var panel_w: int = total_cols * (SLOT_SIZE + SLOT_GAP) - SLOT_GAP + MARGIN * 2
	var panel_h: int = (Constants.INVENTORY_ROWS + 1) * (SLOT_SIZE + SLOT_GAP) + SECTION_GAP + 120 + MARGIN * 2
	_bg_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	_bg_panel.set_anchors_preset(PRESET_CENTER)
	_bg_panel.position -= Vector2(panel_w / 2.0, panel_h / 2.0)
	_bg_panel.size = Vector2(panel_w, panel_h)
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.1, 0.18, 0.95)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_color = Color(0.4, 0.35, 0.5, 0.7)
	_bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_bg_panel)
	
	# Título
	var title := Label.new()
	title.text = "Inventário"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	title.position = Vector2(0, 8)
	title.size.x = panel_w
	_bg_panel.add_child(title)
	
	# Label "Mochila"
	var backpack_label := Label.new()
	backpack_label.text = "Mochila"
	backpack_label.add_theme_font_size_override("font_size", 12)
	backpack_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	backpack_label.position = Vector2(MARGIN, 38)
	_bg_panel.add_child(backpack_label)
	
	# Grid de slots — Backpack (linhas 0-2)
	var start_y: int = 54
	for row in Constants.INVENTORY_ROWS:
		for col in total_cols:
			var slot_index := Constants.HOTBAR_SIZE + row * total_cols + col
			var pos := Vector2(
				MARGIN + col * (SLOT_SIZE + SLOT_GAP),
				start_y + row * (SLOT_SIZE + SLOT_GAP)
			)
			_create_slot(slot_index, pos)
	
	# Separador
	var separator_y: int = start_y + Constants.INVENTORY_ROWS * (SLOT_SIZE + SLOT_GAP) + 4
	
	# Label "Hotbar"
	var hotbar_label := Label.new()
	hotbar_label.text = "Hotbar"
	hotbar_label.add_theme_font_size_override("font_size", 12)
	hotbar_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	hotbar_label.position = Vector2(MARGIN, separator_y)
	_bg_panel.add_child(hotbar_label)
	
	# Hotbar slots
	var hotbar_y: int = separator_y + 18
	for i in Constants.HOTBAR_SIZE:
		var pos := Vector2(
			MARGIN + i * (SLOT_SIZE + SLOT_GAP),
			hotbar_y
		)
		_create_slot(i, pos)
	
	# Painel de informação do item (abaixo dos slots)
	var info_y: int = hotbar_y + SLOT_SIZE + SECTION_GAP
	_build_item_info(info_y, panel_w)


func _create_slot(slot_index: int, pos: Vector2) -> void:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.position = pos
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.18, 0.25, 0.9)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.35, 0.3, 0.45, 0.7)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	slot.add_theme_stylebox_override("panel", style)
	
	# Nome curto do item
	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.set_anchors_preset(PRESET_FULL_RECT)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	slot.add_child(name_label)
	
	# Quantidade
	var qty_label := Label.new()
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	qty_label.set_anchors_preset(PRESET_FULL_RECT)
	qty_label.add_theme_font_size_override("font_size", 11)
	qty_label.add_theme_color_override("font_color", Color.WHITE)
	slot.add_child(qty_label)
	
	# Guardar referências na ordem do slot_index
	# Precisamos garantir que os arrays são grandes o suficiente
	while _slot_panels.size() <= slot_index:
		_slot_panels.append(null)
		_slot_name_labels.append(null)
		_slot_qty_labels.append(null)
	
	_slot_panels[slot_index] = slot
	_slot_name_labels[slot_index] = name_label
	_slot_qty_labels[slot_index] = qty_label
	
	# Input de click/touch
	slot.gui_input.connect(_on_slot_input.bind(slot_index))
	
	_bg_panel.add_child(slot)


func _build_item_info(y_pos: int, panel_width: int) -> void:
	var info_bg := Panel.new()
	info_bg.position = Vector2(MARGIN, y_pos)
	info_bg.size = Vector2(panel_width - MARGIN * 2, 100)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.13, 0.2, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	info_bg.add_theme_stylebox_override("panel", style)
	_bg_panel.add_child(info_bg)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 6
	vbox.offset_bottom = -6
	vbox.add_theme_constant_override("separation", 2)
	info_bg.add_child(vbox)
	
	_item_info_name = Label.new()
	_item_info_name.add_theme_font_size_override("font_size", 16)
	_item_info_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	vbox.add_child(_item_info_name)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	
	_item_info_type = Label.new()
	_item_info_type.add_theme_font_size_override("font_size", 11)
	_item_info_type.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	hbox.add_child(_item_info_type)
	
	_item_info_value = Label.new()
	_item_info_value.add_theme_font_size_override("font_size", 11)
	_item_info_value.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	hbox.add_child(_item_info_value)
	
	_item_info_desc = Label.new()
	_item_info_desc.add_theme_font_size_override("font_size", 11)
	_item_info_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_item_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_item_info_desc)


# =============================================================================
# SLOT INTERACTION
# =============================================================================

func _on_slot_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_slot_click(slot_index)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_slot_click(slot_index)


func _handle_slot_click(slot_index: int) -> void:
	if _held_slot >= 0:
		# Segundo click: fazer swap
		if _held_slot != slot_index:
			InventorySystem.swap_slots(_held_slot, slot_index)
		_held_slot = -1
		_selected_slot = slot_index
	else:
		var slot_data := InventorySystem.get_slot(slot_index)
		if not slot_data.item_id.is_empty():
			_held_slot = slot_index
			_selected_slot = slot_index
		else:
			_selected_slot = -1
	
	_refresh_all_slots()
	_update_item_info()
	EventBus.play_sfx.emit("ui_click")


# =============================================================================
# REFRESH
# =============================================================================

func _refresh_all_slots() -> void:
	for i in _slot_panels.size():
		if _slot_panels[i] == null:
			continue
		_refresh_slot(i)


func _refresh_slot(index: int) -> void:
	var slot_data := InventorySystem.get_slot(index)
	var name_label: Label = _slot_name_labels[index]
	var qty_label: Label = _slot_qty_labels[index]
	
	if slot_data.item_id.is_empty():
		name_label.text = ""
		qty_label.text = ""
	else:
		var item := ItemDatabase.get_item(slot_data.item_id)
		name_label.text = item.display_name.left(6) if item else slot_data.item_id.left(6)
		qty_label.text = str(slot_data.quantity) if slot_data.quantity > 1 else ""
	
	# Estilo do slot
	var style: StyleBoxFlat = _slot_panels[index].get_theme_stylebox("panel").duplicate()
	if index == _held_slot:
		style.border_color = Color(0.2, 0.8, 1.0, 1.0)  # Azul = segurado
		style.bg_color = Color(0.25, 0.25, 0.35, 0.95)
	elif index == _selected_slot:
		style.border_color = Color(1.0, 0.85, 0.2, 1.0)  # Dourado = selecionado
	elif index < Constants.HOTBAR_SIZE and index == InventorySystem.hotbar_selected:
		style.border_color = Color(0.7, 0.6, 0.2, 0.8)  # Dourado suave = hotbar ativo
	else:
		style.border_color = Color(0.35, 0.3, 0.45, 0.7)
		style.bg_color = Color(0.2, 0.18, 0.25, 0.9)
	_slot_panels[index].add_theme_stylebox_override("panel", style)


func _update_item_info() -> void:
	if _selected_slot < 0:
		_item_info_name.text = ""
		_item_info_desc.text = "Selecione um item"
		_item_info_type.text = ""
		_item_info_value.text = ""
		return
	
	var slot_data := InventorySystem.get_slot(_selected_slot)
	if slot_data.item_id.is_empty():
		_item_info_name.text = ""
		_item_info_desc.text = "Slot vazio"
		_item_info_type.text = ""
		_item_info_value.text = ""
		return
	
	var item := ItemDatabase.get_item(slot_data.item_id)
	if not item:
		_item_info_name.text = slot_data.item_id
		_item_info_desc.text = ""
		_item_info_type.text = ""
		_item_info_value.text = ""
		return
	
	_item_info_name.text = item.display_name
	_item_info_desc.text = item.description
	_item_info_type.text = Constants.ItemType.keys()[item.item_type]
	
	if item.sell_price > 0:
		_item_info_value.text = "%dG" % item.sell_price
	else:
		_item_info_value.text = ""


# =============================================================================
# OPEN / CLOSE
# =============================================================================

func open() -> void:
	_selected_slot = -1
	_held_slot = -1
	_refresh_all_slots()
	_update_item_info()
	UIManager.open_menu(self)


func close() -> void:
	_held_slot = -1
	UIManager.close_top_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("open_inventory"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
