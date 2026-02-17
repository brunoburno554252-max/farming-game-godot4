## terrain_features/hoe_dirt.gd
## HoeDirt — Solo arado que contém uma planta (Crop).
## Equivalente EXATO ao HoeDirt do Stardew Valley.
##
## Responsabilidades:
## - Manter o estado do solo (tilled, watered)
## - Conter um Crop opcional
## - Manter o tipo de fertilizante aplicado
## - Processar transição de dia (secar, avisar crop para crescer)
## - Serializar/deserializar para o banco de dados
##
## No Stardew Valley, HoeDirt é o ÚNICO lugar onde plantas crescem.
## O solo é criado quando o jogador usa a enxada, e a semente é plantada nele.
class_name HoeDirt
extends TerrainFeature


# =============================================================================
# STATE
# =============================================================================

## Estado atual do solo
var soil_state: Constants.SoilState = Constants.SoilState.TILLED

## Fertilizante aplicado (NONE = sem fertilizante)
var fertilizer: Constants.FertilizerType = Constants.FertilizerType.NONE

## Referência ao Crop plantado (null = solo vazio)
var crop: Node2D = null  # Será do tipo Crop na Fase 3

## Dias sem regar (se > MAX, o solo volta ao estado natural)
var days_without_water: int = 0

## Máximo de dias sem regar antes do solo sumir
const MAX_DAYS_DRY: int = 4

## Se o solo foi regado hoje (reseta no início do dia)
var _watered_today: bool = false


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	feature_type = "hoe_dirt"
	blocks_movement = false
	is_destructible = true


func _setup_visual() -> void:
	# Criar sprite do solo (será substituído por atlas na Fase 3)
	_sprite = Sprite2D.new()
	_sprite.name = "SoilSprite"
	add_child(_sprite)
	_update_visual()


# =============================================================================
# WATERING
# =============================================================================

## Rega o solo. Chamado pelo jogador (regador) ou pela chuva.
func water() -> void:
	if soil_state == Constants.SoilState.TILLED:
		soil_state = Constants.SoilState.WATERED
		_watered_today = true
		days_without_water = 0
		_update_visual()


## Retorna se o solo está regado.
func is_watered() -> bool:
	return soil_state == Constants.SoilState.WATERED


# =============================================================================
# PLANTING
# =============================================================================

## Planta uma semente neste solo.
## Retorna true se a semente foi plantada com sucesso.
func plant(crop_node: Node2D) -> bool:
	if crop != null:
		return false  # Já tem planta
	if soil_state == Constants.SoilState.UNTILLED:
		return false  # Solo não arado
	
	crop = crop_node
	add_child(crop_node)
	return true


## Remove a planta (colheita ou morte).
func remove_crop() -> Node2D:
	if crop == null:
		return null
	
	var removed := crop
	remove_child(crop)
	crop = null
	return removed


## Retorna se pode plantar aqui.
func can_plant() -> bool:
	return crop == null and soil_state != Constants.SoilState.UNTILLED


## Retorna se tem uma planta.
func has_crop() -> bool:
	return crop != null


# =============================================================================
# FERTILIZER
# =============================================================================

## Aplica fertilizante. Só funciona antes de plantar ou no solo vazio.
func apply_fertilizer(type: Constants.FertilizerType) -> bool:
	if fertilizer != Constants.FertilizerType.NONE:
		return false  # Já tem fertilizante
	
	fertilizer = type
	_update_visual()
	return true


## Retorna o multiplicador de velocidade de crescimento do fertilizante.
func get_speed_multiplier() -> float:
	match fertilizer:
		Constants.FertilizerType.SPEED_GRO:
			return 0.90  # 10% mais rápido
		Constants.FertilizerType.DELUXE_SPEED:
			return 0.75  # 25% mais rápido
		Constants.FertilizerType.HYPER_SPEED:
			return 0.67  # 33% mais rápido
	return 1.0


## Retorna o bonus de qualidade do fertilizante (0.0 a 1.0).
func get_quality_bonus() -> float:
	match fertilizer:
		Constants.FertilizerType.BASIC:
			return 0.1
		Constants.FertilizerType.QUALITY:
			return 0.25
		Constants.FertilizerType.DELUXE:
			return 0.5
	return 0.0


# =============================================================================
# TOOL INTERACTION
# =============================================================================

