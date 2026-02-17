## terrain_features/terrain_feature.gd
## TerrainFeature — Classe base para todos os features do terreno.
## Equivalente ao TerrainFeature do Stardew Valley.
## Subclasses: HoeDirt, Tree, Grass, Bush, Flooring.
##
## Um TerrainFeature ocupa um tile no mapa e pode:
## - Ser interagido com ferramentas (enxada, machado, etc.)
## - Processar transição de dia (crescimento, etc.)
## - Salvar/carregar estado no banco
class_name TerrainFeature
extends Node2D


# =============================================================================
# PROPERTIES
# =============================================================================

## Tipo de feature para serialização
@export var feature_type: String = "base"

## Se este feature bloqueia passagem do jogador
@export var blocks_movement: bool = false

## Se este feature pode ser destruído
@export var is_destructible: bool = true

## Sprite visual do feature
var _sprite: Sprite2D = null


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_setup_visual()


## Override para configurar o visual (sprite, animação, etc.)
func _setup_visual() -> void:
	pass


# =============================================================================
# INTERACTION
# =============================================================================

## Chamado quando o jogador usa uma ferramenta neste tile.
## Retorna true se a ferramenta teve efeito.
func on_tool_use(tool_type: Constants.ToolType, tool_level: Constants.ToolLevel) -> bool:
	return false


## Chamado quando o jogador interage (botão de interação, não ferramenta).
func on_interact() -> bool:
	return false


# =============================================================================
# DAY PROCESSING
# =============================================================================

## Chamado no início de cada novo dia pela GameLocation.
func on_new_day() -> void:
	pass


## Chamado quando a estação muda.
func on_season_change(new_season: Constants.Season) -> void:
	pass


# =============================================================================
# PERSISTENCE
# =============================================================================

## Salva os dados deste feature no banco.
## [param loc_id] ID da location onde este feature está.
## [param tile_pos] Posição no grid.
func save_data(loc_id: String, tile_pos: Vector2i) -> void:
	pass  # Override nas subclasses


## Carrega dados de um Dictionary (vindo do banco).
func load_from_data(data: Dictionary) -> void:
	pass  # Override nas subclasses


# =============================================================================
# QUERIES
# =============================================================================

## Retorna se este feature pode ser plantado (só HoeDirt arado retorna true).
func can_plant() -> bool:
	return false


## Retorna se este feature está ocupando espaço para placement de objetos.
func blocks_placement() -> bool:
	return true
