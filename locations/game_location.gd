## locations/game_location.gd
## GameLocation — Classe base para todas as locations do jogo.
## Equivalente ao GameLocation do Stardew Valley.
## Cada location (Farm, Town, Mine, etc.) herda desta classe.
##
## Uma GameLocation contém:
## - TileMapLayer para o mapa visual
## - Dictionary de TerrainFeatures (HoeDirt, Tree, Grass, Bush)
## - Dictionary de PlacedObjects (Sprinklers, Chests, Machines)
## - Array de NPCs presentes
## - Array de WarpPoints
##
## COMO USAR:
## 1. Crie uma cena com root Node2D
## 2. Attach este script (ou um que herda dele)
## 3. Adicione TileMapLayers como filhos
## 4. Override _setup_warps() e _setup_initial_content() conforme necessário
class_name GameLocation
extends Node2D


# =============================================================================
# EXPORTS
# =============================================================================

## ID único desta location (deve corresponder ao registrado no LocationManager)
@export var location_id: String = ""

## Se o tempo passa nesta location
@export var time_passes: bool = true

## Música padrão desta location (nome do audio no AudioManager)
@export var default_music: String = ""

## Se está dentro de uma construção (renderiza diferente, sem clima visual)
@export var is_indoors: bool = false


# =============================================================================
# TERRAIN FEATURES
# =============================================================================

## Dictionary de terrain features: { Vector2i: TerrainFeature }
## TerrainFeatures são: HoeDirt, Tree, Grass, Bush, etc.
var terrain_features: Dictionary = {}


# =============================================================================
# PLACED OBJECTS
# =============================================================================

## Dictionary de objetos colocados pelo jogador: { Vector2i: PlacedObject }
## PlacedObjects são: Sprinklers, Chests, Kegs, Furnaces, etc.
var placed_objects: Dictionary = {}


# =============================================================================
# NPCs
# =============================================================================

## NPCs atualmente presentes nesta location
var npcs_present: Array[Node] = []


# =============================================================================
# WARP POINTS
# =============================================================================

## Warp points desta location (tiles que levam a outras locations)
var warp_points: Array[Dictionary] = []


# =============================================================================
# MAP LAYERS
# =============================================================================

## Referências aos TileMapLayers (configuradas em _ready)
var _ground_layer: TileMapLayer = null
var _paths_layer: TileMapLayer = null
var _buildings_layer: TileMapLayer = null
var _above_player_layer: TileMapLayer = null

## Container para terrain features visuais
var _terrain_container: Node2D = null

## Container para objetos colocados
var _objects_container: Node2D = null

## Container para NPCs
var _npc_container: Node2D = null


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Buscar layers existentes por nome (convenção)
	_ground_layer = get_node_or_null("GroundLayer") as TileMapLayer
	_paths_layer = get_node_or_null("PathsLayer") as TileMapLayer
	_buildings_layer = get_node_or_null("BuildingsLayer") as TileMapLayer
	_above_player_layer = get_node_or_null("AbovePlayerLayer") as TileMapLayer
	
	# Criar containers se não existirem
	_terrain_container = _get_or_create_child("TerrainFeatures", Node2D)
	_objects_container = _get_or_create_child("PlacedObjects", Node2D)
	_npc_container = _get_or_create_child("NPCs", Node2D)
	
	# Registrar tempo pausado se necessário
	if not time_passes and location_id != "":
		TimeSystem.register_time_paused_location(location_id)
	
	_setup_warps()


## Chamado na primeira vez que a location é carregada.
func on_first_load() -> void:
	_setup_initial_content()


## Chamado quando a location é ativada (jogador entra).
func on_activated() -> void:
	# Trocar música
	if default_music != "":
		EventBus.change_music.emit(default_music, 1.0)
	
	_on_enter()


## Chamado quando a location é desativada (jogador sai).
func on_deactivated() -> void:
	_on_exit()


# =============================================================================
# OVERRIDE POINTS (para classes filhas)
# =============================================================================

## Override para definir os warp points desta location.
func _setup_warps() -> void:
	pass


## Override para colocar conteúdo inicial (trees, grass, etc.).
func _setup_initial_content() -> void:
	pass