func on_tool_use(tool_type: Constants.ToolType, tool_level: Constants.ToolLevel) -> bool:
	match tool_type:
		Constants.ToolType.WATERING_CAN:
			if soil_state == Constants.SoilState.TILLED:
				water()
				return true
		
		Constants.ToolType.PICKAXE:
			# Picareta destrói o solo arado (e a planta, se tiver)
			if crop:
				remove_crop()
			_destroy()
			return true
		
		Constants.ToolType.SCYTHE:
			# Foice colhe a planta se estiver pronta
			if crop and crop.has_method("is_ready_to_harvest"):
				if crop.is_ready_to_harvest():
					return true  # A colheita é processada pelo CropSystem
	
	return false


func _destroy() -> void:
	soil_state = Constants.SoilState.UNTILLED
	fertilizer = Constants.FertilizerType.NONE
	# Notificar a GameLocation para nos remover
	# (feito via signal ou pelo sistema de farming)


# =============================================================================
# DAY PROCESSING
# =============================================================================

func on_new_day() -> void:
	if soil_state == Constants.SoilState.WATERED:
		# Solo seca no início do novo dia
		soil_state = Constants.SoilState.TILLED
		_watered_today = false
		
		# Processar crescimento da planta
		if crop and crop.has_method("grow"):
			crop.grow(self)
	else:
		# Solo não foi regado
		days_without_water += 1
		
		if crop and crop.has_method("on_day_without_water"):
			crop.on_day_without_water()
		
		# Se ficou muito tempo sem regar e não tem planta, o solo volta ao normal
		if crop == null and days_without_water >= MAX_DAYS_DRY:
			_destroy()
	
	_update_visual()


func on_season_change(new_season: Constants.Season) -> void:
	# Ao mudar de estação, plantas de estação errada morrem
	if crop and crop.has_method("check_season"):
		if not crop.check_season(new_season):
			# Planta morreu (estação errada)
			crop.queue_free()
			crop = null


# =============================================================================
# VISUAL
# =============================================================================

func _update_visual() -> void:
	if not _sprite:
		return
	
	# Placeholder: trocar cor baseado no estado
	# Na Fase 3 isso será substituído por texturas do tileset
	match soil_state:
		Constants.SoilState.TILLED:
			_sprite.modulate = Color(0.55, 0.35, 0.2)  # Marrom
		Constants.SoilState.WATERED:
			_sprite.modulate = Color(0.3, 0.2, 0.1)  # Marrom escuro (molhado)
		Constants.SoilState.UNTILLED:
			_sprite.modulate = Color(0.6, 0.5, 0.3)  # Bege
	
	# Indicador de fertilizante (cor sutil overlay)
	if fertilizer != Constants.FertilizerType.NONE:
		pass  # Adicionar overlay visual na Fase 3


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data(loc_id: String, tile_pos: Vector2i) -> void:
	var crop_id := ""
	var crop_phase := 0
	var crop_days := 0
	
	if crop and crop.has_method("get_crop_id"):
		crop_id = crop.get_crop_id()
	if crop and crop.has_method("get_current_phase"):
		crop_phase = crop.get_current_phase()
	if crop and crop.has_method("get_days_growing"):
		crop_days = crop.get_days_growing()
	
	# Upsert no terrain_features
	DatabaseManager.query(
		"INSERT OR REPLACE INTO terrain_features (location_id, tile_x, tile_y, feature_type, state, fertilizer) VALUES ('%s', %d, %d, 'hoe_dirt', %d, %d);" % [
			loc_id, tile_pos.x, tile_pos.y, int(soil_state), int(fertilizer)
		]
	)
	
	# Se tem crop, salvar na tabela crops
	if crop_id != "":
		DatabaseManager.query(
			"INSERT OR REPLACE INTO crops (location_id, tile_x, tile_y, crop_id, current_phase, days_growing, days_without_water) VALUES ('%s', %d, %d, '%s', %d, %d, %d);" % [
				loc_id, tile_pos.x, tile_pos.y, crop_id, crop_phase, crop_days, days_without_water
			]
		)


func load_from_data(data: Dictionary) -> void:
	soil_state = data.get("state", Constants.SoilState.TILLED) as Constants.SoilState
	fertilizer = data.get("fertilizer", Constants.FertilizerType.NONE) as Constants.FertilizerType
	days_without_water = data.get("days_without_water", 0)
	_update_visual()
