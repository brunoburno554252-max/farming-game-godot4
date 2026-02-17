## autoloads/weather_system.gd
## WeatherSystem — Gerencia o clima diário.
## SERÁ EXPANDIDO NA ETAPA 2.
extends Node

var current_weather: Constants.Weather = Constants.Weather.SUNNY
var tomorrow_weather: Constants.Weather = Constants.Weather.SUNNY


func initialize_new_game() -> void:
	current_weather = Constants.Weather.SUNNY
	tomorrow_weather = _generate_random_weather(Constants.Season.SPRING)


func determine_weather_for_day(day: int, season: Constants.Season) -> void:
	current_weather = tomorrow_weather
	tomorrow_weather = _generate_random_weather(season)
	EventBus.weather_changed.emit(current_weather)


func _generate_random_weather(season: Constants.Season) -> Constants.Weather:
	var roll := randf()
	match season:
		Constants.Season.SPRING:
			if roll < 0.35: return Constants.Weather.RAINY
			if roll < 0.05: return Constants.Weather.STORMY
			return Constants.Weather.SUNNY
		Constants.Season.SUMMER:
			if roll < 0.15: return Constants.Weather.RAINY
			if roll < 0.10: return Constants.Weather.STORMY
			return Constants.Weather.SUNNY
		Constants.Season.FALL:
			if roll < 0.30: return Constants.Weather.RAINY
			if roll < 0.10: return Constants.Weather.WINDY
			return Constants.Weather.SUNNY
		Constants.Season.WINTER:
			if roll < 0.40: return Constants.Weather.SNOWY
			return Constants.Weather.SUNNY
	return Constants.Weather.SUNNY


func is_raining() -> bool:
	return current_weather == Constants.Weather.RAINY or current_weather == Constants.Weather.STORMY


func save_data() -> void:
	pass  # Etapa 3


func load_data() -> void:
	pass  # Etapa 3