## Override para lógica ao entrar na location.
func _on_enter() -> void:
	pass


## Override para lógica ao sair da location.
func _on_exit() -> void:
	pass


# =============================================================================
# WARP MANAGEMENT
# =============================================================================

## Adiciona um warp point e registra no LocationManager.
func add_warp(
	from_tile: Vector2i,
	target_location: String,
	target_position: Vector2,
	target_direction: Constants.Direction = Constants.Direction.DOWN
) -> void:
	var warp_data := {
		"from_tile": from_tile,
		"target_location": target_location,
		"target_position": target_position,
		"target_direction": target_direction,
	}
	warp_points.append(warp_data)
	LocationManager.register_warp(
		location_id, from_tile, target_location, target_position, target_direction
	)


# =============================================================================
# TERRAIN FEATURES
# =============================================================================

## Adiciona um terrain feature num tile.
func add_terrain_feature(tile_pos: Vector2i, feature: Node2D) -> bool:
	if terrain_features.has(tile_pos):
		return false  # Já tem algo nesse tile
	
	terrain_features[tile_pos] = feature
	feature.position = tile_to_world(tile_pos)
	_terrain_container.add_child(feature)
	return true


## Remove um terrain feature de um tile.
func remove_terrain_feature(tile_pos: Vector2i) -> Node2D:
	if not terrain_features.has(tile_pos):
		return null
	
	var feature: Node2D = terrain_features[tile_pos]
	terrain_features.erase(tile_pos)
	_terrain_container.remove_child(feature)
	return feature


## Retorna o terrain feature de um tile (ou null).
func get_terrain_feature(tile_pos: Vector2i) -> Node2D:
	return terrain_features.get(tile_pos, null)


## Verifica se um tile tem um terrain feature.
func has_terrain_feature(tile_pos: Vector2i) -> bool:
	return terrain_features.has(tile_pos)


# =============================================================================
# PLACED OBJECTS
# =============================================================================

## Coloca um objeto num tile.
func place_object(tile_pos: Vector2i, object_node: Node2D) -> bool:
	if placed_objects.has(tile_pos):
		return false
	if terrain_features.has(tile_pos):
		return false  # Não pode colocar objeto onde tem terrain feature
	
	placed_objects[tile_pos] = object_node
	object_node.position = tile_to_world(tile_pos)
	_objects_container.add_child(object_node)
	
	EventBus.object_placed.emit(location_id, tile_pos, "")
	return true


## Remove um objeto de um tile.
func remove_object(tile_pos: Vector2i) -> Node2D:
	if not placed_objects.has(tile_pos):
		return null
	
	var obj: Node2D = placed_objects[tile_pos]
	placed_objects.erase(tile_pos)
	_objects_container.remove_child(obj)
	
	EventBus.object_removed.emit(location_id, tile_pos, "")
	return obj


func get_placed_object(tile_pos: Vector2i) -> Node2D:
	return placed_objects.get(tile_pos, null)


func has_placed_object(tile_pos: Vector2i) -> bool:
	return placed_objects.has(tile_pos)


# =============================================================================
# TILE QUERIES
# =============================================================================

## Verifica se um tile está livre (sem terrain feature, sem objeto, e passável).
func is_tile_free(tile_pos: Vector2i) -> bool:
	if terrain_features.has(tile_pos):
		return false
	if placed_objects.has(tile_pos):
		return false
	# Verificar se o tile é walkable no mapa
	if not is_tile_passable(tile_pos):
		return false
	return true


## Verifica se o tile é passável (não tem colisão no tilemap).
## Override em subclasses para lógica custom.
func is_tile_passable(tile_pos: Vector2i) -> bool:
	# Por padrão, tiles sem dados no ground layer são impassáveis
	if _ground_layer:
		var source_id := _ground_layer.get_cell_source_id(tile_pos)
		return source_id != -1  # -1 = tile vazio
	return true


## Retorna se um tile é "tillable" (pode ser arado pela enxada).
## Override na Farm location para definir área arável.
func is_tile_tillable(tile_pos: Vector2i) -> bool:
	return false


