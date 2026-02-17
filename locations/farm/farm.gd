## locations/farm/farm.gd
## Farm — A fazenda principal do jogador.
## Herda de GameLocation. Área onde o jogador planta, cria animais, coloca objetos.
##
## Particularidades:
## - Define quais tiles são "tillable" (podem ser arados)
## - Warp points para Farmhouse, Town, e outras locations
## - Processa sprinklers automaticamente no início do dia
## - Área de shipping bin para vender itens
extends GameLocation


# =============================================================================
# CONFIGURATION
# =============================================================================

## Tiles que podem ser arados (definidos no TileMap como custom data)
## Na prática, será lido do TileMap. Aqui definimos a área base.
var _tillable_tiles: Dictionary = {}  # { Vector2i: true }

## Posição do shipping bin (tile)
@export var shipping_bin_tile: Vector2i = Vector2i(71, 14)

## Itens no shipping bin (serão vendidos ao final do dia)
var shipping_bin: Array[Dictionary] = []


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	location_id = Constants.LOCATION_FARM
	default_music = "farm_day"
	is_indoors = false
	time_passes = true


func _setup_warps() -> void:
	# Warp: Farm → Farmhouse (porta da casa)
	add_warp(
		Vector2i(64, 15),  # Tile da porta
		Constants.LOCATION_FARMHOUSE,
		Vector2(
			6 * Constants.TILE_SIZE + Constants.TILE_SIZE / 2,
			11 * Constants.TILE_SIZE
		),
		Constants.Direction.UP
	)
	
	# Warp: Farm → Town (saída sul da fazenda)
	add_warp(
		Vector2i(79, 39),
		Constants.LOCATION_TOWN,
		Vector2(
			32 * Constants.TILE_SIZE + Constants.TILE_SIZE / 2,
			1 * Constants.TILE_SIZE
		),
		Constants.Direction.DOWN
	)


func _setup_initial_content() -> void:
	# Definir área tillable base da fazenda
	# Em um jogo real, isso viria do TileMap custom data
	# Aqui definimos uma área retangular como placeholder
	_define_tillable_area(
		Vector2i(30, 10),  # Canto superior esquerdo
		Vector2i(70, 35)   # Canto inferior direito
	)


# =============================================================================
# TILLABLE AREA
# =============================================================================

func _define_tillable_area(from: Vector2i, to: Vector2i) -> void:
	for x in range(from.x, to.x + 1):
		for y in range(from.y, to.y + 1):
			_tillable_tiles[Vector2i(x, y)] = true


## Override: Define se um tile pode ser arado.
func is_tile_tillable(tile_pos: Vector2i) -> bool:
	if not _tillable_tiles.has(tile_pos):
		return false
	# Não pode arar se já tem terrain feature ou objeto
	if terrain_features.has(tile_pos):
		return false
	if placed_objects.has(tile_pos):
		return false
	return true


# =============================================================================
# FARMING ACTIONS
# =============================================================================

## Cria um HoeDirt num tile (jogador usou enxada).
func till_soil(tile_pos: Vector2i) -> bool:
	if not is_tile_tillable(tile_pos):
		return false
	
	var dirt := HoeDirt.new()
	add_terrain_feature(tile_pos, dirt)
	EventBus.soil_tilled.emit(location_id, tile_pos)
	return true


# =============================================================================
# SHIPPING BIN
# =============================================================================

## Adiciona um item ao shipping bin para ser vendido no final do dia.
func add_to_shipping_bin(item_id: String, quantity: int, quality: Constants.ItemQuality) -> void:
	shipping_bin.append({
		"item_id": item_id,
		"quantity": quantity,
		"quality": quality,
	})


## Processa a venda de todos os itens no shipping bin.
## Retorna o total ganho.
func process_shipping_bin() -> int:
	var total_gold := 0
	
	for item in shipping_bin:
		# Calcular preço (será integrado com ItemData na Fase 3)
		var base_price := 0  # ItemDatabase.get_sell_price(item.item_id)
		var quality_mult: float = Constants.QUALITY_PRICE_MULTIPLIER.get(
			item.quality, 1.0
		)
		total_gold += int(base_price * quality_mult) * item.quantity
	
	shipping_bin.clear()
	return total_gold


# =============================================================================
# DAY PROCESSING
# =============================================================================

func _on_enter() -> void:
	# Ajustar música baseado no horário
	if TimeSystem.is_night():
		EventBus.change_music.emit("farm_night", 1.5)
	else:
		EventBus.change_music.emit("farm_day", 1.5)


## Override para processar sprinklers antes do crescimento de plantas.
func process_day_transition() -> void:
	# 1. Processar sprinklers (regam tiles adjacentes)
	_process_sprinklers()
	
	# 2. Processar chuva
	if WeatherSystem.is_raining():
		_auto_water_from_rain()
	
	# 3. Processar terrain features (crescimento)
	for tile_pos in terrain_features:
		var feature: Node2D = terrain_features[tile_pos]
		if feature.has_method("on_new_day"):
			feature.on_new_day()
	
	# 4. Processar objetos
	for tile_pos in placed_objects:
		var obj: Node2D = placed_objects[tile_pos]
		if obj.has_method("on_new_day"):
			obj.on_new_day()
	
	# 5. Processar shipping bin
	var gold_earned := process_shipping_bin()
	if gold_earned > 0:
		InventorySystem.earn_gold(gold_earned)


## Processa sprinklers: rega os tiles ao redor.
func _process_sprinklers() -> void:
	for tile_pos in placed_objects:
		var obj: Node2D = placed_objects[tile_pos]
		if obj.has_method("get_sprinkler_range"):
			var sprinkler_range: Array = obj.get_sprinkler_range()
			for offset in sprinkler_range:
				var target_tile: Vector2i = tile_pos + offset
				if terrain_features.has(target_tile):
					var feature: Node2D = terrain_features[target_tile]
					if feature.has_method("water"):
						feature.water()
