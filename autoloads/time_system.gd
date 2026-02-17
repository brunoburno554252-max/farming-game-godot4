## autoloads/time_system.gd
## TimeSystem — Gerencia o fluxo completo de tempo no jogo.
## Ciclo de 20 horas (6AM-2AM), 4 estações de 28 dias, calendário completo.
## Equivalente ao sistema de tempo do Stardew Valley (Game1.timeOfDay, Game1.dayOfMonth, etc.)
extends Node


# =============================================================================
# STATE
# =============================================================================

## Hora atual no formato "26h" (6 = 6AM, 13 = 1PM, 25 = 1AM, 26 = 2AM)
var current_hour: int = 6
var current_minute: int = 0

## Calendário
var current_day: int = 1
var current_season: Constants.Season = Constants.Season.SPRING
var current_year: int = 1
var total_days_played: int = 0

## Controle de fluxo
var is_time_running: bool = false
var _tick_timer: float = 0.0

## Multiplicador de velocidade do tempo (1.0 = normal)
## Locations específicas podem alterar (ex: caverna roda mais rápido no Stardew)
var time_speed_multiplier: float = 1.0

## Locations onde o tempo é pausado
var _time_paused_locations: Array[String] = []

## Hora em que o jogador acordou
var _wakeup_hour: int = 6


# =============================================================================
# COMPUTED PROPERTIES
# =============================================================================

func get_day_of_week() -> Constants.DayOfWeek:
	return ((total_days_played) % 7) as Constants.DayOfWeek


func get_day_of_week_name() -> String:
	return Constants.DAY_NAMES[get_day_of_week()]


func get_season_name() -> String:
	return Constants.SEASON_NAMES[current_season]


## Retorna a hora formatada para exibição (ex: "1:30 PM")
func get_time_string() -> String:
	var display_hour := current_hour
	if display_hour >= 24:
		display_hour -= 24
	var ampm := "AM" if display_hour < 12 else "PM"
	if display_hour == 0:
		display_hour = 12
	elif display_hour > 12:
		display_hour -= 12
	return "%d:%02d %s" % [display_hour, current_minute, ampm]


## Retorna a data completa formatada
func get_date_string() -> String:
	return "%s, dia %d de %s, Ano %d" % [
		get_day_of_week_name(), current_day, get_season_name(), current_year
	]


## Retorna progresso do dia normalizado (0.0 = 6AM, 1.0 = 2AM)
## Útil para interpolação de luz do dia, cores do céu, etc.
func get_day_progress() -> float:
	var total_min := (current_hour - Constants.DAY_START_HOUR) * 60 + current_minute
	var max_min := (Constants.DAY_END_HOUR - Constants.DAY_START_HOUR) * 60
	return clampf(float(total_min) / float(max_min), 0.0, 1.0)


## Faixas do dia para lógica visual e gameplay
func is_night() -> bool:
	return current_hour >= 20 or current_hour < 6

func is_morning() -> bool:
	return current_hour >= 6 and current_hour < 12

func is_afternoon() -> bool:
	return current_hour >= 12 and current_hour < 18

func is_evening() -> bool:
	return current_hour >= 18 and current_hour < 20

func is_late_night() -> bool:
	return current_hour >= Constants.EXHAUSTION_HOUR


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	EventBus.location_ready.connect(_on_location_ready)


func initialize_new_game() -> void:
	current_hour = Constants.DAY_START_HOUR
	current_minute = 0
	current_day = 1
	current_season = Constants.Season.SPRING
	current_year = 1
	total_days_played = 0
	time_speed_multiplier = 1.0
	_wakeup_hour = Constants.DAY_START_HOUR
	is_time_running = false
	_tick_timer = 0.0


func start_time() -> void:
	is_time_running = true
	_wakeup_hour = current_hour


func stop_time() -> void:
	is_time_running = false


# =============================================================================
# TIME FLOW
# =============================================================================

func _process(delta: float) -> void:
	if not is_time_running or not GameManager.is_playing():
		return
	if LocationManager.current_location_id in _time_paused_locations:
		return
	
	var tick_interval: float = Constants.REAL_SECONDS_PER_TICK / time_speed_multiplier
	_tick_timer += delta
	
	if _tick_timer >= tick_interval:
		_tick_timer -= tick_interval
		_advance_time_tick()


func _advance_time_tick() -> void:
	current_minute += Constants.GAME_MINUTES_PER_TICK
	
	if current_minute >= Constants.MINUTES_PER_GAME_HOUR:
		current_minute -= Constants.MINUTES_PER_GAME_HOUR
		current_hour += 1
		EventBus.hour_changed.emit(current_hour)
		
		if current_hour >= Constants.PASSOUT_HOUR:
			is_time_running = false
			EventBus.player_passed_out.emit("too_late")
			return
	
	EventBus.time_tick.emit(current_hour, current_minute)


# =============================================================================
# DAY ADVANCEMENT
# =============================================================================

func advance_to_next_day() -> void:
	current_day += 1
	total_days_played += 1
	current_hour = Constants.DAY_START_HOUR
	current_minute = 0
	_tick_timer = 0.0
	_wakeup_hour = Constants.DAY_START_HOUR
	
	if current_day > Constants.DAYS_PER_SEASON:
		current_day = 1
		var next_season := int(current_season) + 1
		if next_season >= Constants.SEASONS_PER_YEAR:
			next_season = 0
			current_year += 1
			EventBus.year_changed.emit(current_year)
		current_season = next_season as Constants.Season
		EventBus.season_changed.emit(current_season)


# =============================================================================
# LOCATION-BASED TIME CONTROL
# =============================================================================

func register_time_paused_location(location_id: String) -> void:
	if location_id not in _time_paused_locations:
		_time_paused_locations.append(location_id)


func unregister_time_paused_location(location_id: String) -> void:
	_time_paused_locations.erase(location_id)


func _on_location_ready(_location_id: String) -> void:
	time_speed_multiplier = 1.0


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	DatabaseManager.query(
		"UPDATE game_state SET current_day=%d, current_season=%d, current_year=%d, current_hour=%d, current_minute=%d, total_days_played=%d WHERE id=1;" % [
			current_day, int(current_season), current_year,
			current_hour, current_minute, total_days_played
		]
	)


func load_data() -> void:
	var data := DatabaseManager.get_game_state()
	if data.is_empty():
		return
	current_day = data.get("current_day", 1)
	current_season = data.get("current_season", 0) as Constants.Season
	current_year = data.get("current_year", 1)
	current_hour = data.get("current_hour", Constants.DAY_START_HOUR)
	current_minute = data.get("current_minute", 0)
	total_days_played = data.get("total_days_played", 0)
