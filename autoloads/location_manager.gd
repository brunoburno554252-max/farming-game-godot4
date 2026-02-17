## autoloads/location_manager.gd
## LocationManager — Gerencia carregamento/descarregamento de locations (cenas do mundo).
## Equivalente ao sistema de GameLocation do Stardew Valley.
## SERÁ EXPANDIDO NA ETAPA 6.
extends Node

## Location atualmente carregada
var current_location_id: String = ""
var current_location_node: Node = null

## Container onde as locations são instanciadas
var _location_container: Node = null

## Cache de locations já visitadas (para não recarregar toda vez)
var _location_cache: Dictionary = {}

## Registro de cenas de location: { location_id: "res://locations/..." }
var _location_scenes: Dictionary = {
	Constants.LOCATION_FARM: "res://locations/farm/farm.tscn",
	Constants.LOCATION_FARMHOUSE: "res://locations/house/farmhouse.tscn",
	Constants.LOCATION_TOWN: "res://locations/town/town.tscn",
	Constants.LOCATION_BEACH: "res://locations/town/beach.tscn",
	Constants.LOCATION_GENERAL_STORE: "res://locations/shop/general_store.tscn",
	Constants.LOCATION_MINE: "res://locations/mine/mine.tscn",
	Constants.LOCATION_SALOON: "res://locations/town/saloon.tscn",
}


func _ready() -> void:
	# O container será definido pela cena principal (main.tscn)
	pass


## Define o nó container onde as locations serão colocadas.
func set_location_container(container: Node) -> void:
	_location_container = container


## Carrega uma location pelo ID. Faz transição com fade.
func load_location(location_id: String, spawn_point: String = "default") -> void:
	if not _location_scenes.has(location_id):
		push_error("[LocationManager] Location '%s' não registrada!" % location_id)
		return
	
	var from_location := current_location_id
	EventBus.scene_transition_started.emit(from_location, location_id)
	
	# Descarregar location atual
	if current_location_node:
		unload_current_location()
	
	# Carregar nova location
	var scene_path: String = _location_scenes[location_id]
	
	if _location_cache.has(location_id):
		current_location_node = _location_cache[location_id]
	else:
		if not ResourceLoader.exists(scene_path):
			push_error("[LocationManager] Cena não encontrada: %s" % scene_path)
			return
		var scene := load(scene_path) as PackedScene
		if scene:
			current_location_node = scene.instantiate()
			_location_cache[location_id] = current_location_node
	
	if current_location_node and _location_container:
		_location_container.add_child(current_location_node)
	
	current_location_id = location_id
	
	EventBus.scene_transition_completed.emit(location_id)
	EventBus.location_ready.emit(location_id)
	print("[LocationManager] Location carregada: %s" % location_id)


## Descarrega a location atual (remove da árvore, mas mantém no cache).
func unload_current_location() -> void:
	if current_location_node and current_location_node.get_parent():
		current_location_node.get_parent().remove_child(current_location_node)
	current_location_id = ""
	current_location_node = null


## Registra uma nova location (para expansibilidade/mods).
func register_location(location_id: String, scene_path: String) -> void:
	_location_scenes[location_id] = scene_path


## Salva o estado de todas as locations que foram visitadas.
func save_all_locations() -> void:
	pass  # Etapa 3 — cada location serializa seus terrain_features e objects


## Limpa o cache (usado ao voltar pro menu).
func clear_cache() -> void:
	for loc in _location_cache.values():
		if loc is Node:
			loc.queue_free()
	_location_cache.clear()
