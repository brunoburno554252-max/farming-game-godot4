## autoloads/weather_system.gd
## WeatherSystem — Gerencia o clima diário com probabilidades por estação.
## O clima afeta: rega automática de plantas, schedules de NPCs, peixes disponíveis,
## efeitos visuais (chuva, neve, raios), e música ambiente.
## Baseado no sistema de clima do Stardew Valley.
extends Node


# =============================================================================
# STATE
# =============================================================================

var current_weather: Constants.Weather = Constants.Weather.SUNNY
var tomorrow_weather: Constants.Weather = Constants.Weather.SUNNY

## Dias consecutivos de chuva (para limitar longas sequências)
var _rain_streak: int = 0

## Previsão para a TV do fazendeiro (gerada no início do dia)
var _forecast_text: String = ""


# =============================================================================
# WEATHER PROBABILITY TABLES
# =============================================================================

## Probabilidades base de clima por estação: { Weather: peso }
## Os pesos são normalizados automaticamente.
## Baseado nas probabilidades reais do Stardew Valley.
const WEATHER_PROBABILITIES: Dictionary = {
	Constants.Season.SPRING: {
		Constants.Weather.SUNNY: 55,
		Constants.Weather.RAINY: 30,
		Constants.Weather.STORMY: 10,
		Constants.Weather.WINDY: 5,
	},
	Constants.Season.SUMMER: {
		Constants.Weather.SUNNY: 65,
		Constants.Weather.RAINY: 15,
		Constants.Weather.STORMY: 15,
		Constants.Weather.WINDY: 5,
	},
	Constants.Season.FALL: {
		Constants.Weather.SUNNY: 50,
		Constants.Weather.RAINY: 25,
		Constants.Weather.STORMY: 5,
		Constants.Weather.WINDY: 20,
	},
	Constants.Season.WINTER: {
		Constants.Weather.SUNNY: 40,
		Constants.Weather.SNOWY: 50,
		Constants.Weather.WINDY: 10,
	},
}

## Dias especiais com clima forçado (ex: festivais sempre ensolarados)
## Formato: { season * 100 + day: Weather }
## Dia 1 de cada estação = sempre ensolarado (como no Stardew)
var _forced_weather: Dictionary = {}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Forçar dia 1 de cada estação como ensolarado
	for season in Constants.Season.values():
		_forced_weather[season * 100 + 1] = Constants.Weather.SUNNY
	
	EventBus.day_started.connect(_on_day_started)


func initialize_new_game() -> void:
	current_weather = Constants.Weather.SUNNY
	tomorrow_weather = _generate_weather(Constants.Season.SPRING, 2)
	_rain_streak = 0
	_generate_forecast()


# =============================================================================
# WEATHER DETERMINATION
# =============================================================================

## Determina o clima para o dia atual e gera previsão do dia seguinte.
## Chamado pelo GameManager durante a transição de dia.
func determine_weather_for_day(day: int, season: Constants.Season) -> void:
	# Aplicar o clima que foi previsto ontem
	current_weather = tomorrow_weather
	
	# Verificar se o próximo dia tem clima forçado
	var next_day := day + 1
	var next_season := season
	if next_day > Constants.DAYS_PER_SEASON:
		next_day = 1
		next_season = ((int(season) + 1) % Constants.SEASONS_PER_YEAR) as Constants.Season
	
	var forced_key := int(next_season) * 100 + next_day
	if _forced_weather.has(forced_key):
		tomorrow_weather = _forced_weather[forced_key]
	else:
		tomorrow_weather = _generate_weather(next_season, next_day)
	
	# Atualizar streak de chuva
	if is_raining():
		_rain_streak += 1
	else:
		_rain_streak = 0
	
	_generate_forecast()
	EventBus.weather_changed.emit(current_weather)


## Gera um clima aleatório baseado nas probabilidades da estação.
func _generate_weather(season: Constants.Season, day: int) -> Constants.Weather:
	if not WEATHER_PROBABILITIES.has(season):
		return Constants.Weather.SUNNY
	
	var probs: Dictionary = WEATHER_PROBABILITIES[season]
	
	# Se já choveu 3 dias seguidos, forçar sol (evita frustração)
	if _rain_streak >= 3:
		if randf() < 0.8:
			return Constants.Weather.SUNNY
	
	# Weighted random selection
	var total_weight: float = 0.0
	for weight in probs.values():
		total_weight += weight
	
	var roll := randf() * total_weight
	var cumulative: float = 0.0
	
	for weather in probs:
		cumulative += probs[weather]
		if roll <= cumulative:
			return weather
	
	return Constants.Weather.SUNNY


