## ui/menus/shop_menu.gd
## ShopMenu — Interface de compra e venda com lista de itens.
## Equivalente ao ShopMenu do Stardew Valley.
## Abre com dados dinâmicos: cada loja passa seu inventário.
extends Control


# =============================================================================
# CONSTANTS
# =============================================================================

const ITEM_ROW_HEIGHT: int = 48
const MAX_VISIBLE_ITEMS: int = 8


# =============================================================================
# STATE
# =============================================================================

enum ShopTab { BUY, SELL }

var _current_tab: ShopTab = ShopTab.BUY
var _shop_items: Array[Dictionary] = []  ## [{item_id, price, stock}]
var _selected_index: int = 0
var _quantity: int = 1
var _shop_name: String = "Loja"

var _bg_panel: Panel
var _title_label: Label
var _gold_label: Label
var _tab_buy: Button
var _tab_sell: Button
var _item_list: VBoxContainer
var _item_rows: Array[Panel] = []
var _detail_name: Label
var _detail_desc: Label
var _detail_price: Label
var _quantity_label: Label
var _buy_button: Button
var _scroll_offset: int = 0


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	name = "ShopMenu"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	
	_build_ui()


func _build_ui() -> void:
	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.set_anchors_preset(PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	# Painel principal
	_bg_panel = Panel.new()
	var pw: int = 420
	var ph: int = 480
	_bg_panel.set_anchors_preset(PRESET_CENTER)
	_bg_panel.position = Vector2(-pw / 2.0, -ph / 2.0)
	_bg_panel.size = Vector2(pw, ph)
	
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
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_title_label.position = Vector2(0, 10)
	_title_label.size.x = pw
	_bg_panel.add_child(_title_label)
	
	# Gold do jogador
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_gold_label.position = Vector2(pw - 120, 14)
	_gold_label.size.x = 100
	_bg_panel.add_child(_gold_label)
	
	# Tabs (Comprar / Vender)
	var tab_y: int = 42
	_tab_buy = _create_tab("Comprar", Vector2(20, tab_y), true)
	_tab_buy.pressed.connect(func(): _switch_tab(ShopTab.BUY))
	_bg_panel.add_child(_tab_buy)
	
	_tab_sell = _create_tab("Vender", Vector2(120, tab_y), false)
	_tab_sell.pressed.connect(func(): _switch_tab(ShopTab.SELL))
	_bg_panel.add_child(_tab_sell)
	
	# Lista de itens
	var list_clip := Panel.new()
	list_clip.position = Vector2(16, 80)
	list_clip.size = Vector2(pw - 32, ITEM_ROW_HEIGHT * MAX_VISIBLE_ITEMS)
	list_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	var list_style := StyleBoxFlat.new()
	list_style.bg_color = Color(0.08, 0.06, 0.12, 0.6)
	list_style.corner_radius_top_left = 4
	list_style.corner_radius_top_right = 4
	list_style.corner_radius_bottom_left = 4
	list_style.corner_radius_bottom_right = 4
	list_clip.add_theme_stylebox_override("panel", list_style)
	_bg_panel.add_child(list_clip)
	
	_item_list = VBoxContainer.new()
	_item_list.position = Vector2.ZERO
	_item_list.size.x = pw - 32
	_item_list.add_theme_constant_override("separation", 0)
	list_clip.add_child(_item_list)
	
	# Detail panel
	var detail_y: int = 80 + ITEM_ROW_HEIGHT * MAX_VISIBLE_ITEMS + 10
	var detail_panel := Panel.new()
	detail_panel.position = Vector2(16, detail_y)
	detail_panel.size = Vector2(pw - 32, 80)
	var dp_style := StyleBoxFlat.new()
	dp_style.bg_color = Color(0.1, 0.08, 0.15, 0.7)
	dp_style.corner_radius_top_left = 4
	dp_style.corner_radius_top_right = 4
	dp_style.corner_radius_bottom_left = 4
	dp_style.corner_radius_bottom_right = 4
	detail_panel.add_theme_stylebox_override("panel", dp_style)
	_bg_panel.add_child(detail_panel)
	
	_detail_name = Label.new()
	_detail_name.position = Vector2(10, 6)
	_detail_name.add_theme_font_size_override("font_size", 15)
	_detail_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	detail_panel.add_child(_detail_name)
	
	_detail_desc = Label.new()
	_detail_desc.position = Vector2(10, 28)
	_detail_desc.size = Vector2(pw - 52, 24)
	_detail_desc.add_theme_font_size_override("font_size", 11)
	_detail_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	detail_panel.add_child(_detail_desc)
	
	_detail_price = Label.new()
	_detail_price.position = Vector2(10, 52)
	_detail_price.add_theme_font_size_override("font_size", 13)
	_detail_price.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	detail_panel.add_child(_detail_price)
	
	# Quantidade + Botão de compra
	var action_y: int = detail_y + 90
	
	var qty_minus := Button.new()
	qty_minus.text = "-"
	qty_minus.position = Vector2(pw / 2.0 - 90, action_y)
	qty_minus.size = Vector2(36, 36)
	qty_minus.pressed.connect(func(): _change_quantity(-1))
	_bg_panel.add_child(qty_minus)
	
	_quantity_label = Label.new()
	_quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quantity_label.position = Vector2(pw / 2.0 - 50, action_y)
	_quantity_label.size = Vector2(40, 36)
	_quantity_label.add_theme_font_size_override("font_size", 16)
	_quantity_label.add_theme_color_override("font_color", Color.WHITE)
	_quantity_label.text = "1"
	_bg_panel.add_child(_quantity_label)
	
	var qty_plus := Button.new()
	qty_plus.text = "+"
	qty_plus.position = Vector2(pw / 2.0 - 6, action_y)
	qty_plus.size = Vector2(36, 36)
	qty_plus.pressed.connect(func(): _change_quantity(1))
	_bg_panel.add_child(qty_plus)
	
	_buy_button = Button.new()
	_buy_button.text = "Comprar"
	_buy_button.position = Vector2(pw / 2.0 + 40, action_y)
	_buy_button.size = Vector2(100, 36)
	_buy_button.pressed.connect(_on_action_pressed)
	_bg_panel.add_child(_buy_button)


func _create_tab(text: String, pos: Vector2, active: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(90, 30)
	btn.add_theme_font_size_override("font_size", 13)
	if active:
		btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	else:
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	return btn


# =============================================================================
# OPEN / CLOSE
# =============================================================================

## Abre a loja com uma lista de itens para venda.
## [param shop_name] Nome da loja.
## [param items] Array de dicts: [{item_id: String, price: int, stock: int (-1 = infinito)}]
func open(shop_name: String, items: Array[Dictionary]) -> void:
	_shop_name = shop_name
	_shop_items = items
	_selected_index = 0
	_quantity = 1
	_scroll_offset = 0
	_current_tab = ShopTab.BUY
	
	_title_label.text = _shop_name
	_update_gold()
	_refresh_list()
	_update_detail()
	
	UIManager.open_menu(self)


func close() -> void:
	UIManager.close_top_menu()


# =============================================================================
# TAB SWITCHING
# =============================================================================

func _switch_tab(tab: ShopTab) -> void:
	_current_tab = tab
	_selected_index = 0
	_scroll_offset = 0
	_quantity = 1
	
	_tab_buy.add_theme_color_override("font_color",
		Color(1.0, 0.95, 0.7) if tab == ShopTab.BUY else Color(0.6, 0.6, 0.7))
	_tab_sell.add_theme_color_override("font_color",
		Color(1.0, 0.95, 0.7) if tab == ShopTab.SELL else Color(0.6, 0.6, 0.7))
	_buy_button.text = "Comprar" if tab == ShopTab.BUY else "Vender"
	
	_refresh_list()
	_update_detail()
	EventBus.play_sfx.emit("ui_click")


# =============================================================================
# LIST MANAGEMENT
# =============================================================================

func _get_current_items() -> Array[Dictionary]:
	if _current_tab == ShopTab.BUY:
		return _shop_items
	else:
		# Vender: listar itens do inventário que têm sell_price > 0
		var sell_items: Array[Dictionary] = []
		for i in Constants.TOTAL_INVENTORY_SLOTS:
			var slot := InventorySystem.get_slot(i)
			if slot.item_id.is_empty():
				continue
			var item := ItemDatabase.get_item(slot.item_id)
			if item and item.sell_price > 0:
				sell_items.append({
					"item_id": slot.item_id,
					"price": item.sell_price,
					"stock": slot.quantity,
					"slot_index": i
				})
		return sell_items


func _refresh_list() -> void:
	# Limpar lista
	for child in _item_list.get_children():
		child.queue_free()
	_item_rows.clear()
	
	var items := _get_current_items()
	
	for i in items.size():
		var item_dict := items[i]
		var item_data := ItemDatabase.get_item(item_dict.item_id)
		var row := _create_item_row(i, item_data, item_dict)
		_item_list.add_child(row)
		_item_rows.append(row)
	
	_update_selection()
	_quantity_label.text = str(_quantity)


func _create_item_row(index: int, item_data: ItemData, item_dict: Dictionary) -> Panel:
	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, ITEM_ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.13, 0.2, 0.0)
	row.add_theme_stylebox_override("panel", style)
	
	# Nome do item
	var name_lbl := Label.new()
	name_lbl.text = item_data.display_name if item_data else item_dict.item_id
	name_lbl.position = Vector2(12, 6)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
	row.add_child(name_lbl)
	
	# Preço
	var price_lbl := Label.new()
	price_lbl.text = "%dG" % item_dict.price
	price_lbl.position = Vector2(12, 26)
	price_lbl.add_theme_font_size_override("font_size", 11)
	price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	row.add_child(price_lbl)
	
	# Estoque
	if item_dict.stock >= 0:
		var stock_lbl := Label.new()
		stock_lbl.text = "x%d" % item_dict.stock
		stock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stock_lbl.position = Vector2(row.custom_minimum_size.x - 60, 14)
		stock_lbl.size.x = 50
		stock_lbl.add_theme_font_size_override("font_size", 12)
		stock_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		row.add_child(stock_lbl)
	
	row.gui_input.connect(_on_row_input.bind(index))
	
	return row


func _on_row_input(event: InputEvent, index: int) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		_selected_index = index
		_quantity = 1
		_update_selection()
		_update_detail()
		EventBus.play_sfx.emit("ui_click")


func _update_selection() -> void:
	for i in _item_rows.size():
		var style: StyleBoxFlat = _item_rows[i].get_theme_stylebox("panel").duplicate()
		if i == _selected_index:
			style.bg_color = Color(0.25, 0.2, 0.35, 0.8)
		else:
			style.bg_color = Color(0.15, 0.13, 0.2, 0.0 if i % 2 == 0 else 0.3)
		_item_rows[i].add_theme_stylebox_override("panel", style)


func _update_detail() -> void:
	var items := _get_current_items()
	if _selected_index < 0 or _selected_index >= items.size():
		_detail_name.text = ""
		_detail_desc.text = ""
		_detail_price.text = ""
		return
	
	var item_dict := items[_selected_index]
	var item_data := ItemDatabase.get_item(item_dict.item_id)
	
	_detail_name.text = item_data.display_name if item_data else item_dict.item_id
	_detail_desc.text = item_data.description if item_data else ""
	
	var total := item_dict.price * _quantity
	if _current_tab == ShopTab.BUY:
		_detail_price.text = "Custo: %dG (x%d)" % [total, _quantity]
	else:
		_detail_price.text = "Venda: %dG (x%d)" % [total, _quantity]
	
	_update_gold()


func _update_gold() -> void:
	_gold_label.text = "%dG" % InventorySystem.gold


# =============================================================================
# QUANTITY & ACTION
# =============================================================================

func _change_quantity(delta: int) -> void:
	var items := _get_current_items()
	if _selected_index < 0 or _selected_index >= items.size():
		return
	
	_quantity = maxi(1, _quantity + delta)
	
	# Limitar pela quantidade disponível
	var item_dict := items[_selected_index]
	if item_dict.stock >= 0:
		_quantity = mini(_quantity, item_dict.stock)
	
	# Limitar pelo gold (compra)
	if _current_tab == ShopTab.BUY and item_dict.price > 0:
		var max_afford := InventorySystem.gold / item_dict.price
		_quantity = mini(_quantity, max_afford)
	
	_quantity = maxi(1, _quantity)
	_quantity_label.text = str(_quantity)
	_update_detail()


func _on_action_pressed() -> void:
	var items := _get_current_items()
	if _selected_index < 0 or _selected_index >= items.size():
		return
	
	var item_dict := items[_selected_index]
	var total_cost: int = item_dict.price * _quantity
	
	if _current_tab == ShopTab.BUY:
		if not InventorySystem.spend_gold(total_cost):
			EventBus.show_notification.emit("Gold insuficiente!", null)
			return
		var leftover := InventorySystem.add_item(item_dict.item_id, _quantity)
		if leftover > 0:
			InventorySystem.earn_gold(leftover * item_dict.price)
			EventBus.show_notification.emit("Inventário cheio!", null)
		else:
			EventBus.show_notification.emit("Comprou %d %s!" % [_quantity, item_dict.item_id], null)
			EventBus.play_sfx.emit("purchase")
	else:
		# Vender
		if item_dict.has("slot_index"):
			InventorySystem.remove_from_slot(item_dict.slot_index, _quantity)
		else:
			InventorySystem.remove_item(item_dict.item_id, _quantity)
		InventorySystem.earn_gold(total_cost)
		EventBus.show_notification.emit("Vendeu por %dG!" % total_cost, null)
		EventBus.play_sfx.emit("purchase")
	
	_quantity = 1
	_refresh_list()
	_update_detail()


# =============================================================================
# INPUT
# =============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		close()
		get_viewport().set_input_as_handled()
