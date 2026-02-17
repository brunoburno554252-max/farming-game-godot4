## autoloads/time_system.gd
## TimeSystem — Gerencia o fluxo de tempo no jogo.
## SERÁ EXPANDIDO NA ETAPA 2.
extends Node

var current_hour: int = 6
var current_minute: int = 0
var current_day: int = 1
var current_season: Constants.Season = Constants.Season.SPRING
var current_year: int = 1
var total_days_played: int = 0
var is_time_running: bool = false

var _tick_timer: float = 0.0


func initialize_new_game() -> void:
	current_hour = Constants.DAY_START_HOUR
	current_minute = 0
	current_day = 1
	current_season = Constants.Season.SPRING
	current_year = 1
	total_days_played = 0


func advance_to_next_day() -> void:
	current_day += 1
	total_days_played += 1
	current_hour = Constants.DAY_START_HOUR
	current_minute = 0
	
	if current_day > Constants.DAYS_PER_SEASON:
		current_day = 1
		var season_int := int(current_season) + 1
		if season_int >= Constants.SEASONS_PER_YEAR:
			season_int = 0
			current_year += 1
			EventBus.year_changed.emit(current_year)
		current_season = season_int as Constants.Season
		EventBus.season_changed.emit(current_season)


func get_day_of_week() -> Constants.DayOfWeek:
	return ((total_days_played) % 7) as Constants.DayOfWeek


func get_time_string() -> String:
	var display_hour := current_hour % 24
	var ampm := "AM" if display_hour < 12 else "PM"
	if display_hour == 0:
		display_hour = 12
	elif display_hour > 12:
		display_hour -= 12
	return "%d:%02d %s" % [display_hour, current_minute, ampm]


func save_data() -> void:
	pass  # Implementado na Etapa 3


func load_data() -> void:
	pass  # Implementado na Etapa 3


func _process(delta: float) -> void:
	if not is_time_running or not GameManager.is_playing():
		return
	
	_tick_timer += delta
	if _tick_timer >= Constants.REAL_SECONDS_PER_TICK:
		_tick_timer -= Constants.REAL_SECONDS_PER_TICK
		_advance_time_tick()


func _advance_time_tick() -> void:
	current_minute += Constants.GAME_MINUTES_PER_TICK
	if current_minute >= Constants.MINUTES_PER_GAME_HOUR:
		current_minute = 0
		current_hour += 1
		EventBus.hour_changed.emit(current_hour)
		
		if current_hour >= Constants.PASSOUT_HOUR:
			EventBus.player_passed_out.emit("exhaustion_time")
			return
	
	EventBus.time_tick.emit(current_hour, current_minute)
