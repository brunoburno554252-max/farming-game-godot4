## autoloads/dialogue_manager.gd
## DialogueManager — Gerencia diálogos com NPCs e sistema de choices.
## SERÁ EXPANDIDO NA ETAPA 6 (NPCs).
extends Node

var is_dialogue_active: bool = false
var _current_speaker: String = ""
var _current_lines: Array[String] = []
var _current_line_index: int = 0
var _current_choices: Array[String] = []


## Inicia um diálogo simples (sem choices).
func start_dialogue(speaker: String, lines: Array[String]) -> void:
	_current_speaker = speaker
	_current_lines = lines
	_current_line_index = 0
	_current_choices.clear()
	is_dialogue_active = true
	
	GameManager.enter_dialogue()
	EventBus.dialogue_started.emit(speaker)


## Avança para a próxima linha do diálogo. Retorna false se acabou.
func advance_dialogue() -> bool:
	_current_line_index += 1
	if _current_line_index >= _current_lines.size():
		end_dialogue()
		return false
	return true


## Retorna a linha atual.
func get_current_line() -> String:
	if _current_line_index < _current_lines.size():
		return _current_lines[_current_line_index]
	return ""


## Apresenta choices ao jogador.
func show_choices(choices: Array[String]) -> void:
	_current_choices = choices
	# A UI de diálogo vai ler isso e mostrar os botões


## Chamado quando o jogador seleciona uma choice.
func select_choice(index: int) -> void:
	if index < _current_choices.size():
		EventBus.dialogue_choice_selected.emit(index, _current_choices[index])
	_current_choices.clear()


## Encerra o diálogo.
func end_dialogue() -> void:
	is_dialogue_active = false
	_current_speaker = ""
	_current_lines.clear()
	_current_line_index = 0
	_current_choices.clear()
	
	GameManager.exit_dialogue()
	EventBus.dialogue_ended.emit()
