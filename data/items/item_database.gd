## data/items/item_database.gd
## ItemDatabase — Registro central de todos os itens e crops do jogo.
## Carrega de .tres E registra defaults programaticamente.
## Acessado como: ItemDatabase.get_item("parsnip")
##
## Estratégia: Primeiro tenta carregar .tres de res://data/items/ e res://data/crops/.
## Se nenhum item foi carregado (projeto sem assets), registra defaults programáticos.
## Isso garante que o jogo SEMPRE funciona, com ou sem .tres files.
class_name ItemDatabase
extends RefCounted


# =============================================================================
# STORAGE
# =============================================================================

static var _items: Dictionary = {}
static var _crops: Dictionary = {}
static var _initialized: bool = false


# =============================================================================
# INITIALIZATION
# =============================================================================

static func initialize() -> void:
	if _initialized:
		return
	
	# 1. Tentar carregar .tres files
	_load_items_from_directory("res://data/items/")
	_load_crops_from_directory("res://data/crops/")
	
	# 2. Se não encontrou nada, registrar defaults
	if _items.is_empty():
		_register_default_items()
	if _crops.is_empty():
		_register_default_crops()
	
	_initialized = true
	print("[ItemDatabase] Carregados %d itens e %d crops." % [_items.size(), _crops.size()])


# =============================================================================
# FILE LOADING
# =============================================================================

