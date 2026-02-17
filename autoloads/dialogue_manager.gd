## autoloads/dialogue_manager.gd
## DialogueManager — Gerencia diálogos com NPCs e sistema de choices.
## Suporta diálogos simples (array de strings) e ricos (array de dicts com choices).
## Tokens dinâmicos: {player_name}, {season}, {day}, {weather}, etc.
## Equivalente ao Dialogue/CharacterDialogues do Stardew Valley.
extends Node


# =============================================================================
# STATE
# =============================================================================

var is_dialogue_active: bool = false
var _current_speaker: String = ""

## Linhas do diálogo. Cada linha pode ser:
## - String simples: "Olá, como vai?"
## - Dictionary rico: {text: "Olá!", speaker: "Pierre", choices: ["Sim", "Não"]}
var _current_lines: Array = []
var _current_line_index: int = 0
var _current_choices: Array[String] = []

## Callback chamado após uma choice ser selecionada
var _choice_callback: Callable


# =============================================================================
# SIMPLE DIALOGUE
# =============================================================================

## Inicia um diálogo com linhas simples (strings).
func start_dialogue(speaker: String, lines: Array) -> void:
	_current_speaker = speaker
	_current_lines = lines
	_current_line_index = 0
	_current_choices.clear()
	is_dialogue_active = true
	
	GameManager.enter_dialogue()
	EventBus.dialogue_started.emit(speaker)


## Inicia um diálogo com uma única linha.
func say(speaker: String, text: String) -> void:
	start_dialogue(speaker, [text])


# =============================================================================
# RICH DIALOGUE
# =============================================================================

## Inicia um diálogo rico com linhas que podem ter choices.
## [param speaker] Nome padrão do falante.
## [param lines] Array misto de Strings e Dicts.
## Cada Dict pode ter: {text, speaker?, choices?, choice_callback?}
func start_rich_dialogue(speaker: String, lines: Array) -> void:
	_current_speaker = speaker
	_current_lines = lines
	_current_line_index = 0
	_current_choices.clear()
	is_dialogue_active = true
	
	GameManager.enter_dialogue()
	EventBus.dialogue_started.emit(speaker)


# =============================================================================
# NAVIGATION
# =============================================================================

## Retorna os dados da linha atual como Dictionary.
## Sempre retorna: {text: String, speaker: String, choices: Array}
func get_current_line() -> Dictionary:
	if _current_line_index >= _current_lines.size():
		return {}
	
	var line = _current_lines[_current_line_index]
	var result := {
		"text": "",
		"speaker": _current_speaker,
		"choices": [] as Array[String],
	}
	
	if line is String:
		result.text = _process_tokens(line)
	elif line is Dictionary:
		result.text = _process_tokens(line.get("text", ""))
		if line.has("speaker"):
			result.speaker = line.speaker
		if line.has("choices"):
			result.choices = line.choices
		if line.has("choice_callback"):
			_choice_callback = line.choice_callback
	
	return result


## Avança para a próxima linha. Retorna false se acabou.
func advance_dialogue() -> bool:
	_current_line_index += 1
	if _current_line_index >= _current_lines.size():
		end_dialogue()
		return false
	return true


## Chamado quando o jogador seleciona uma choice.
func select_choice(index: int) -> void:
	if index < _current_choices.size():
		EventBus.dialogue_choice_selected.emit(index, _current_choices[index])
	
	if _choice_callback.is_valid():
		_choice_callback.call(index)
		_choice_callback = Callable()
	
	_current_choices.clear()
	
	# Avançar para a próxima linha após a choice
	advance_dialogue()
	if not is_dialogue_active:
		return


## Apresenta choices ao jogador (chamado externamente).
func show_choices(choices: Array[String], callback: Callable = Callable()) -> void:
	_current_choices = choices
	_choice_callback = callback


## Encerra o diálogo.
func end_dialogue() -> void:
	is_dialogue_active = false
	_current_speaker = ""
	_current_lines.clear()
	_current_line_index = 0
	_current_choices.clear()
	_choice_callback = Callable()
	
	GameManager.exit_dialogue()
	EventBus.dialogue_ended.emit()


# =============================================================================
# TOKEN REPLACEMENT
# =============================================================================

## Substitui tokens dinâmicos no texto.
## Ex: "Olá {player_name}! Lindo dia de {season}." → "Olá João! Lindo dia de Primavera."
func _process_tokens(text: String) -> String:
	var result := text
	
	# Tokens disponíveis
	result = result.replace("{player_name}", GameManager.player_name if GameManager.get("player_name") else "Fazendeiro")
	result = result.replace("{season}", TimeSystem.get_season_name())
	result = result.replace("{day}", str(TimeSystem.current_day))
	result = result.replace("{day_of_week}", TimeSystem.get_day_of_week_name())
	result = result.replace("{year}", str(TimeSystem.current_year))
	result = result.replace("{weather}", WeatherSystem.get_weather_name())
	result = result.replace("{time}", TimeSystem.get_time_string())
	result = result.replace("{gold}", str(InventorySystem.gold))
	
	return result
