## classes/state.gd
## State — Classe base para todos os estados da StateMachine.
## Cada estado específico (ex: PlayerIdleState, PlayerWalkState) herda desta classe.
##
## Override os métodos que você precisa:
##   _enter(args)        — Chamado ao entrar no estado
##   _exit()             — Chamado ao sair do estado
##   _update(delta)      — Chamado todo frame (_process)
##   _physics_update(delta) — Chamado todo physics frame (_physics_process)
##   _handle_input(event)   — Chamado em _unhandled_input
class_name State
extends Node


## Referência à StateMachine que gerencia este estado
var state_machine: StateMachine

## Referência ao nó dono da StateMachine (ex: PlayerController, NPCController)
var owner_node: Node


## Chamado quando este estado se torna ativo.
## [param args] Dicionário de dados opcionais passados pela transição.
func _enter(_args: Dictionary) -> void:
	pass


## Chamado quando este estado deixa de ser ativo.
func _exit() -> void:
	pass


## Chamado todo frame enquanto este estado estiver ativo. Equivale a _process().
## [param delta] Tempo desde o último frame.
func _update(_delta: float) -> void:
	pass


## Chamado todo physics frame enquanto ativo. Equivale a _physics_process().
## [param delta] Tempo desde o último physics frame.
func _physics_update(_delta: float) -> void:
	pass


## Chamado quando há input não tratado enquanto ativo. Equivale a _unhandled_input().
## [param event] O evento de input.
func _handle_input(_event: InputEvent) -> void:
	pass


## Helper: Transiciona para outro estado na mesma StateMachine.
## Atalho para state_machine.transition_to()
func transition_to(state_name: String, args: Dictionary = {}) -> void:
	if state_machine:
		state_machine.transition_to(state_name, args)
