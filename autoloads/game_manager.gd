## autoloads/game_manager.gd
## GameManager — Orquestrador central do jogo.
## Controla o estado global, inicialização de sistemas, save/load, e transições de dia.
## Equivalente ao Game1 do Stardew Valley.
extends Node


# =============================================================================
# STATE
# =============================================================================

## Estado atual do jogo
var current_state: Constants.GameState = Constants.GameState.INITIALIZING

## Dados do jogador (carregados do save ou criados no new game)
var player_name: String = ""
var farm_name: String = ""
var save_slot: int = -1

## Flag para saber se o jogo está rodando
var is_game_running: bool = false


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Configurações de performance para mobile
	_apply_mobile_settings()
	
	# Conectar sinais do EventBus que o GameManager precisa ouvir
	EventBus.player_slept.connect(_on_player_slept)
	EventBus.player_passed_out.connect(_on_player_passed_out)
	
	# Aguarda um frame para garantir que todos os Autoloads foram carregados
	await get_tree().process_frame
	
	_change_state(Constants.GameState.MAIN_MENU)
	print("[GameManager] Sistemas inicializados. Aguardando input do jogador.")


func _apply_mobile_settings() -> void:
	Engine.max_fps = Constants.TARGET_FPS
	# Desabilita VSync em mobile para melhor responsividade
	# DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


# =============================================================================
# GAME STATE MANAGEMENT
# =============================================================================

## Muda o estado do jogo e emite o sinal correspondente.
func _change_state(new_state: Constants.GameState) -> void:
	if new_state == current_state:
		return
	
	var old_state := current_state
	current_state = new_state
	
	# Pausa/despausa a árvore de cena conforme o estado
	match new_state:
		Constants.GameState.PLAYING:
			get_tree().paused = false
		Constants.GameState.PAUSED, Constants.GameState.INVENTORY, \
		Constants.GameState.SHOPPING, Constants.GameState.CRAFTING:
			get_tree().paused = true
		Constants.GameState.DIALOGUE:
			get_tree().paused = true
		Constants.GameState.CUTSCENE:
			get_tree().paused = true
	
	EventBus.game_state_changed.emit(old_state, new_state)
	print("[GameManager] Estado: %s → %s" % [
		Constants.GameState.keys()[old_state],
		Constants.GameState.keys()[new_state]
	])


## Retorna true se o jogo está em um estado "jogável" (não em menu/transição)
func is_playing() -> bool:
	return current_state == Constants.GameState.PLAYING


## Retorna true se o jogador pode mover/agir
func can_player_act() -> bool:
	return current_state == Constants.GameState.PLAYING


## Pausa o jogo (ex: ao abrir menu)
func pause_game() -> void:
	if current_state == Constants.GameState.PLAYING:
		_change_state(Constants.GameState.PAUSED)


## Despausa o jogo
func unpause_game() -> void:
	if current_state == Constants.GameState.PAUSED:
		_change_state(Constants.GameState.PLAYING)


## Entra em modo de diálogo
func enter_dialogue() -> void:
	_change_state(Constants.GameState.DIALOGUE)


## Sai do modo de diálogo
func exit_dialogue() -> void:
	_change_state(Constants.GameState.PLAYING)


## Entra em modo de loja
func enter_shopping() -> void:
	_change_state(Constants.GameState.SHOPPING)


## Entra em modo de inventário
func enter_inventory() -> void:
	_change_state(Constants.GameState.INVENTORY)


## Volta para o estado PLAYING (de qualquer estado de menu/UI)
func return_to_playing() -> void:
	_change_state(Constants.GameState.PLAYING)


# =============================================================================
# NEW GAME
# =============================================================================

## Inicia um novo jogo.
## [param p_name] Nome do jogador.
## [param f_name] Nome da fazenda.
## [param slot] Slot de save (0, 1, ou 2).
func start_new_game(p_name: String, f_name: String, slot: int) -> void:
	print("[GameManager] Iniciando novo jogo: %s na fazenda %s (slot %d)" % [p_name, f_name, slot])
	
	player_name = p_name
	farm_name = f_name
	save_slot = slot
	
	_change_state(Constants.GameState.LOADING)
	
	# Inicializar banco de itens
	ItemDatabase.initialize()
	NPCDatabase.initialize()
	
	# Inicializar banco de dados com tabelas vazias
	DatabaseManager.create_new_save(slot)
	
	# Inicializar sistemas com valores padrão
	TimeSystem.initialize_new_game()
	WeatherSystem.initialize_new_game()
	InventorySystem.initialize_new_game()
	FriendshipSystem.initialize_new_game()
	SkillSystem.initialize_new_game()
	CraftingSystem.initialize_new_game()
	
	# Carregar a fazenda como location inicial
	await LocationManager.load_location(Constants.LOCATION_FARM)
	
	_change_state(Constants.GameState.PLAYING)
	is_game_running = true
	
	EventBus.new_game_started.emit()
	EventBus.game_ready.emit()
	print("[GameManager] Novo jogo iniciado com sucesso!")


# =============================================================================
# SAVE / LOAD
# =============================================================================

