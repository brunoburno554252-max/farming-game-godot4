## terrain_features/crop.gd
## Crop — Planta que cresce dentro de um HoeDirt.
## Equivalente ao Crop do Stardew Valley.
##
## Ciclo de vida:
## 1. Semente plantada no HoeDirt → Crop criado na fase 0
## 2. HoeDirt regado → no novo dia, Crop.grow() avança a fase
## 3. Fase final atingida → pronta para colheita
## 4. Colhida → se regrows, volta para regrow_phase; senão, é destruída
class_name Crop
extends Node2D


# =============================================================================
# DATA
# =============================================================================

## Dados estáticos do tipo de crop (Resource)
var crop_data: CropData = null


# =============================================================================
# STATE
# =============================================================================

## Fase atual de crescimento (0 = semente, último = maduro)
var current_phase: int = 0

## Dias acumulados de crescimento na fase atual
var days_in_current_phase: int = 0

## Dias totais desde que foi plantado
var days_growing: int = 0

## Se já está pronta para colheita
var is_harvestable: bool = false

## Se está morta (por falta de água prolongada ou estação errada)
var is_dead: bool = false

## Dias consecutivos sem água
var days_without_water: int = 0

## Máximo de dias sem água antes de morrer
const MAX_DAYS_WITHOUT_WATER: int = 5


# =============================================================================
# VISUAL
# =============================================================================

var _sprite: Sprite2D = null


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "CropSprite"
	# Offset para que a base da planta fique no centro do tile
	_sprite.offset = Vector2(0, -8)  # Plantas crescem "para cima"
	add_child(_sprite)
	_update_visual()


## Inicializa o crop com seus dados.
func initialize(data: CropData) -> void:
	crop_data = data
	current_phase = 0
	days_in_current_phase = 0
	days_growing = 0
	is_harvestable = false
	is_dead = false
	days_without_water = 0
	_update_visual()


# =============================================================================
# GROWTH
# =============================================================================

## Chamado pelo HoeDirt quando o solo foi regado e o novo dia começa.
## [param dirt] Referência ao HoeDirt pai (para acessar fertilizante).
func grow(dirt: HoeDirt) -> void:
	if is_dead or is_harvestable or not crop_data:
		return
	
	days_growing += 1
	days_in_current_phase += 1
	days_without_water = 0  # Foi regado
	
	# Verificar se avança de fase
	var days_needed := _get_phase_days(dirt)
	
	if days_in_current_phase >= days_needed:
		current_phase += 1
		days_in_current_phase = 0
		
		# Verificar se chegou à fase final (colheita)
		if current_phase >= crop_data.get_total_phases():
			current_phase = crop_data.get_total_phases() - 1
			is_harvestable = true
			
			# Emitir sinal de crop pronta
			var loc := _get_parent_location()
			if loc:
				var tile := _get_tile_position()
				EventBus.crop_ready_to_harvest.emit(loc, tile, crop_data.id)
		else:
			# Emitir sinal de crescimento
			var loc := _get_parent_location()
			if loc:
				var tile := _get_tile_position()
				EventBus.crop_grew.emit(loc, tile, current_phase)
	
	_update_visual()


## Chamado pelo HoeDirt quando o solo NÃO foi regado no dia.
func on_day_without_water() -> void:
	if is_dead or is_harvestable:
		return
	
	days_without_water += 1
	days_growing += 1
	
	# Planta não cresce sem água, mas também não morre imediatamente
	if days_without_water >= MAX_DAYS_WITHOUT_WATER:
		_die()


## Retorna os dias necessários para a fase atual, considerando fertilizante.
func _get_phase_days(dirt: HoeDirt) -> int:
	if current_phase >= crop_data.phase_days.size():
		return 999  # Já na fase final
	
	var base_days: int = crop_data.phase_days[current_phase]
	var speed_mult: float = dirt.get_speed_multiplier()
	
	# Aplicar multiplicador (arredondar para cima, mínimo 1)
	return maxi(1, ceili(base_days * speed_mult))


# =============================================================================
# HARVEST
# =============================================================================

## Retorna se está pronta para colheita.
func is_ready_to_harvest() -> bool:
	return is_harvestable and not is_dead


