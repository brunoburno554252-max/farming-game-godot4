## classes/state_machine.gd
## StateMachine genérica reutilizável.
## Usada pelo PlayerController, NPCController, GameManager, e qualquer outro nó
## que precise de estados distintos com transições limpas.
##
## Uso:
##   1. Adicione este nó como filho do nó que precisa de estados
##   2. Adicione nós State como filhos desta StateMachine
##   3. Defina initial_state no Inspector ou via código
##   4. Chame transition_to("NomeDoEstado") para mudar de estado
class_name StateMachine
extends Node


## O estado inicial (definido no Inspector — arraste o nó State aqui)
@export var initial_state: State

## Estado atual ativo
var current_state: State

## Dicionário de todos os estados registrados: { "NomeDoEstado": StateNode }
var _states: Dictionary = {}

## Referência ao nó dono desta state machine (o pai)
var owner_node: Node


func _ready() -> void:
	owner_node = get_parent()
	
	# Registra todos os filhos que são State
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.state_machine = self
			child.owner_node = owner_node
	
	# Ativa o estado inicial
	if initial_state:
		current_state = initial_state
		current_state._enter({})
	elif _states.size() > 0:
		# Fallback: usa o primeiro filho State
		current_state = _states.values()[0]
		current_state._enter({})
	else:
		push_warning("StateMachine em '%s' não tem estados!" % owner_node.name)


func _process(delta: float) -> void:
	if current_state:
		current_state._update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state._physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state._handle_input(event)


## Transiciona para um novo estado pelo nome.
## [param state_name] Nome do nó State filho.
## [param args] Dicionário opcional de dados para passar ao novo estado.
func transition_to(state_name: String, args: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_error("StateMachine: Estado '%s' não encontrado em '%s'!" % [state_name, owner_node.name])
		return
	
	var new_state: State = _states[state_name]
	
	if new_state == current_state:
		return  # Já estamos nesse estado
	
	var old_state := current_state
	
	if current_state:
		current_state._exit()
	
	current_state = new_state
	current_state._enter(args)
	
	# Debug (remover em produção ou usar feature flag)
	# print("[StateMachine] %s: %s → %s" % [owner_node.name, old_state.name if old_state else "null", new_state.name])


## Retorna o nome do estado atual
func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""


## Verifica se está em um estado específico
func is_in_state(state_name: String) -> bool:
	return current_state and current_state.name == state_name


## Retorna um estado pelo nome (ou null se não existe)
func get_state(state_name: String) -> State:
	return _states.get(state_name, null)
