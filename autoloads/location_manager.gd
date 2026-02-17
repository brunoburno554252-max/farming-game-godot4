## autoloads/location_manager.gd
## LocationManager — Gerencia carregamento/descarregamento de GameLocations.
## Cada location é uma cena que herda de GameLocation (base class).
## Lida com cache, loading async, e registro de warps.
extends Node


# =============================================================================
# STATE
# =============================================================================

## Location atualmente carregada
var current_location_id: String = ""
var current_location_node: Node = null

## Container onde as locations são instanciadas (definido pelo main.tscn)
var _location_container: Node = null

## Cache de locations visitadas (mantidas em memória para reentrada rápida)
var _location_cache: Dictionary = {}

## Registro de cenas: { location_id: scene_path }
var _location_scenes: Dictionary = {
	Constants.LOCATION_FARM: "res://locations/farm/farm.tscn",
	Constants.LOCATION_FARMHOUSE: "res://locations/house/farmhouse.tscn",
	Constants.LOCATION_TOWN: "res://locations/town/town.tscn",
	Constants.LOCATION_BEACH: "res://locations/town/beach.tscn",
	Constants.LOCATION_MOUNTAIN: "res://locations/town/mountain.tscn",
	Constants.LOCATION_FOREST: "res://locations/town/forest.tscn",
	Constants.LOCATION_GENERAL_STORE: "res://locations/shop/general_store.tscn",
	Constants.LOCATION_BLACKSMITH: "res://locations/shop/blacksmith.tscn",
	Constants.LOCATION_MINE: "res://locations/mine/mine.tscn",
	Constants.LOCATION_SALOON: "res://locations/town/saloon.tscn",
}

## Registro global de warps: { "from_location:tile_x,tile_y": WarpData }
var _warp_registry: Dictionary = {}

## Locations sendo carregadas em background (evitar duplicatas)
var _loading_locations: Array[String] = []


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	pass


func set_location_container(container: Node) -> void:
	_location_container = container


# =============================================================================
# LOCATION LOADING
# =============================================================================

## Carrega uma location. Retorna quando a location está pronta.
## Se a location já está no cache, reutiliza.
func load_location(location_id: String) -> void:
	if not _location_scenes.has(location_id):
		push_error("[LocationManager] Location '%s' não registrada!" % location_id)
		return
	
	if location_id in _loading_locations:
		push_warning("[LocationManager] Location '%s' já está sendo carregada." % location_id)
		return
	
	_loading_locations.append(location_id)
	
	# Descarregar location atual (remove da árvore mas mantém no cache)
	if current_location_node:
		_deactivate_current_location()
	
	# Carregar ou reativar
	if _location_cache.has(location_id):
		# Reativar do cache
		current_location_node = _location_cache[location_id]
		_activate_location(location_id)
	else:
		# Carregar do disco
		await _load_location_from_disk(location_id)
	
	_loading_locations.erase(location_id)
	
	current_location_id = location_id
	EventBus.location_ready.emit(location_id)


## Carrega a cena do disco e instancia.
func _load_location_from_disk(location_id: String) -> void:
	var scene_path: String = _location_scenes[location_id]
	
	if not ResourceLoader.exists(scene_path):
		push_error("[LocationManager] Cena não encontrada: %s" % scene_path)
		return
	
	# Carregar a cena (sync por enquanto, async na otimização mobile)
	var scene := load(scene_path) as PackedScene
	if not scene:
		push_error("[LocationManager] Falha ao carregar cena: %s" % scene_path)
		return
	
	current_location_node = scene.instantiate()
	_location_cache[location_id] = current_location_node
	_activate_location(location_id)
	
	# Se a location é um GameLocation, inicializar
	if current_location_node.has_method("on_first_load"):
		current_location_node.on_first_load()


## Coloca a location na árvore de cena.
func _activate_location(location_id: String) -> void:
	if current_location_node and _location_container:
		if not current_location_node.is_inside_tree():
			_location_container.add_child(current_location_node)
		current_location_node.visible = true
		current_location_node.process_mode = Node.PROCESS_MODE_INHERIT
		
		# Notificar a location que foi (re)ativada
		if current_location_node.has_method("on_activated"):
			current_location_node.on_activated()


