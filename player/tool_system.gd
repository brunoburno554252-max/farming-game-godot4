## player/tool_system.gd
## ToolSystem — Gerencia o uso de ferramentas pelo jogador.
## Determina efeitos baseado no tipo de ferramenta, nível, e tile alvo.
## Conecta InventorySystem (item selecionado) com GameLocation (efeito no mundo).
##
## NOTA: Este NÃO é um Autoload. É instanciado pelo PlayerController.
class_name ToolSystem
extends RefCounted


# =============================================================================
# STATE
# =============================================================================

## Energia atual do jogador
var current_energy: float = 270.0
var max_energy: float = 270.0


# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(start_energy: float, start_max: float) -> void:
	current_energy = start_energy
	max_energy = start_max


# =============================================================================
# TOOL USAGE
# =============================================================================

## Tenta usar a ferramenta atualmente equipada no tile alvo.
## Retorna Dictionary com resultado: { "success": bool, "action": String }
func use_tool_at(
	tile_pos: Vector2i,
	facing_direction: Constants.Direction
) -> Dictionary:
	var result := {"success": false, "action": "none"}
	
	# Obter item selecionado
	var selected := InventorySystem.get_selected_item_data()
	if not selected:
		return result
	
	# Se é uma ferramenta
	if selected.is_tool():
		return _use_tool(selected, tile_pos, facing_direction)
	
	# Se é uma semente
	if selected.is_seed():
		return _use_seed(selected, tile_pos)
	
	# Se é comida
	if selected.is_food():
		return _use_food(selected)
	
	# Se é um objeto colocável
	if selected.item_type == Constants.ItemType.CRAFTABLE and selected.is_placeable:
		return _place_object(selected, tile_pos)
	
	return result


## Processa uso de ferramenta real.
func _use_tool(
	item: ItemData,
	tile_pos: Vector2i,
	direction: Constants.Direction
) -> Dictionary:
	var result := {"success": false, "action": "tool"}
	
	# Verificar energia
	var energy_cost: int = Constants.TOOL_ENERGY_COST.get(item.tool_type, 0)
	if current_energy < energy_cost:
		result.action = "no_energy"
		return result
	
	# Obter location atual
	var location := LocationManager.get_current_game_location()
	if not location:
		return result
	
	var success := false
	
	match item.tool_type:
		Constants.ToolType.HOE:
			success = _use_hoe(location, tile_pos, item.tool_level)
		
		Constants.ToolType.WATERING_CAN:
			success = _use_watering_can(location, tile_pos, item.tool_level)
		
		Constants.ToolType.AXE:
			success = _use_axe(location, tile_pos, item.tool_level)
		
		Constants.ToolType.PICKAXE:
			success = _use_pickaxe(location, tile_pos, item.tool_level)
		
		Constants.ToolType.SCYTHE:
			success = _use_scythe(location, tile_pos, item.tool_level)
	
	if success:
		# Gastar energia
		spend_energy(energy_cost)
		result.success = true
		result.action = Constants.ToolType.keys()[item.tool_type].to_lower()
		
		# Emitir sinais
		EventBus.player_used_tool.emit(item.tool_type, tile_pos)
		EventBus.play_sfx.emit("tool_%s" % result.action)
	
	return result


# =============================================================================
# INDIVIDUAL TOOL EFFECTS
# =============================================================================

## Enxada: Ara o solo
func _use_hoe(location: Node, tile_pos: Vector2i, level: Constants.ToolLevel) -> bool:
	# Se o tile já tem terrain feature, tentar interagir
	if location.has_terrain_feature(tile_pos):
		var feature: Node2D = location.get_terrain_feature(tile_pos)
		if feature.has_method("on_tool_use"):
			return feature.on_tool_use(Constants.ToolType.HOE, level)
		return false
	
	# Se o tile é arável, criar HoeDirt
	if location.has_method("is_tile_tillable") and location.is_tile_tillable(tile_pos):
		if location.has_method("till_soil"):
			return location.till_soil(tile_pos)
	
	return false