static func _load_items_from_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(path + file_name)
			if res is ItemData:
				_items[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


static func _load_crops_from_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(path + file_name)
			if res is CropData:
				_crops[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


# =============================================================================
# QUERY
# =============================================================================

static func get_item(item_id: String) -> ItemData:
	return _items.get(item_id, null)

static func has_item(item_id: String) -> bool:
	return _items.has(item_id)

static func get_crop(crop_id: String) -> CropData:
	return _crops.get(crop_id, null)

static func has_crop(crop_id: String) -> bool:
	return _crops.has(crop_id)

static func get_all_items() -> Array:
	return _items.values()

static func get_all_crops() -> Array:
	return _crops.values()

## Retorna itens filtrados por tipo.
static func get_items_by_type(item_type: Constants.ItemType) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in _items.values():
		if item.item_type == item_type:
			result.append(item)
	return result

## Retorna crops válidos para uma estação.
static func get_crops_for_season(season: Constants.Season) -> Array[CropData]:
	var result: Array[CropData] = []
	for crop in _crops.values():
		if season in crop.valid_seasons:
			result.append(crop)
	return result


# =============================================================================
# PROGRAMMATIC ITEM REGISTRATION — DEFAULT CONTENT
# =============================================================================

static func _register_default_items() -> void:
	print("[ItemDatabase] Registrando itens default programaticamente...")
	
	# ====== TOOLS ======
	_reg_tool("hoe", "Enxada", "Usada para arar a terra.", Constants.ToolType.HOE)
	_reg_tool("watering_can", "Regador", "Rega o solo para as plantas crescerem.", Constants.ToolType.WATERING_CAN)
	_reg_tool("axe", "Machado", "Corta árvores e madeira.", Constants.ToolType.AXE)
	_reg_tool("pickaxe", "Picareta", "Quebra pedras e minérios.", Constants.ToolType.PICKAXE)
	_reg_tool("scythe", "Foice", "Corta grama e colhe certas plantas.", Constants.ToolType.SCYTHE)
	_reg_tool("fishing_rod", "Vara de Pesca", "Usada para pescar nos rios e lagos.", Constants.ToolType.FISHING_ROD)
	_reg_tool("sword", "Espada", "Arma básica para combate.", Constants.ToolType.SWORD)
	
	# ====== SEEDS (Spring) ======
	_reg_seed("parsnip_seeds", "Sem. Cenoura-branca", "Sementes de cenoura-branca. Leva 4 dias.", 20, "parsnip")
	_reg_seed("potato_seeds", "Sem. Batata", "Sementes de batata. Leva 6 dias.", 50, "potato")
	_reg_seed("cauliflower_seeds", "Sem. Couve-flor", "Sementes de couve-flor. Leva 12 dias.", 80, "cauliflower")
	_reg_seed("green_bean_seeds", "Sem. Feijão", "Sementes de feijão. Leva 10 dias, renasce.", 60, "green_bean")
	_reg_seed("kale_seeds", "Sem. Couve", "Sementes de couve. Leva 6 dias.", 70, "kale")
	
	# ====== SEEDS (Summer) ======
	_reg_seed("melon_seeds", "Sem. Melão", "Sementes de melão. Leva 12 dias.", 80, "melon")
	_reg_seed("tomato_seeds", "Sem. Tomate", "Sementes de tomate. Leva 11 dias, renasce.", 50, "tomato")
	_reg_seed("blueberry_seeds", "Sem. Mirtilo", "Sementes de mirtilo. Leva 13 dias, renasce.", 80, "blueberry")
	_reg_seed("corn_seeds", "Sem. Milho", "Sementes de milho. Leva 14 dias, renasce.", 150, "corn")
	_reg_seed("hot_pepper_seeds", "Sem. Pimenta", "Sementes de pimenta. Leva 5 dias, renasce.", 40, "hot_pepper")
	
	# ====== SEEDS (Fall) ======
	_reg_seed("pumpkin_seeds", "Sem. Abóbora", "Sementes de abóbora. Leva 13 dias.", 100, "pumpkin")
	_reg_seed("cranberry_seeds", "Sem. Oxicoco", "Sementes de oxicoco. Leva 7 dias, renasce.", 240, "cranberry")
	_reg_seed("eggplant_seeds", "Sem. Berinjela", "Sementes de berinjela. Leva 5 dias, renasce.", 20, "eggplant")
	_reg_seed("yam_seeds", "Sem. Inhame", "Sementes de inhame. Leva 10 dias.", 60, "yam")
	
	# ====== CROP HARVESTS (Spring) ======
	_reg_crop_item("parsnip", "Cenoura-branca", "Um vegetal com raiz doce e crocante.", 35)
	_reg_crop_item("potato", "Batata", "Versátil e nutritiva.", 80)
	_reg_crop_item("cauliflower", "Couve-flor", "Uma bela cabeça de couve-flor.", 175)
	_reg_crop_item("green_bean", "Feijão", "Feijão verde e crocante.", 40)
	_reg_crop_item("kale", "Couve", "Folhas verdes muito nutritivas.", 110)
	
	# ====== CROP HARVESTS (Summer) ======
	_reg_crop_item("melon", "Melão", "Um melão doce e suculento.", 250)
	_reg_crop_item("tomato", "Tomate", "Tomate vermelho e maduro.", 60)
	_reg_crop_item("blueberry", "Mirtilo", "Frutinhas doces e azuis.", 50)
	_reg_crop_item("corn", "Milho", "Uma espiga de milho dourada.", 50)
	_reg_crop_item("hot_pepper", "Pimenta", "Cuidado, é bem picante!", 40)
	
	# ====== CROP HARVESTS (Fall) ======
	_reg_crop_item("pumpkin", "Abóbora", "Uma abóbora grande e laranja.", 320)
	_reg_crop_item("cranberry", "Oxicoco", "Frutinhas vermelhas e ácidas.", 75)
	_reg_crop_item("eggplant", "Berinjela", "Uma berinjela roxa e brilhante.", 60)
	_reg_crop_item("yam", "Inhame", "Um tubérculo de sabor terroso.", 160)
	
	# ====== RESOURCES ======
	_reg_resource("wood", "Madeira", "Material básico de construção.", 2)
	_reg_resource("stone", "Pedra", "Material sólido para construção.", 2)
	_reg_resource("fiber", "Fibra", "Fibra vegetal útil para crafting.", 1)
	_reg_resource("coal", "Carvão", "Combustível para fornalhas.", 15)
	_reg_resource("copper_ore", "Minério de Cobre", "Pode ser fundido em barras.", 5)
	_reg_resource("iron_ore", "Minério de Ferro", "Pode ser fundido em barras.", 10)
	_reg_resource("gold_ore", "Minério de Ouro", "Pode ser fundido em barras.", 25)
	_reg_resource("copper_bar", "Barra de Cobre", "Uma barra de cobre refinado.", 60)
	_reg_resource("iron_bar", "Barra de Ferro", "Uma barra de ferro refinado.", 120)
	_reg_resource("gold_bar", "Barra de Ouro", "Uma barra de ouro reluzente.", 250)
	_reg_resource("sap", "Seiva", "Substância pegajosa das árvores.", 2)
	_reg_resource("hardwood", "Madeira de Lei", "Madeira dura e resistente.", 15)
	_reg_resource("clay", "Argila", "Material maleável encontrado cavando.", 20)
	
	# ====== FOOD ======
	_reg_food("fried_egg", "Ovo Frito", "Simples e satisfatório.", 35, 50.0)
	_reg_food("salad", "Salada", "Uma porção saudável de verduras.", 110, 80.0)
	_reg_food("bread", "Pão", "Um pão caseiro fresquinho.", 60, 60.0)
	_reg_food("cheese", "Queijo", "Queijo envelhecido saboroso.", 200, 100.0)
	_reg_food("field_snack", "Lanche do Campo", "Feito de sementes e nozes.", 20, 45.0)
	
	# ====== FORAGE ======
	_reg_forage("wild_horseradish", "Raiz-forte Selvagem", "Encontrada na primavera.", 50)
	_reg_forage("daffodil", "Narciso", "Uma flor amarela da primavera.", 30)
	_reg_forage("leek", "Alho-poró", "Um vegetal selvagem da primavera.", 60)
	_reg_forage("dandelion", "Dente-de-leão", "Flor comum, mas útil.", 40)
	_reg_forage("common_mushroom", "Cogumelo Comum", "Encontrado no outono.", 40)
	_reg_forage("wild_plum", "Ameixa Selvagem", "Doce e suculenta.", 80)
	
	# ====== CRAFTABLE/PLACEABLE ======
	_reg_craftable("chest", "Baú", "Armazena itens. Coloque na fazenda.", 0)
	_reg_craftable("sprinkler", "Irrigador", "Rega 4 tiles adjacentes toda manhã.", 0)
	_reg_craftable("quality_sprinkler", "Irrigador Qualidade", "Rega 8 tiles ao redor.", 0)
	_reg_craftable("scarecrow", "Espantalho", "Protege plantações de corvos.", 0)
	_reg_craftable("furnace", "Fornalha", "Funde minérios em barras.", 0)
	_reg_craftable("seed_maker", "Produtor de Sementes", "Transforma colheitas em sementes.", 0)
	_reg_craftable("bee_house", "Casa de Abelhas", "Produz mel ao longo do tempo.", 0)
	_reg_craftable("keg", "Barril", "Fermenta frutas e vegetais.", 0)
	_reg_craftable("preserves_jar", "Pote de Conserva", "Faz geleia e picles.", 0)


# =============================================================================
# PROGRAMMATIC CROP REGISTRATION
# =============================================================================

static func _register_default_crops() -> void:
	print("[ItemDatabase] Registrando crops default programaticamente...")
	
	# ====== SPRING CROPS ======
	_reg_crop("parsnip", "Cenoura-branca", "parsnip_seeds", "parsnip",
		[1, 1, 1, 1], [Constants.Season.SPRING], false, 0, 1, 1, 8, 35)
	
	_reg_crop("potato", "Batata", "potato_seeds", "potato",
		[1, 1, 1, 2, 1], [Constants.Season.SPRING], false, 0, 1, 1, 12, 80)
	
	_reg_crop("cauliflower", "Couve-flor", "cauliflower_seeds", "cauliflower",
		[1, 2, 4, 4, 1], [Constants.Season.SPRING], false, 0, 1, 1, 23, 175)
	
	_reg_crop("green_bean", "Feijão", "green_bean_seeds", "green_bean",
		[1, 1, 1, 3, 4], [Constants.Season.SPRING], true, 3, 4, 1, 1, 40)
	
	_reg_crop("kale", "Couve", "kale_seeds", "kale",
		[1, 2, 2, 1], [Constants.Season.SPRING], false, 0, 1, 1, 17, 110)
	
	# ====== SUMMER CROPS ======
	_reg_crop("melon", "Melão", "melon_seeds", "melon",
		[1, 2, 3, 3, 3], [Constants.Season.SUMMER], false, 0, 1, 1, 23, 250)
	
	_reg_crop("tomato", "Tomate", "tomato_seeds", "tomato",
		[2, 2, 2, 2, 3], [Constants.Season.SUMMER], true, 4, 4, 1, 1, 60)
	
	_reg_crop("blueberry", "Mirtilo", "blueberry_seeds", "blueberry",
		[1, 3, 3, 4, 2], [Constants.Season.SUMMER], true, 4, 4, 1, 3, 50)
	
	_reg_crop("corn", "Milho", "corn_seeds", "corn",
		[2, 3, 3, 3, 3], [Constants.Season.SUMMER, Constants.Season.FALL], true, 4, 4, 1, 1, 50)
	
	_reg_crop("hot_pepper", "Pimenta", "hot_pepper_seeds", "hot_pepper",
		[1, 1, 1, 1, 1], [Constants.Season.SUMMER], true, 3, 4, 1, 1, 40)
	
	# ====== FALL CROPS ======
	_reg_crop("pumpkin", "Abóbora", "pumpkin_seeds", "pumpkin",
		[1, 2, 3, 4, 3], [Constants.Season.FALL], false, 0, 1, 1, 31, 320)
	
	_reg_crop("cranberry", "Oxicoco", "cranberry_seeds", "cranberry",
		[1, 2, 1, 1, 2], [Constants.Season.FALL], true, 5, 4, 1, 2, 75)
	
	_reg_crop("eggplant", "Berinjela", "eggplant_seeds", "eggplant",
		[1, 1, 1, 1, 1], [Constants.Season.FALL], true, 5, 4, 1, 1, 60)
	
	_reg_crop("yam", "Inhame", "yam_seeds", "yam",
		[1, 3, 3, 3], [Constants.Season.FALL], false, 0, 1, 1, 18, 160)


# =============================================================================
# HELPER REGISTRATION FUNCTIONS
# =============================================================================

static func _reg_tool(id: String, display: String, desc: String, tool_type: Constants.ToolType) -> void:
	var item := ItemData.new()
	item.id = id
	item.display_name = display
	item.description = desc
	item.item_type = Constants.ItemType.TOOL
	item.category = "tool"
	item.tool_type = tool_type
	item.max_stack = 1
	item.is_stackable = false
	item.is_sellable = false
	item.sell_price = 0
	_items[id] = item


static func _reg_seed(id: String, display: String, desc: String, buy: int, crop_id: String) -> void:
	var item := ItemData.new()
	item.id = id
	item.display_name = display
	item.description = desc
	item.item_type = Constants.ItemType.SEED
	item.category = "seed"
	item.buy_price = buy
	item.sell_price = int(buy * 0.5)
	item.plants_crop_id = crop_id
	_items[id] = item


static func _reg_crop_item(id: String, display: String, desc: String, sell: int) -> void:
	var item := ItemData.new()
	item.id = id
	item.display_name = display
	item.description = desc
	item.item_type = Constants.ItemType.CROP_HARVEST
	item.category = "crop"
	item.sell_price = sell
	_items[id] = item


static func _reg_resource(id: String, display: String, desc: String, sell: int) -> void:
	var item := ItemData.new()
	item.id = id
	item.display_name = display
	item.description = desc
	item.item_type = Constants.ItemType.RESOURCE
	item.category = "resource"
	item.sell_price = sell
	_items[id] = item


static func _reg_food(id: String, display: String, desc: String, sell: int, energy: float) -> void:
	var item := ItemData.new()
	item.id = id
	item.display_name = display
	item.description = desc
	item.item_type = Constants.ItemType.FOOD
	item.category = "food"
	item.sell_price = sell
	item.energy_restored = energy
	_items[id] = item


static func _reg_forage(id: String, display: String, desc: String, sell: int) -> void:
	var item := ItemData.new()
	item.id = id
	item.display_name = display
	item.description = desc
	item.item_type = Constants.ItemType.CROP_HARVEST
	item.category = "forage"
	item.sell_price = sell
	_items[id] = item


static func _reg_craftable(id: String, display: String, desc: String, sell: int) -> void:
	var item := ItemData.new()
	item.id = id
	item.display_name = display
	item.description = desc
	item.item_type = Constants.ItemType.CRAFTABLE
	item.category = "craftable"
	item.sell_price = sell
	item.is_placeable = true
	_items[id] = item


static func _reg_crop(
	id: String, display: String, seed_id: String, harvest_id: String,
	phases: Array, seasons: Array, regrows: bool, regrow_days: int,
	regrow_phase: int, min_h: int, max_h: int, xp: int, base_sell: int
) -> void:
	var crop := CropData.new()
	crop.id = id
	crop.display_name = display
	crop.seed_item_id = seed_id
	crop.harvest_item_id = harvest_id
	crop.phase_days = []
	for p in phases:
		crop.phase_days.append(p)
	crop.valid_seasons = []
	for s in seasons:
		crop.valid_seasons.append(s)
	crop.regrows_after_harvest = regrows
	crop.days_to_regrow = regrow_days
	crop.regrow_phase = regrow_phase
	crop.min_harvest = min_h
	crop.max_harvest = max_h
	crop.harvest_xp = xp
	crop.base_sell_price = base_sell
	crop.seed_buy_price = get_item(seed_id).buy_price if has_item(seed_id) else 0
	_crops[id] = crop