# =============================================================================
# WEATHER QUERIES
# =============================================================================

## Retorna true se está chovendo (rain ou storm). Usado pelo CropSystem para auto-rega.
func is_raining() -> bool:
	return current_weather == Constants.Weather.RAINY or \
		   current_weather == Constants.Weather.STORMY


## Retorna true se está tempestade (chuva + raios)
func is_stormy() -> bool:
	return current_weather == Constants.Weather.STORMY


## Retorna true se está nevando
func is_snowing() -> bool:
	return current_weather == Constants.Weather.SNOWY


## Retorna true se está ventando (debris visuais)
func is_windy() -> bool:
	return current_weather == Constants.Weather.WINDY


## Retorna o nome do clima para exibição
func get_weather_name() -> String:
	match current_weather:
		Constants.Weather.SUNNY: return "Ensolarado"
		Constants.Weather.RAINY: return "Chuvoso"
		Constants.Weather.STORMY: return "Tempestade"
		Constants.Weather.SNOWY: return "Neve"
		Constants.Weather.WINDY: return "Ventoso"
	return "Desconhecido"


func get_tomorrow_weather_name() -> String:
	match tomorrow_weather:
		Constants.Weather.SUNNY: return "Ensolarado"
		Constants.Weather.RAINY: return "Chuvoso"
		Constants.Weather.STORMY: return "Tempestade"
		Constants.Weather.SNOWY: return "Neve"
		Constants.Weather.WINDY: return "Ventoso"
	return "Desconhecido"


# =============================================================================
# FORECAST (para TV do fazendeiro)
# =============================================================================

func _generate_forecast() -> void:
	match tomorrow_weather:
		Constants.Weather.SUNNY:
			var options := [
				"Amanhã será um lindo dia de sol! Perfeito para trabalhar na fazenda.",
				"Previsão para amanhã: céu limpo e temperatura agradável.",
				"Sol forte amanhã. Não esqueça de regar suas plantações!",
			]
			_forecast_text = options[randi() % options.size()]
		Constants.Weather.RAINY:
			var options := [
				"Chuva prevista para amanhã. Suas plantas serão regadas automaticamente!",
				"Traga um guarda-chuva amanhã. Dia chuvoso pela frente.",
				"Previsão de chuva para amanhã. Bom dia para pescar!",
			]
			_forecast_text = options[randi() % options.size()]
		Constants.Weather.STORMY:
			var options := [
				"Atenção! Tempestade prevista para amanhã. Cuidado com os raios!",
				"Forte tempestade amanhã. Fique em segurança!",
			]
			_forecast_text = options[randi() % options.size()]
		Constants.Weather.SNOWY:
			var options := [
				"Neve prevista para amanhã. O vale ficará branco!",
				"Prepare-se para a neve amanhã. Dia gelado pela frente.",
			]
			_forecast_text = options[randi() % options.size()]
		Constants.Weather.WINDY:
			var options := [
				"Ventos fortes amanhã. Segure seu chapéu!",
				"Previsão de vento forte. Alguns detritos podem voar pela fazenda.",
			]
			_forecast_text = options[randi() % options.size()]


func get_forecast() -> String:
	return _forecast_text


# =============================================================================
# FORCED WEATHER (para festivais, eventos, etc.)
# =============================================================================

## Força o clima de um dia específico.
## [param season] Estação.
## [param day] Dia do mês (1-28).
## [param weather] Clima forçado.
func force_weather_on_day(season: Constants.Season, day: int, weather: Constants.Weather) -> void:
	_forced_weather[int(season) * 100 + day] = weather


## Remove clima forçado de um dia.
func clear_forced_weather(season: Constants.Season, day: int) -> void:
	_forced_weather.erase(int(season) * 100 + day)


# =============================================================================
# SIGNALS
# =============================================================================

func _on_day_started(_day: int, _season: Constants.Season, _year: int) -> void:
	# Pode ser usado para ativar efeitos visuais de clima
	pass


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	DatabaseManager.query(
		"UPDATE game_state SET weather_today=%d, weather_tomorrow=%d WHERE id=1;" % [
			int(current_weather), int(tomorrow_weather)
		]
	)


func load_data() -> void:
	var data := DatabaseManager.get_game_state()
	if data.is_empty():
		return
	current_weather = data.get("weather_today", 0) as Constants.Weather
	tomorrow_weather = data.get("weather_tomorrow", 0) as Constants.Weather
	_generate_forecast()
