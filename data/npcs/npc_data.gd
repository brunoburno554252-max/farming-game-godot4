## data/npcs/npc_data.gd
## NPCData — Resource que define os dados de um NPC.
## Inclui informações pessoais, preferências de presente, diálogos por contexto.
## Equivalente ao CharacterData/NPCDispositions do Stardew Valley.
class_name NPCData
extends Resource


# =============================================================================
# IDENTIFICATION
# =============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

## Location onde o NPC mora (onde dorme)
@export var home_location: String = "town"

## Posição padrão (tile) na home location
@export var home_tile: Vector2i = Vector2i.ZERO

## Se é um NPC que pode ser namorado/casado
@export var is_romanceable: bool = false

## Aniversário: {season: Season, day: int}
@export var birthday_season: Constants.Season = Constants.Season.SPRING
@export var birthday_day: int = 1


# =============================================================================
# GIFT TASTES
# =============================================================================

## Dicionário de item_id → GiftTaste
## Ex: {"melon": GiftTaste.LOVE, "stone": GiftTaste.HATE}
@export var gift_preferences: Dictionary = {}

## Categorias universais (aplicam a todos os NPCs como fallback)
@export var loved_categories: Array[String] = []
@export var hated_categories: Array[String] = []


# =============================================================================
# DIALOGUE
# =============================================================================

## Diálogos genéricos por estação (fallback)
## {Season: Array[String]}
@export var seasonal_dialogue: Dictionary = {}

## Diálogos por nível de amizade (hearts)
## {hearts_threshold: Array[String]}
@export var friendship_dialogue: Dictionary = {}

## Diálogos especiais por dia da semana
## {DayOfWeek: Array[String]}
@export var weekday_dialogue: Dictionary = {}

## Diálogos em dias de chuva
@export var rain_dialogue: Array[String] = []

## Diálogo de aniversário
@export var birthday_dialogue: String = ""


# =============================================================================
# SCHEDULE
# =============================================================================

## Schedule padrão: Array de ScheduleEntry
## Cada entry: {hour: int, location: String, tile: Vector2i, facing: Direction}
## O NPC se move entre estes pontos durante o dia.
@export var default_schedule: Array[Dictionary] = []

## Schedules por estação (sobrescreve o default)
## {Season: Array[Dictionary]}
@export var seasonal_schedules: Dictionary = {}

## Schedules por dia da semana específico
## {"season_dayofweek": Array[Dictionary]} ex: "spring_monday"
@export var special_schedules: Dictionary = {}

## Schedule para dias de chuva
@export var rain_schedule: Array[Dictionary] = []


# =============================================================================
# METHODS
# =============================================================================

## Retorna o gift taste para um item.
func get_gift_taste(item_id: String) -> Constants.GiftTaste:
	if gift_preferences.has(item_id):
		return gift_preferences[item_id]
	return Constants.GiftTaste.NEUTRAL


## Retorna o schedule para o dia atual.
func get_schedule_for_day(
	day: int, season: Constants.Season, day_of_week: Constants.DayOfWeek, is_raining: bool
) -> Array[Dictionary]:
	# Prioridade: chuva > especial > sazonal > default
	if is_raining and not rain_schedule.is_empty():
		return rain_schedule
	
	var special_key := "%s_%s" % [
		Constants.SEASON_NAMES[season].to_lower(),
		Constants.DAY_NAMES[day_of_week].to_lower()
	]
	if special_schedules.has(special_key):
		return special_schedules[special_key]
	
	if seasonal_schedules.has(season):
		return seasonal_schedules[season]
	
	return default_schedule


## Retorna uma linha de diálogo contextual.
func get_dialogue(
	hearts: int, season: Constants.Season, day_of_week: Constants.DayOfWeek,
	is_raining: bool, day: int
) -> String:
	# Aniversário
	if int(birthday_season) == int(season) and birthday_day == day:
		if not birthday_dialogue.is_empty():
			return birthday_dialogue
	
	# Chuva
	if is_raining and not rain_dialogue.is_empty():
		return rain_dialogue[randi() % rain_dialogue.size()]
	
	# Por amizade (maior threshold primeiro)
	var best_threshold := -1
	for threshold_str in friendship_dialogue:
		var threshold: int = int(threshold_str) if threshold_str is String else threshold_str
		if hearts >= threshold and threshold > best_threshold:
			best_threshold = threshold
	if best_threshold >= 0:
		var lines: Array = friendship_dialogue[best_threshold]
		if not lines.is_empty():
			return lines[randi() % lines.size()]
	
	# Por dia da semana
	if weekday_dialogue.has(day_of_week):
		var lines: Array = weekday_dialogue[day_of_week]
		if not lines.is_empty():
			return lines[randi() % lines.size()]
	
	# Por estação
	if seasonal_dialogue.has(season):
		var lines: Array = seasonal_dialogue[season]
		if not lines.is_empty():
			return lines[randi() % lines.size()]
	
	return "..."