## Remove a location atual da árvore (sem destruir, fica no cache).
func _deactivate_current_location() -> void:
	if not current_location_node:
		return
	
	# Notificar que será desativada
	if current_location_node.has_method("on_deactivated"):
		current_location_node.on_deactivated()
	
	# Remover da árvore mas manter referência no cache
	if current_location_node.is_inside_tree():
		current_location_node.get_parent().remove_child(current_location_node)
	
	current_location_id = ""
	current_location_node = null


# =============================================================================
# WARP REGISTRY
# =============================================================================

## Registra um warp point. Chamado pelas locations ao serem carregadas.
## [param from_location] ID da location de origem.
## [param from_tile] Tile que ativa o warp.
## [param target_location] ID da location destino.
## [param target_position] Posição de spawn no destino (em pixels).
## [param target_direction] Direção do jogador ao chegar.
func register_warp(
	from_location: String,
	from_tile: Vector2i,
	target_location: String,
	target_position: Vector2,
	target_direction: Constants.Direction = Constants.Direction.DOWN
) -> void:
	var key := "%s:%d,%d" % [from_location, from_tile.x, from_tile.y]
	_warp_registry[key] = {
		"target_location": target_location,
		"target_position": target_position,
		"target_direction": target_direction,
	}


## Checa se um tile tem um warp point registrado.
func check_warp(location_id: String, tile_pos: Vector2i) -> Dictionary:
	var key := "%s:%d,%d" % [location_id, tile_pos.x, tile_pos.y]
	if _warp_registry.has(key):
		return _warp_registry[key]
	return {}


## Remove todos os warps de uma location.
func clear_warps_for_location(location_id: String) -> void:
	var to_remove: Array[String] = []
	for key in _warp_registry.keys():
		if (key as String).begins_with(location_id + ":"):
			to_remove.append(key)
	for key in to_remove:
		_warp_registry.erase(key)


# =============================================================================
# QUERIES
# =============================================================================

## Retorna a location atual como GameLocation (ou null se não for).
func get_current_game_location() -> Node:
	return current_location_node


## Verifica se uma location existe no registro.
func has_location(location_id: String) -> bool:
	return _location_scenes.has(location_id)


## Registra uma nova location (para mods/expansões).
func register_location(location_id: String, scene_path: String) -> void:
	_location_scenes[location_id] = scene_path


# =============================================================================
# PERSISTENCE
# =============================================================================

## Salva o estado de todas as locations cacheadas que implementam save.
func save_all_locations() -> void:
	for loc_id in _location_cache:
		var loc_node: Node = _location_cache[loc_id]
		if loc_node.has_method("save_location_data"):
			loc_node.save_location_data()


## Carrega o estado de uma location do banco.
func load_location_data(location_id: String) -> void:
	if _location_cache.has(location_id):
		var loc_node: Node = _location_cache[location_id]
		if loc_node.has_method("load_location_data"):
			loc_node.load_location_data()


# =============================================================================
# CACHE MANAGEMENT
# =============================================================================

## Limpa o cache completamente (ao voltar pro menu, por exemplo).
## Descarrega a location atual e limpa referências.
func unload_current_location() -> void:
	_deactivate_current_location()
	current_location_id = ""
	current_location_node = null


func clear_cache() -> void:
	for loc in _location_cache.values():
		if loc is Node:
			loc.queue_free()
	_location_cache.clear()
	_warp_registry.clear()
	current_location_id = ""
	current_location_node = null


## Remove locations do cache que não foram visitadas recentemente.
## Útil para economia de memória em mobile.
func trim_cache(keep_ids: Array[String] = []) -> void:
	# Sempre manter a location atual
	if current_location_id:
		if current_location_id not in keep_ids:
			keep_ids.append(current_location_id)
	
	var to_remove: Array[String] = []
	for loc_id in _location_cache:
		if loc_id not in keep_ids:
			to_remove.append(loc_id)
	
	for loc_id in to_remove:
		var node: Node = _location_cache[loc_id]
		if node.is_inside_tree():
			node.get_parent().remove_child(node)
		node.queue_free()
		_location_cache.erase(loc_id)
