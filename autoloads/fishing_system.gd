## autoloads/fishing_system.gd
## FishingSystem — Gerencia dados de peixes, lógica de pesca, e estado do minigame.
## O minigame em si é uma UI (FishingMinigame) que se comunica com este sistema.
## Equivalente ao FishingRod + Fish do Stardew Valley.
extends Node


# =============================================================================
# FISH DATA
# =============================================================================

## {fish_id: {display_name, difficulty, behavior, min_size, max_size, base_price,
##   locations: [String], seasons: [Season], weather: [Weather], time_range: [start_hour, end_hour]}}
var _fish: Dictionary = {}


# =============================================================================
# STATE
# =============================================================================

var is_fishing: bool = false
var _current_location: String = ""
var _current_fish_id: String = ""
var _catch_difficulty: float = 0.0


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_register_default_fish()


# =============================================================================
# FISH REGISTRY
# =============================================================================

func _register_default_fish() -> void:
	# Spring fish
	_reg("sunfish", "Peixe-sol", 30, "mixed", 5, 15, 30,
		["town", "farm"], [Constants.Season.SPRING, Constants.Season.SUMMER], [], [6, 19])
	_reg("catfish", "Bagre", 60, "dart", 12, 30, 200,
		["town", "forest"], [Constants.Season.SPRING, Constants.Season.FALL],
		[Constants.Weather.RAINY], [6, 24])
	_reg("eel", "Enguia", 55, "smooth", 15, 35, 85,
		["beach"], [Constants.Season.SPRING, Constants.Season.FALL],
		[Constants.Weather.RAINY], [16, 26])
	
	# Summer fish
	_reg("red_snapper", "Vermelhão", 40, "mixed", 8, 20, 50,
		["beach"], [Constants.Season.SUMMER, Constants.Season.FALL],
		[Constants.Weather.RAINY], [6, 19])
	_reg("tilapia", "Tilápia", 35, "mixed", 8, 18, 75,
		["beach", "town"], [Constants.Season.SUMMER, Constants.Season.FALL], [], [6, 14])
	_reg("octopus", "Polvo", 75, "sinker", 10, 25, 150,
		["beach"], [Constants.Season.SUMMER], [], [6, 13])
	
	# Fall fish
	_reg("salmon", "Salmão", 50, "mixed", 20, 40, 75,
		["town", "forest"], [Constants.Season.FALL], [], [6, 19])
	_reg("walleye", "Lucioperca", 65, "smooth", 15, 35, 105,
		["town", "forest"], [Constants.Season.FALL],
		[Constants.Weather.RAINY], [12, 26])
	
	# Winter fish
	_reg("perch", "Perca", 35, "dart", 8, 18, 55,
		["town", "forest", "mountain"], [Constants.Season.WINTER], [], [6, 19])
	_reg("pike", "Lúcio", 60, "dart", 20, 45, 100,
		["town", "forest"], [Constants.Season.SUMMER, Constants.Season.WINTER], [], [6, 19])
	
	# All-season fish
	_reg("carp", "Carpa", 15, "mixed", 10, 25, 30,
		["mountain", "forest", "farm"], [], [], [6, 26])
	_reg("bullhead", "Cabeça-de-touro", 25, "smooth", 6, 15, 75,
		["mountain"], [], [], [6, 26])
	_reg("largemouth_bass", "Robalo", 50, "mixed", 12, 30, 100,
		["mountain", "farm"], [], [], [6, 19])
	
	# Legendary (rare)
	_reg("legend", "Lenda", 90, "dart", 30, 60, 5000,
		["mountain"], [Constants.Season.SPRING], [Constants.Weather.RAINY], [6, 20])