## Processa a colheita. Retorna dados do item colhido.
## [param farming_level] Nível de farming do jogador (afeta qualidade).
## [param fertilizer_bonus] Bonus de qualidade do fertilizante.
func harvest(farming_level: int = 0, fertilizer_bonus: float = 0.0) -> Dictionary:
	if not is_ready_to_harvest():
		return {}
	
	var amount := crop_data.calculate_harvest_amount(fertilizer_bonus)
	var quality := crop_data.calculate_harvest_quality(fertilizer_bonus, farming_level)
	
	var result := {
		"item_id": crop_data.harvest_item_id,
		"quantity": amount,
		"quality": quality,
		"xp": crop_data.harvest_xp,
	}
	
	# Verificar se a planta renasce
	if crop_data.regrows_after_harvest:
		# Voltar para a fase de regrow
		is_harvestable = false
		current_phase = crop_data.regrow_phase
		days_in_current_phase = 0
		_update_visual()
	else:
		# Planta colhida e destruída — será removida pelo HoeDirt/CropSystem
		pass
	
	return result


## Retorna se a planta renasce (ou se deve ser destruída após colheita).
func will_regrow() -> bool:
	return crop_data.regrows_after_harvest if crop_data else false


# =============================================================================
# SEASON CHECK
# =============================================================================

## Verifica se a planta pode crescer na estação dada.
## Retorna false se deve morrer (estação errada).
func check_season(season: Constants.Season) -> bool:
	if not crop_data:
		return false
	return crop_data.can_grow_in_season(season)


# =============================================================================
# DEATH
# =============================================================================

func _die() -> void:
	is_dead = true
	is_harvestable = false
	_update_visual()
	
	var loc := _get_parent_location()
	if loc:
		var tile := _get_tile_position()
		EventBus.crop_withered.emit(loc, tile)


# =============================================================================
# VISUAL
# =============================================================================

func _update_visual() -> void:
	if not _sprite or not crop_data:
		return
	
	if is_dead:
		# Visual de planta morta
		_sprite.modulate = Color(0.4, 0.35, 0.2, 0.8)
		return
	
	if crop_data.growth_spritesheet:
		_sprite.texture = crop_data.growth_spritesheet
		_sprite.region_enabled = true
		_sprite.region_rect = Rect2(
			current_phase * crop_data.frame_width, 0,
			crop_data.frame_width, crop_data.frame_height
		)
	
	# Modulate normal
	_sprite.modulate = Color.WHITE
	
	# Se está pronta para colheita, pode ter um leve "glow"
	if is_harvestable:
		_sprite.modulate = Color(1.05, 1.05, 0.95)


# =============================================================================
# QUERIES
# =============================================================================

func get_crop_id() -> String:
	return crop_data.id if crop_data else ""

func get_current_phase() -> int:
	return current_phase

func get_days_growing() -> int:
	return days_growing

func get_growth_percentage() -> float:
	if not crop_data:
		return 0.0
	var total := crop_data.get_total_grow_days()
	if total <= 0:
		return 1.0
	return clampf(float(days_growing) / float(total), 0.0, 1.0)


# =============================================================================
# HELPERS
# =============================================================================

func _get_parent_location() -> String:
	# Navegar: Crop → HoeDirt → TerrainContainer → GameLocation
	var dirt := get_parent()
	if dirt:
		var container := dirt.get_parent()
		if container:
			var location := container.get_parent()
			if location and location.has_method("is_tile_free"):
				return location.get("location_id")
	return ""

func _get_tile_position() -> Vector2i:
	var dirt := get_parent()
	if dirt:
		return Vector2i(
			int(dirt.position.x) / Constants.TILE_SIZE,
			int(dirt.position.y) / Constants.TILE_SIZE
		)
	return Vector2i.ZERO


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data(loc_id: String, tile_pos: Vector2i) -> void:
	if not crop_data:
		return
	DatabaseManager.query(
		"INSERT OR REPLACE INTO crops (location_id, tile_x, tile_y, crop_id, current_phase, days_in_phase, days_growing, days_without_water, is_dead) VALUES ('%s', %d, %d, '%s', %d, %d, %d, %d, %d);" % [
			loc_id, tile_pos.x, tile_pos.y, crop_data.id,
			current_phase, days_in_current_phase, days_growing,
			days_without_water, int(is_dead)
		]
	)


func load_from_data(data: Dictionary) -> void:
	current_phase = data.get("current_phase", 0)
	days_in_current_phase = data.get("days_in_phase", 0)
	days_growing = data.get("days_growing", 0)
	days_without_water = data.get("days_without_water", 0)
	is_dead = bool(data.get("is_dead", 0))
	
	# Verificar se já está na fase final
	if crop_data and current_phase >= crop_data.get_total_phases() - 1:
		is_harvestable = true
	
	_update_visual()
