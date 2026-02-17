## ui/menus/crafting_menu.gd
## CraftingMenu — Interface de crafting com receitas desbloqueadas.
extends Control


var _recipe_rows: Array[Panel] = []
var _selected_index: int = 0
var _current_recipes: Array[Dictionary] = []

var _bg_panel: Panel
var _list_container: VBoxContainer
var _detail_name: Label
var _detail_ingredients: Label
var _detail_result: Label
var _craft_button: Button


func _ready() -> void:
	name = "CraftingMenu"
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
	
	var pw: int = 380
	var ph: int = 420
	_bg_panel = Panel.new()
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
	
	var title := Label.new()
	title.text = "Crafting"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	title.position = Vector2(0, 10)
	title.size.x = pw
	_bg_panel.add_child(title)
	
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16, 45)
	scroll.size = Vector2(pw - 32, 220)
	_bg_panel.add_child(scroll)
	
	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 2)
	scroll.add_child(_list_container)
	
	# Detail area
	var dy: int = 275
	_detail_name = Label.new()
	_detail_name.position = Vector2(20, dy)
	_detail_name.add_theme_font_size_override("font_size", 16)
	_detail_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_bg_panel.add_child(_detail_name)
	
	_detail_ingredients = Label.new()
	_detail_ingredients.position = Vector2(20, dy + 24)
	_detail_ingredients.size = Vector2(pw - 40, 40)
	_detail_ingredients.add_theme_font_size_override("font_size", 11)
	_detail_ingredients.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_detail_ingredients.autowrap_mode = TextServer.AUTOWRAP_WORD
	_bg_panel.add_child(_detail_ingredients)
	
	_detail_result = Label.new()
	_detail_result.position = Vector2(20, dy + 66)
	_detail_result.add_theme_font_size_override("font_size", 12)
	_detail_result.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	_bg_panel.add_child(_detail_result)
	
	_craft_button = Button.new()
	_craft_button.text = "Craftar"
	_craft_button.position = Vector2(pw / 2.0 - 55, ph - 50)
	_craft_button.size = Vector2(110, 36)
	_craft_button.pressed.connect(_on_craft)
	_bg_panel.add_child(_craft_button)


func open() -> void:
	_refresh_list()
	_update_detail()
	UIManager.open_menu(self)


func close() -> void:
	UIManager.close_top_menu()


func _refresh_list() -> void:
	for child in _list_container.get_children():
		child.queue_free()
	_recipe_rows.clear()
	_current_recipes = CraftingSystem.get_unlocked_recipes()
	
	for i in _current_recipes.size():
		var recipe: Dictionary = _current_recipes[i]
		var row := Panel.new()
		row.custom_minimum_size = Vector2(0, 36)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.15, 0.13, 0.2, 0.0 if i % 2 == 0 else 0.3)
		row.add_theme_stylebox_override("panel", s)
		
		var lbl := Label.new()
		lbl.text = recipe.display_name
		lbl.position = Vector2(10, 8)
		lbl.add_theme_font_size_override("font_size", 13)
		var can := CraftingSystem.can_craft(recipe.id)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95) if can else Color(0.5, 0.5, 0.55))
		row.add_child(lbl)
		
		row.gui_input.connect(func(event: InputEvent):
			if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				_selected_index = i
				_update_detail()
				_update_selection()
		)
		
		_list_container.add_child(row)
		_recipe_rows.append(row)
	
	_update_selection()


func _update_selection() -> void:
	for i in _recipe_rows.size():
		var s: StyleBoxFlat = _recipe_rows[i].get_theme_stylebox("panel").duplicate()
		s.bg_color = Color(0.25, 0.2, 0.35, 0.8) if i == _selected_index else Color(0.15, 0.13, 0.2, 0.0 if i % 2 == 0 else 0.3)
		_recipe_rows[i].add_theme_stylebox_override("panel", s)


func _update_detail() -> void:
	if _selected_index < 0 or _selected_index >= _current_recipes.size():
		_detail_name.text = ""
		_detail_ingredients.text = ""
		_detail_result.text = ""
		return
	
	var recipe: Dictionary = _current_recipes[_selected_index]
	_detail_name.text = recipe.display_name
	
	var ing_text := "Necessário: "
	var ing_parts: Array[String] = []
	for item_id in recipe.ingredients:
		var qty: int = recipe.ingredients[item_id]
		var have := InventorySystem.count_item(item_id)
		var item := ItemDatabase.get_item(item_id)
		var name_str: String = item.display_name if item else item_id
		var color := "✓" if have >= qty else "✗"
		ing_parts.append("%s %s (%d/%d)" % [color, name_str, have, qty])
	_detail_ingredients.text = ing_text + ", ".join(ing_parts)
	
	var result_item := ItemDatabase.get_item(recipe.result_id)
	var result_name: String = result_item.display_name if result_item else recipe.result_id
	_detail_result.text = "Produz: %s x%d" % [result_name, recipe.result_qty]
	
	_craft_button.disabled = not CraftingSystem.can_craft(recipe.id)


func _on_craft() -> void:
	if _selected_index < 0 or _selected_index >= _current_recipes.size():
		return
	CraftingSystem.craft(_current_recipes[_selected_index].id)
	_refresh_list()
	_update_detail()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		close()
		get_viewport().set_input_as_handled()
