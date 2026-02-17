## scenes/main.gd
## Main — Script raiz do jogo. Bootstraps e gerencia o fluxo de cenas.
## Entry point: mostra o título, depois inicia o jogo quando solicitado.
extends Node


## Container onde as locations são instanciadas
var _world_container: Node2D

## Tela de título
var _title_screen: Control

## Player instanciado
var _player_node: CharacterBody2D

## Camera do jogo
var _camera: Camera2D


func _ready() -> void:
	# Criar containers
	_world_container = Node2D.new()
	_world_container.name = "World"
	add_child(_world_container)
	
	# Registrar o container no LocationManager
	LocationManager.set_location_container(_world_container)
	
	# Criar e mostrar a tela de título
	_show_title_screen()
	
	# Conectar sinais do GameManager
	EventBus.new_game_started.connect(_on_game_started)
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.game_state_changed.connect(_on_game_state_changed)


# =============================================================================
# TITLE SCREEN
# =============================================================================

func _show_title_screen() -> void:
	if _title_screen:
		_title_screen.queue_free()
	
	var TitleScript := load("res://ui/menus/title_screen.gd")
	if TitleScript:
		_title_screen = Control.new()
		_title_screen.set_script(TitleScript)
		_title_screen.name = "TitleScreen"
		add_child(_title_screen)
	else:
		# Fallback: iniciar jogo direto se não tem title screen
		push_warning("[Main] TitleScreen não encontrado, iniciando jogo direto.")
		GameManager.start_new_game("Fazendeiro", "Minha Fazenda", 1)


# =============================================================================
# GAME START
# =============================================================================

func _on_game_started() -> void:
	_cleanup_title()
	_setup_game_world()

func _on_game_loaded(_slot: int) -> void:
	_cleanup_title()
	_setup_game_world()


func _cleanup_title() -> void:
	if _title_screen and is_instance_valid(_title_screen):
		_title_screen.queue_free()
		_title_screen = null


func _setup_game_world() -> void:
	# Instanciar o player se ainda não existe
	if not _player_node:
		var PlayerScript := load("res://player/player_controller.gd")
		if PlayerScript:
			_player_node = CharacterBody2D.new()
			_player_node.set_script(PlayerScript)
			_player_node.name = "Player"
			_world_container.add_child(_player_node)
		else:
			push_error("[Main] PlayerController script não encontrado!")
			return
	
	# Criar câmera que segue o player
	if not _camera:
		_camera = Camera2D.new()
		_camera.name = "PlayerCamera"
		_camera.position_smoothing_enabled = true
		_camera.position_smoothing_speed = 8.0
		_camera.zoom = Vector2(3.0, 3.0)  # Zoom para pixel art 16x16
		_player_node.add_child(_camera)
		_camera.make_current()
	
	# Iniciar o tempo
	TimeSystem.start_time()


func _on_game_state_changed(_old: Constants.GameState, new_state: Constants.GameState) -> void:
	if new_state == Constants.GameState.MAIN_MENU:
		# Limpar o mundo
		if _player_node and is_instance_valid(_player_node):
			_player_node.queue_free()
			_player_node = null
			_camera = null
		LocationManager.unload_current_location()
		LocationManager.clear_cache()
		_show_title_screen()
