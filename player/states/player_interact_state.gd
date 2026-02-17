## player/states/player_interact_state.gd
## PlayerInteractState — Estado de interação com o mundo.
## Fala com NPCs, abre baús, interage com objetos e tiles especiais.
## Retorna para Idle ao terminar.
class_name PlayerInteractState
extends State


var _player: PlayerController


func _enter(_args: Dictionary) -> void:
	_player = owner as PlayerController
	if not _player:
		transition_to("Idle")
		return
	
	_player.can_move = false
	_player.velocity = Vector2.ZERO
	
	var interacted := false
	var facing_tile := _player.get_facing_tile()
	
	# 1. Checar se o raycast está colidindo com algo (NPC, objeto interativo)
	var target := _player.get_interaction_target()
	if target:
		if target.has_method("interact"):
			target.interact()
			interacted = true
		elif target.has_method("on_interact"):
			target.on_interact()
			interacted = true
	
	# 2. Checar terrain features no tile à frente
	if not interacted:
		var location := LocationManager.get_current_game_location()
		if location:
			if location.has_terrain_feature(facing_tile):
				var feature: Node2D = location.get_terrain_feature(facing_tile)
				if feature.has_method("on_interact"):
					interacted = feature.on_interact()
			
			# 3. Checar objetos colocados
			if not interacted and location.has_placed_object(facing_tile):
				var obj: Node2D = location.get_placed_object(facing_tile)
				if obj.has_method("on_interact"):
					interacted = obj.on_interact()
			
			# 4. Checar interações especiais de tile (cama, TV, etc.)
			if not interacted and location.has_method("check_tile_interaction"):
				var interaction_type: String = location.check_tile_interaction(facing_tile)
				if interaction_type != "":
					_handle_special_interaction(location, interaction_type)
					interacted = true
	
	if interacted:
		EventBus.player_interact.emit(target, facing_tile)
	
	# Voltar para Idle
	_player.can_move = true
	transition_to("Idle")


func _handle_special_interaction(location: Node, interaction_type: String) -> void:
	match interaction_type:
		"bed":
			if location.has_method("interact_bed"):
				location.interact_bed()
		"tv":
			if location.has_method("get_tv_forecast"):
				var forecast: String = location.get_tv_forecast()
				DialogueManager.start_dialogue("TV", [forecast])
		"fridge":
			# Abrir inventário especial (storage da geladeira)
			EventBus.menu_opened.emit("fridge_storage")