## Salva o jogo no slot atual.
func save_game() -> void:
	if save_slot < 0:
		push_error("[GameManager] Tentativa de salvar sem slot definido!")
		return
	
	print("[GameManager] Salvando jogo no slot %d..." % save_slot)
	_change_state(Constants.GameState.SAVING)
	
	# Cada sistema serializa seus dados para o DB
	TimeSystem.save_data()
	WeatherSystem.save_data()
	InventorySystem.save_data()
	FriendshipSystem.save_data()
	SkillSystem.save_data()
	CraftingSystem.save_data()
	LocationManager.save_all_locations()
	# PlayerController salva via LocationManager (posição, energia, etc.)
	
	DatabaseManager.commit_save()
	
	_change_state(Constants.GameState.PLAYING)
	EventBus.game_saved.emit(save_slot)
	print("[GameManager] Jogo salvo com sucesso!")


## Carrega um jogo de um slot de save.
## [param slot] Slot de save para carregar.
func load_game(slot: int) -> void:
	print("[GameManager] Carregando jogo do slot %d..." % slot)
	_change_state(Constants.GameState.LOADING)
	
	save_slot = slot
	
	# Inicializar banco de itens
	ItemDatabase.initialize()
	NPCDatabase.initialize()
	
	# Carregar dados do DB
	var success := DatabaseManager.load_save(slot)
	if not success:
		push_error("[GameManager] Falha ao carregar save do slot %d!" % slot)
		_change_state(Constants.GameState.MAIN_MENU)
		return
	
	# Cada sistema desserializa seus dados do DB
	var game_data := DatabaseManager.get_game_state()
	player_name = game_data.get("player_name", "")
	farm_name = game_data.get("farm_name", "")
	
	TimeSystem.load_data()
	WeatherSystem.load_data()
	InventorySystem.load_data()
	FriendshipSystem.load_data()
	SkillSystem.load_data()
	CraftingSystem.load_data()
	
	# Carregar a location onde o jogador estava
	var last_location: String = game_data.get("current_location", Constants.LOCATION_FARM)
	await LocationManager.load_location(last_location)
	
	_change_state(Constants.GameState.PLAYING)
	is_game_running = true
	
	EventBus.game_loaded.emit(slot)
	EventBus.game_ready.emit()
	print("[GameManager] Jogo carregado com sucesso!")


# =============================================================================
# DAY TRANSITION (Dormir / Desmaiar)
# =============================================================================

## Processa a transição de dia. Chamado quando o jogador dorme ou desmaia.
## Este é o coração do loop diário — equivalente ao _newDayAfterFade() do Stardew.
func _process_day_transition(is_passed_out: bool) -> void:
	_change_state(Constants.GameState.DAY_TRANSITION)
	
	print("[GameManager] Processando transição de dia...")
	
	# 1. Emitir sinal de fim do dia (para sistemas limparem estado diário)
	EventBus.day_ended.emit()
	
	# 2. Avançar o tempo para o próximo dia
	TimeSystem.advance_to_next_day()
	
	# 3. Determinar o clima do próximo dia
	WeatherSystem.determine_weather_for_day(
		TimeSystem.current_day,
		TimeSystem.current_season
	)
	
	# 4. Emitir sinal de processamento (crescimento de plantas, NPCs resetam, etc.)
	EventBus.day_transition_process.emit()
	
	# 5. Restaurar energia do jogador
	if is_passed_out:
		# Desmaiou: perde dinheiro e acorda com menos energia
		var penalty_gold := mini(1000, InventorySystem.gold / 10)
		InventorySystem.spend_gold(penalty_gold)
		# Energia restaurada parcialmente
		EventBus.player_energy_changed.emit(
			Constants.DEFAULT_MAX_ENERGY * 0.5,
			Constants.DEFAULT_MAX_ENERGY
		)
	else:
		# Dormiu normalmente: energia total
		EventBus.player_energy_changed.emit(
			float(Constants.DEFAULT_MAX_ENERGY),
			float(Constants.DEFAULT_MAX_ENERGY)
		)
	
	# 6. Salvar automaticamente
	if Constants.AUTOSAVE_ENABLED:
		save_game()
	
	# 7. Emitir sinal de novo dia
	EventBus.day_started.emit(
		TimeSystem.current_day,
		TimeSystem.current_season,
		TimeSystem.current_year
	)
	
	# 8. Voltar ao jogo
	_change_state(Constants.GameState.PLAYING)
	
	print("[GameManager] Novo dia: Dia %d, %s, Ano %d | Clima: %s" % [
		TimeSystem.current_day,
		Constants.SEASON_NAMES[TimeSystem.current_season],
		TimeSystem.current_year,
		Constants.Weather.keys()[WeatherSystem.current_weather]
	])


func _on_player_slept() -> void:
	_process_day_transition(false)


func _on_player_passed_out(reason: String) -> void:
	print("[GameManager] Jogador desmaiou: %s" % reason)
	_process_day_transition(true)


# =============================================================================
# QUIT
# =============================================================================

## Sai do jogo para o menu principal.
func quit_to_menu() -> void:
	is_game_running = false
	LocationManager.unload_current_location()
	DatabaseManager.close_database()
	_change_state(Constants.GameState.MAIN_MENU)


## Sai do jogo completamente.
func quit_game() -> void:
	if is_game_running and Constants.AUTOSAVE_ENABLED:
		save_game()
	get_tree().quit()
