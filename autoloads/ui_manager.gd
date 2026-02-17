## autoloads/ui_manager.gd
## UIManager — Gerencia stack de menus, HUD, e instanciação de UI.
## Coordena todos os elementos visuais da interface.
## Equivalente ao Game1.activeClickableMenu + HUD do Stardew Valley.
extends CanvasLayer


# =============================================================================
# STATE
# =============================================================================

## Stack de menus abertos (último = topo)
var _menu_stack: Array[Control] = []

## Referências aos componentes de UI
var hud: Control = null
var inventory_menu: Control = null
var pause_menu: Control = null
var shop_menu: Control = null
var dialogue_box: Control = null
var crafting_menu: Control = null
var fishing_minigame: Control = null
var elevator_menu: Control = null

## Root container para todos os UI elements
var _ui_root: Control


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Container raiz
	_ui_root = Control.new()
	_ui_root.name = "UIRoot"
	_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui_root)
	
	# Instanciar componentes de UI
	_create_ui_components()
	
	# Conectar sinais
	EventBus.game_ready.connect(_on_game_ready)


func _create_ui_components() -> void:
	# HUD
	var HUDScript := load("res://ui/hud/hud.gd")
	if HUDScript:
		hud = Control.new()
		hud.set_script(HUDScript)
		hud.name = "HUD"
		_ui_root.add_child(hud)
	
	# Inventory Menu
	var InvScript := load("res://ui/menus/inventory_menu.gd")
	if InvScript:
		inventory_menu = Control.new()
		inventory_menu.set_script(InvScript)
		inventory_menu.name = "InventoryMenu"
		inventory_menu.add_to_group("inventory_menu")
		_ui_root.add_child(inventory_menu)
	
	# Pause Menu
	var PauseScript := load("res://ui/menus/pause_menu.gd")
	if PauseScript:
		pause_menu = Control.new()
		pause_menu.set_script(PauseScript)
		pause_menu.name = "PauseMenu"
		_ui_root.add_child(pause_menu)
	
	# Shop Menu
	var ShopScript := load("res://ui/menus/shop_menu.gd")
	if ShopScript:
		shop_menu = Control.new()
		shop_menu.set_script(ShopScript)
		shop_menu.name = "ShopMenu"
		_ui_root.add_child(shop_menu)
	
	# Dialogue Box
	var DialogueScript := load("res://ui/dialogue/dialogue_box.gd")
	if DialogueScript:
		dialogue_box = Control.new()
		dialogue_box.set_script(DialogueScript)
		dialogue_box.name = "DialogueBox"
		_ui_root.add_child(dialogue_box)
	
	# Crafting Menu
	var CraftScript := load("res://ui/menus/crafting_menu.gd")
	if CraftScript:
		crafting_menu = Control.new()
		crafting_menu.set_script(CraftScript)
		crafting_menu.name = "CraftingMenu"
		_ui_root.add_child(crafting_menu)
	
	# Fishing Minigame
	var FishScript := load("res://ui/minigames/fishing_minigame.gd")
	if FishScript:
		fishing_minigame = Control.new()
		fishing_minigame.set_script(FishScript)
		fishing_minigame.name = "FishingMinigame"
		_ui_root.add_child(fishing_minigame)
	
	# Elevator Menu
	var ElevScript := load("res://ui/menus/elevator_menu.gd")
	if ElevScript:
		elevator_menu = Control.new()
		elevator_menu.set_script(ElevScript)
		elevator_menu.name = "ElevatorMenu"
		_ui_root.add_child(elevator_menu)


func _on_game_ready() -> void:
	# Mostrar HUD quando o jogo estiver pronto
	if hud:
		hud.visible = true


# =============================================================================
# MENU STACK
# =============================================================================

## Abre um menu (empilha no stack).
func open_menu(menu: Control) -> void:
	if menu in _menu_stack:
		return
	_menu_stack.append(menu)
	menu.visible = true
	EventBus.menu_opened.emit(menu.name)
	
	if _menu_stack.size() == 1:
		GameManager.pause_game()


## Fecha o menu do topo do stack.
func close_top_menu() -> void:
	if _menu_stack.is_empty():
		return
	var menu := _menu_stack.pop_back()
	menu.visible = false
	EventBus.menu_closed.emit(menu.name)
	
	if _menu_stack.is_empty():
		GameManager.return_to_playing()
		EventBus.all_menus_closed.emit()


## Fecha todos os menus.
func close_all_menus() -> void:
	while not _menu_stack.is_empty():
		var menu := _menu_stack.pop_back()
		menu.visible = false
		EventBus.menu_closed.emit(menu.name)
	GameManager.return_to_playing()
	EventBus.all_menus_closed.emit()


## Verifica se algum menu está aberto.
func is_any_menu_open() -> bool:
	return not _menu_stack.is_empty()


## Retorna o menu no topo do stack.
func get_top_menu() -> Control:
	if _menu_stack.is_empty():
		return null
	return _menu_stack.back()


# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

## Abre o inventário.
func open_inventory() -> void:
	if inventory_menu and inventory_menu.has_method("open"):
		inventory_menu.open()


## Abre o menu de pausa.
func open_pause() -> void:
	if pause_menu and pause_menu.has_method("open"):
		pause_menu.open()


## Abre uma loja.
## [param shop_name] Nome da loja.
## [param items] Array de dicts: [{item_id, price, stock}]
func open_shop(shop_name: String, items: Array[Dictionary]) -> void:
	if shop_menu and shop_menu.has_method("open"):
		shop_menu.open(shop_name, items)


## Abre o crafting.
func open_crafting() -> void:
	if crafting_menu and crafting_menu.has_method("open"):
		crafting_menu.open()


## Abre o elevador da mina.
func open_elevator() -> void:
	if elevator_menu and elevator_menu.has_method("open"):
		elevator_menu.open()


## Inicia o minigame de pesca.
func start_fishing_minigame(fish_data: Dictionary) -> void:
	if fishing_minigame and fishing_minigame.has_method("start"):
		fishing_minigame.start(fish_data)


## Mostra/esconde o HUD.
func set_hud_visible(v: bool) -> void:
	if hud:
		hud.visible = v


# =============================================================================
# INPUT
# =============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if is_any_menu_open():
			close_top_menu()
		elif GameManager.is_playing():
			open_pause()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("open_inventory"):
		if is_any_menu_open():
			# Se o inventário está aberto, fechar; senão ignorar
			if get_top_menu() == inventory_menu:
				close_top_menu()
		elif GameManager.is_playing():
			open_inventory()
		get_viewport().set_input_as_handled()