func _reg(id: String, display: String, diff: int, behavior: String,
	min_s: int, max_s: int, price: int,
	locations: Array, seasons: Array, weather: Array, time_range: Array) -> void:
	_fish[id] = {
		"id": id,
		"display_name": display,
		"difficulty": diff,
		"behavior": behavior,  # mixed, dart, smooth, sinker
		"min_size": min_s,
		"max_size": max_s,
		"base_price": price,
		"locations": locations,
		"seasons": seasons,
		"weather": weather,
		"time_range": time_range,
	}
	
	# Also register as an item if not already
	if not ItemDatabase.has_item(id):
		var item := ItemData.new()
		item.id = id
		item.display_name = display
		item.description = "Um peixe: %s." % display
		item.item_type = Constants.ItemType.FISH
		item.category = "fish"
		item.sell_price = price


# =============================================================================
# FISHING LOGIC
# =============================================================================

## Determina quais peixes estão disponíveis agora na location atual.
func get_available_fish(location_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var hour := TimeSystem.current_hour
	var season := TimeSystem.current_season
	var weather := WeatherSystem.current_weather
	
	for fish_id in _fish:
		var fish: Dictionary = _fish[fish_id]
		
		# Check location
		if not fish.locations.is_empty() and location_id not in fish.locations:
			continue
		
		# Check season
		if not fish.seasons.is_empty() and season not in fish.seasons:
			continue
		
		# Check weather
		if not fish.weather.is_empty() and weather not in fish.weather:
			continue
		
		# Check time
		if not fish.time_range.is_empty():
			var start_h: int = fish.time_range[0]
			var end_h: int = fish.time_range[1]
			if hour < start_h or hour > end_h:
				continue
		
		result.append(fish)
	
	return result


## Inicia uma tentativa de pesca. Retorna o peixe selecionado ou vazio.
func start_fishing(location_id: String) -> Dictionary:
	var available := get_available_fish(location_id)
	if available.is_empty():
		return {}
	
	# Weighted selection (peixes mais difíceis são menos comuns)
	var weights: Array[float] = []
	var total_weight: float = 0.0
	for fish in available:
		var weight: float = 100.0 - fish.difficulty + 20.0
		weights.append(weight)
		total_weight += weight
	
	var roll := randf() * total_weight
	var cumulative: float = 0.0
	for i in available.size():
		cumulative += weights[i]
		if roll <= cumulative:
			_current_fish_id = available[i].id
			_catch_difficulty = available[i].difficulty / 100.0
			is_fishing = true
			return available[i]
	
	return available[0]


## Calcula o resultado da pesca após o minigame.
## [param success] Se o jogador venceu o minigame.
## [param quality_bonus] 0.0-1.0 baseado na performance no minigame.
func finish_fishing(success: bool, quality_bonus: float = 0.0) -> Dictionary:
	is_fishing = false
	
	if not success or _current_fish_id.is_empty():
		_current_fish_id = ""
		return {"success": false}
	
	var fish: Dictionary = _fish.get(_current_fish_id, {})
	if fish.is_empty():
		return {"success": false}
	
	# Determine quality
	var quality := Constants.ItemQuality.NORMAL
	if quality_bonus > 0.9:
		quality = Constants.ItemQuality.IRIDIUM
	elif quality_bonus > 0.7:
		quality = Constants.ItemQuality.GOLD
	elif quality_bonus > 0.4:
		quality = Constants.ItemQuality.SILVER
	
	# Determine size
	var size_range: float = fish.max_size - fish.min_size
	var fish_size: int = fish.min_size + int(size_range * randf())
	
	# Add to inventory
	var leftover := InventorySystem.add_item(_current_fish_id, 1, quality)
	
	# XP
	SkillSystem.add_xp(Constants.SkillType.FISHING, int(fish.difficulty * 0.5) + 10)
	
	var result := {
		"success": true,
		"fish_id": _current_fish_id,
		"display_name": fish.display_name,
		"size": fish_size,
		"quality": quality,
		"price": fish.base_price,
	}
	
	_current_fish_id = ""
	EventBus.show_item_obtained.emit(result.fish_id, 1)
	
	return result


func get_fish_data(fish_id: String) -> Dictionary:
	return _fish.get(fish_id, {})
