## autoloads/crafting_system.gd
## CraftingSystem — Gerencia receitas e crafting.
## Verifica ingredientes no inventário, consome e produz itens.
## Equivalente ao CraftingRecipe do Stardew Valley.
extends Node


# =============================================================================
# RECIPE DATA
# =============================================================================

## {recipe_id: {display_name, ingredients: {item_id: qty}, result_id, result_qty, unlock_level, unlock_skill}}
var _recipes: Dictionary = {}

## IDs de receitas desbloqueadas pelo jogador
var _unlocked: Dictionary = {}


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.skill_level_up.connect(_on_skill_level_up)


func initialize_new_game() -> void:
	_recipes.clear()
	_unlocked.clear()
	_register_default_recipes()
	# Unlock starter recipes
	for recipe_id in _recipes:
		var recipe: Dictionary = _recipes[recipe_id]
		if recipe.get("unlock_level", 0) <= 0:
			_unlocked[recipe_id] = true


# =============================================================================
# RECIPES
# =============================================================================

func _register_default_recipes() -> void:
	# Farming / Basic
	_reg("chest", "Baú", {"wood": 50}, "chest", 1, 0, Constants.SkillType.FARMING)
	_reg("furnace", "Fornalha", {"copper_ore": 20, "stone": 25}, "furnace", 1, 0, Constants.SkillType.MINING)
	_reg("scarecrow", "Espantalho", {"wood": 50, "coal": 1, "fiber": 20}, "scarecrow", 1, 0, Constants.SkillType.FARMING)
	_reg("sprinkler", "Irrigador", {"copper_bar": 1, "iron_bar": 1}, "sprinkler", 1, 2, Constants.SkillType.FARMING)
	_reg("quality_sprinkler", "Irrigador Qualidade", {"iron_bar": 1, "gold_bar": 1}, "quality_sprinkler", 1, 6, Constants.SkillType.FARMING)
	_reg("bee_house", "Casa de Abelhas", {"wood": 40, "coal": 8, "iron_bar": 1}, "bee_house", 1, 3, Constants.SkillType.FARMING)
	_reg("keg", "Barril", {"wood": 30, "copper_bar": 1, "iron_bar": 1}, "keg", 1, 8, Constants.SkillType.FARMING)
	_reg("preserves_jar", "Pote de Conserva", {"wood": 50, "stone": 40, "coal": 8}, "preserves_jar", 1, 4, Constants.SkillType.FARMING)
	_reg("seed_maker", "Produtor de Sementes", {"wood": 25, "coal": 10, "gold_bar": 1}, "seed_maker", 1, 9, Constants.SkillType.FARMING)
	
	# Food
	_reg("field_snack", "Lanche do Campo", {"parsnip_seeds": 1, "fiber": 2}, "field_snack", 1, 0, Constants.SkillType.FORAGING)
	_reg("fried_egg", "Ovo Frito", {"field_snack": 2}, "fried_egg", 1, 1, Constants.SkillType.FARMING)
	_reg("salad", "Salada", {"leek": 1, "dandelion": 1}, "salad", 1, 0, Constants.SkillType.FORAGING)
	
	# Smelting (via furnace, mas registrado aqui para controle)
	_reg("smelt_copper", "Fundir Cobre", {"copper_ore": 5, "coal": 1}, "copper_bar", 1, 0, Constants.SkillType.MINING)
	_reg("smelt_iron", "Fundir Ferro", {"iron_ore": 5, "coal": 1}, "iron_bar", 1, 0, Constants.SkillType.MINING)
	_reg("smelt_gold", "Fundir Ouro", {"gold_ore": 5, "coal": 1}, "gold_bar", 1, 0, Constants.SkillType.MINING)


func _reg(id: String, display: String, ingredients: Dictionary, result: String, qty: int, level: int, skill: Constants.SkillType) -> void:
	_recipes[id] = {
		"id": id,
		"display_name": display,
		"ingredients": ingredients,
		"result_id": result,
		"result_qty": qty,
		"unlock_level": level,
		"unlock_skill": skill,
	}


# =============================================================================
# QUERIES
# =============================================================================

func get_recipe(recipe_id: String) -> Dictionary:
	return _recipes.get(recipe_id, {})

func is_unlocked(recipe_id: String) -> bool:
	return _unlocked.has(recipe_id)

## Retorna todas as receitas desbloqueadas.
func get_unlocked_recipes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in _unlocked:
		if _recipes.has(id):
			result.append(_recipes[id])
	return result

## Verifica se o jogador tem os ingredientes para uma receita.
func can_craft(recipe_id: String) -> bool:
	if not _recipes.has(recipe_id) or not _unlocked.has(recipe_id):
		return false
	var recipe: Dictionary = _recipes[recipe_id]
	for item_id in recipe.ingredients:
		var needed: int = recipe.ingredients[item_id]
		if not InventorySystem.has_item(item_id, needed):
			return false
	return true


# =============================================================================
# CRAFTING
# =============================================================================

## Executa o crafting. Retorna true se sucesso.
func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false
	
	var recipe: Dictionary = _recipes[recipe_id]
	
	# Consumir ingredientes
	for item_id in recipe.ingredients:
		var needed: int = recipe.ingredients[item_id]
		InventorySystem.remove_item(item_id, needed)
	
	# Produzir resultado
	var leftover := InventorySystem.add_item(recipe.result_id, recipe.result_qty)
	
	if leftover > 0:
		EventBus.show_notification.emit("Inventário cheio! Itens foram perdidos.", null)
	else:
		var item := ItemDatabase.get_item(recipe.result_id)
		var display := item.display_name if item else recipe.result_id
		EventBus.show_notification.emit("Craftou %s!" % display, null)
		EventBus.show_item_obtained.emit(recipe.result_id, recipe.result_qty)
	
	EventBus.play_sfx.emit("craft")
	return true


# =============================================================================
# UNLOCKING
# =============================================================================

func unlock_recipe(recipe_id: String) -> void:
	if _unlocked.has(recipe_id):
		return
	_unlocked[recipe_id] = true
	EventBus.recipe_unlocked.emit(recipe_id)
	var recipe := get_recipe(recipe_id)
	if not recipe.is_empty():
		EventBus.show_notification.emit("Nova receita: %s!" % recipe.display_name, null)


func _on_skill_level_up(skill: Constants.SkillType, new_level: int) -> void:
	# Desbloquear receitas que requerem este nível de skill
	for recipe_id in _recipes:
		if _unlocked.has(recipe_id):
			continue
		var recipe: Dictionary = _recipes[recipe_id]
		if int(recipe.unlock_skill) == int(skill) and recipe.unlock_level <= new_level:
			unlock_recipe(recipe_id)


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	for recipe_id in _unlocked:
		DatabaseManager.query(
			"INSERT OR REPLACE INTO unlocked_recipes (recipe_id) VALUES ('%s');" % recipe_id
		)

func load_data() -> void:
	_recipes.clear()
	_unlocked.clear()
	_register_default_recipes()
	var rows := DatabaseManager.query("SELECT * FROM unlocked_recipes;")
	for row in rows:
		_unlocked[row.recipe_id] = true
