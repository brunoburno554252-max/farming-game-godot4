## autoloads/ui_manager.gd
## UIManager — Gerencia stack de menus e HUD.
## SERÁ EXPANDIDO NA ETAPA 5 (UI).
extends CanvasLayer

## Stack de menus abertos (último = topo)
var _menu_stack: Array[Control] = []

## Referência ao HUD
var hud: Control = null


func _ready() -> void:
	layer = 10  # UI sempre por cima
	process_mode = Node.PROCESS_MODE_ALWAYS  # UI funciona mesmo com jogo pausado


## Abre um menu (empilha no stack).
func open_menu(menu: Control) -> void:
	if menu in _menu_stack:
		return
	_menu_stack.append(menu)
	menu.visible = true
	EventBus.menu_opened.emit(menu.name)
	
	if _menu_stack.size() == 1:
		# Primeiro menu aberto: pausa o jogo
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if is_any_menu_open():
			close_top_menu()
		elif GameManager.is_playing():
			# Abrir menu de pause (será implementado na Etapa 5)
			pass
		get_viewport().set_input_as_handled()
