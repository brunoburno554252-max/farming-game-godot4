## locations/house/farmhouse.gd
## Farmhouse — Casa do jogador. Location interior.
## Contém: cama (dormir), TV (previsão do tempo), geladeira (storage).
extends GameLocation


# =============================================================================
# CONFIGURATION
# =============================================================================

## Tile da cama (interagir para dormir)
@export var bed_tile: Vector2i = Vector2i(9, 5)

## Tile da TV
@export var tv_tile: Vector2i = Vector2i(3, 6)

## Tile da geladeira
@export var fridge_tile: Vector2i = Vector2i(6, 3)


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	location_id = Constants.LOCATION_FARMHOUSE
	default_music = "farmhouse"
	is_indoors = true
	time_passes = true  # Tempo passa dentro de casa


func _setup_warps() -> void:
	# Warp: Farmhouse → Farm (porta de saída)
	add_warp(
		Vector2i(6, 12),  # Tile da porta
		Constants.LOCATION_FARM,
		Vector2(
			64 * Constants.TILE_SIZE + Constants.TILE_SIZE / 2,
			16 * Constants.TILE_SIZE
		),
		Constants.Direction.DOWN
	)


# =============================================================================
# INTERACTIONS
# =============================================================================

## Verifica interação especial baseada no tile.
## Chamado pelo sistema de interação quando o jogador pressiona o botão.
func check_tile_interaction(tile_pos: Vector2i) -> String:
	if tile_pos == bed_tile:
		return "bed"
	elif tile_pos == tv_tile:
		return "tv"
	elif tile_pos == fridge_tile:
		return "fridge"
	return ""


## Retorna o texto da previsão do tempo (TV).
func get_tv_forecast() -> String:
	return WeatherSystem.get_forecast()


## Inicia o processo de dormir.
func interact_bed() -> void:
	if TimeSystem.current_hour < 18:
		# Muito cedo para dormir
		EventBus.dialogue_started.emit("Narrador")
		# DialogueManager vai mostrar: "Ainda não está com sono..."
	else:
		EventBus.player_slept.emit()