## Retorna se um tile é "waterable" (pode plantar/regar).
func is_tile_waterable(tile_pos: Vector2i) -> bool:
	if not terrain_features.has(tile_pos):
		return false
	var feature = terrain_features[tile_pos]
	return feature.has_method("water")


# =============================================================================
# COORDINATE CONVERSION
# =============================================================================

## Converte coordenada de tile para posição no mundo (centro do tile).
func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(
		tile_pos.x * Constants.TILE_SIZE + Constants.TILE_SIZE / 2,
		tile_pos.y * Constants.TILE_SIZE + Constants.TILE_SIZE / 2
	)


## Converte posição no mundo para coordenada de tile.
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x) / Constants.TILE_SIZE,
		int(world_pos.y) / Constants.TILE_SIZE
	)


# =============================================================================
# DAY PROCESSING
# =============================================================================

## Processa o fim do dia para todos os terrain features e objetos.
## Chamado pelo GameManager via EventBus.day_transition_process.
func process_day_transition() -> void:
	# Processar terrain features (crescimento de plantas, etc.)
	for tile_pos in terrain_features:
		var feature: Node2D = terrain_features[tile_pos]
		if feature.has_method("on_new_day"):
			feature.on_new_day()
	
	# Processar objetos colocados (keg, furnace, etc.)
	for tile_pos in placed_objects:
		var obj: Node2D = placed_objects[tile_pos]
		if obj.has_method("on_new_day"):
			obj.on_new_day()
	
	# Se está chovendo, regar todos os HoeDirt
	if not is_indoors and WeatherSystem.is_raining():
		_auto_water_from_rain()


## Rega automaticamente todos os HoeDirt quando chove.
func _auto_water_from_rain() -> void:
	for tile_pos in terrain_features:
		var feature: Node2D = terrain_features[tile_pos]
		if feature.has_method("water"):
			feature.water()


# =============================================================================
# PERSISTENCE
# =============================================================================

## Salva todos os dados desta location no banco.
func save_location_data() -> void:
	# Salvar terrain features
	for tile_pos in terrain_features:
		var feature: Node2D = terrain_features[tile_pos]
		if feature.has_method("save_data"):
			feature.save_data(location_id, tile_pos)
	
	# Salvar objetos colocados
	for tile_pos in placed_objects:
		var obj: Node2D = placed_objects[tile_pos]
		if obj.has_method("save_data"):
			obj.save_data(location_id, tile_pos)


## Carrega dados desta location do banco.
func load_location_data() -> void:
	_load_terrain_features()
	_load_placed_objects()


func _load_terrain_features() -> void:
	var results := DatabaseManager.query(
		"SELECT * FROM terrain_features WHERE location_id='%s';" % location_id
	)
	for row in results:
		var tile_pos := Vector2i(row["tile_x"], row["tile_y"])
		var feature_type: String = row.get("feature_type", "")
		# Feature factory — será implementado na Fase 3
		_create_terrain_feature_from_data(tile_pos, feature_type, row)


func _load_placed_objects() -> void:
	var results := DatabaseManager.query(
		"SELECT * FROM placed_objects WHERE location_id='%s';" % location_id
	)
	for row in results:
		var tile_pos := Vector2i(row["tile_x"], row["tile_y"])
		var object_type: String = row.get("object_id", "")
		_create_placed_object_from_data(tile_pos, object_type, row)


## Factory de terrain features a partir dos dados salvos.
## Será expandido na Fase 3 com cada tipo de feature.
func _create_terrain_feature_from_data(
	tile_pos: Vector2i, feature_type: String, data: Dictionary
) -> void:
	pass  # Implementar na Fase 3 (HoeDirt, Tree, etc.)


## Factory de placed objects a partir dos dados salvos.
func _create_placed_object_from_data(
	tile_pos: Vector2i, object_type: String, data: Dictionary
) -> void:
	pass  # Implementar na Fase 3 (Sprinkler, Chest, etc.)


# =============================================================================
# HELPERS
# =============================================================================

func _get_or_create_child(child_name: String, child_type: Variant) -> Node:
	var existing := get_node_or_null(child_name)
	if existing:
		return existing
	var new_node: Node = child_type.new()
	new_node.name = child_name
	add_child(new_node)
	return new_node