## Regador: Rega o solo
func _use_watering_can(location: Node, tile_pos: Vector2i, level: Constants.ToolLevel) -> bool:
	if location.has_terrain_feature(tile_pos):
		var feature: Node2D = location.get_terrain_feature(tile_pos)
		if feature.has_method("water"):
			feature.water()
			EventBus.soil_watered.emit(location.location_id, tile_pos)
			return true
	return false


## Machado: Corta árvores e troncos
func _use_axe(location: Node, tile_pos: Vector2i, level: Constants.ToolLevel) -> bool:
	if location.has_terrain_feature(tile_pos):
		var feature: Node2D = location.get_terrain_feature(tile_pos)
		if feature.has_method("on_tool_use"):
			return feature.on_tool_use(Constants.ToolType.AXE, level)
	
	# Verificar se tem objeto destrutível com machado
	if location.has_placed_object(tile_pos):
		var obj: Node2D = location.get_placed_object(tile_pos)
		if obj.has_method("on_tool_use"):
			return obj.on_tool_use(Constants.ToolType.AXE, level)
	
	return false


## Picareta: Quebra pedras e destrói solo arado
func _use_pickaxe(location: Node, tile_pos: Vector2i, level: Constants.ToolLevel) -> bool:
	# Terrain features primeiro
	if location.has_terrain_feature(tile_pos):
		var feature: Node2D = location.get_terrain_feature(tile_pos)
		if feature.has_method("on_tool_use"):
			return feature.on_tool_use(Constants.ToolType.PICKAXE, level)
	
	# Objetos
	if location.has_placed_object(tile_pos):
		var obj: Node2D = location.get_placed_object(tile_pos)
		if obj.has_method("on_tool_use"):
			return obj.on_tool_use(Constants.ToolType.PICKAXE, level)
	
	return false


## Foice: Colhe plantas maduras, corta grama
func _use_scythe(location: Node, tile_pos: Vector2i, level: Constants.ToolLevel) -> bool:
	if location.has_terrain_feature(tile_pos):
		var feature: Node2D = location.get_terrain_feature(tile_pos)
		
		# Se é HoeDirt com crop pronto, colher
		if feature is HoeDirt and feature.has_crop():
			var crop: Node2D = feature.crop
			if crop.has_method("is_ready_to_harvest") and crop.is_ready_to_harvest():
				return _harvest_crop(location, tile_pos, feature, crop)
		
		# Se é outro terrain feature destrutível com foice (grama)
		if feature.has_method("on_tool_use"):
			return feature.on_tool_use(Constants.ToolType.SCYTHE, level)
	
	return false


## Processa colheita de um crop.
func _harvest_crop(
	location: Node, tile_pos: Vector2i, dirt: HoeDirt, crop: Node2D
) -> bool:
	if not crop.has_method("harvest"):
		return false
	
	var farming_level := 0  # TODO: integrar com SkillSystem
	var fert_bonus := dirt.get_quality_bonus()
	var harvest_data: Dictionary = crop.harvest(farming_level, fert_bonus)
	
	if harvest_data.is_empty():
		return false
	
	# Adicionar item ao inventário
	var quality := harvest_data.get("quality", Constants.ItemQuality.NORMAL)
	InventorySystem.add_item_or_drop(
		harvest_data.item_id,
		harvest_data.quantity,
		quality
	)
	
	# XP de farming
	var xp: int = harvest_data.get("xp", 0)
	if xp > 0:
		EventBus.skill_xp_gained.emit(Constants.SkillType.FARMING, xp)
	
	# Emitir sinal
	EventBus.crop_harvested.emit(
		location.location_id, tile_pos,
		crop.get_crop_id() if crop.has_method("get_crop_id") else "",
		harvest_data.item_id, harvest_data.quantity
	)
	
	# Se a planta não renasce, remover
	if not crop.will_regrow():
		dirt.remove_crop()
		crop.queue_free()
	
	return true


# =============================================================================
# SEED PLANTING
# =============================================================================

func _use_seed(item: ItemData, tile_pos: Vector2i) -> Dictionary:
	var result := {"success": false, "action": "plant"}
	
	var location := LocationManager.get_current_game_location()
	if not location:
		return result
	
	# Verificar se tem HoeDirt no tile
	if not location.has_terrain_feature(tile_pos):
		return result
	
	var feature: Node2D = location.get_terrain_feature(tile_pos)
	if not feature is HoeDirt:
		return result
	
	var dirt: HoeDirt = feature as HoeDirt
	if not dirt.can_plant():
		return result
	
	# Obter dados do crop
	var crop_data := ItemDatabase.get_crop_for_seed(item.id)
	if not crop_data:
		return result
	
	# Verificar estação
	if not crop_data.can_grow_in_season(TimeSystem.current_season):
		result.action = "wrong_season"
		return result
	
	# Criar e plantar o crop
	var crop_node := Crop.new()
	crop_node.initialize(crop_data)
	
	if dirt.plant(crop_node):
		# Consumir 1 semente
		InventorySystem.consume_selected()
		
		EventBus.crop_planted.emit(location.location_id, tile_pos, crop_data.id)
		EventBus.play_sfx.emit("seed_plant")
		result.success = true
	else:
		crop_node.queue_free()
	
	return result


# =============================================================================
# FOOD CONSUMPTION
# =============================================================================

func _use_food(item: ItemData) -> Dictionary:
	var result := {"success": false, "action": "eat"}
	
	if item.energy_restored <= 0:
		return result
	
	if current_energy >= max_energy:
		result.action = "full_energy"
		return result
	
	# Consumir o item
	InventorySystem.consume_selected()
	
	# Restaurar energia
	restore_energy(item.energy_restored)
	
	EventBus.play_sfx.emit("eat")
	result.success = true
	return result


# =============================================================================
# OBJECT PLACEMENT
# =============================================================================

func _place_object(item: ItemData, tile_pos: Vector2i) -> Dictionary:
	var result := {"success": false, "action": "place"}
	
	var location := LocationManager.get_current_game_location()
	if not location:
		return result
	
	if not location.is_tile_free(tile_pos):
		return result
	
	if item.placed_scene:
		var obj: Node2D = item.placed_scene.instantiate()
		if location.place_object(tile_pos, obj):
			InventorySystem.consume_selected()
			EventBus.play_sfx.emit("place_object")
			result.success = true
		else:
			obj.queue_free()
	
	return result


# =============================================================================
# ENERGY
# =============================================================================

func spend_energy(amount: int) -> void:
	current_energy = maxf(0.0, current_energy - amount)
	EventBus.player_energy_changed.emit(current_energy, max_energy)
	
	if current_energy <= 0:
		EventBus.player_passed_out.emit("no_energy")


func restore_energy(amount: float) -> void:
	current_energy = minf(max_energy, current_energy + amount)
	EventBus.player_energy_changed.emit(current_energy, max_energy)


func restore_full_energy() -> void:
	current_energy = max_energy
	EventBus.player_energy_changed.emit(current_energy, max_energy)


func get_energy_percentage() -> float:
	return current_energy / max_energy if max_energy > 0 else 0.0


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	DatabaseManager.query(
		"UPDATE player SET energy=%.1f, max_energy=%.1f WHERE id=1;" % [
			current_energy, max_energy
		]
	)


func load_data() -> void:
	var data := DatabaseManager.query("SELECT energy, max_energy FROM player WHERE id=1;")
	if data.size() > 0:
		current_energy = data[0].get("energy", 270.0)
		max_energy = data[0].get("max_energy", 270.0)
