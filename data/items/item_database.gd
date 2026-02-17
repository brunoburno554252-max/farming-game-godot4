## data/items/item_database.gd
## ItemDatabase — Registro de todos os itens do jogo.
## Carrega todos os ItemData resources e os indexa por ID.
## Acessado como: ItemDatabase.get_item("parsnip")
##
## NOTA: Este script é um Autoload secundário OU pode ser acessado
## como um helper estático. Para simplificar, funciona como classe
## com métodos estáticos e deve ser inicializado pelo GameManager.
class_name ItemDatabase
extends RefCounted


# =============================================================================
# STORAGE
# =============================================================================

## Dicionário de todos os itens: { item_id: ItemData }
static var _items: Dictionary = {}

## Dicionário de crops: { crop_id: CropData }
static var _crops: Dictionary = {}

## Se já foi inicializado
static var _initialized: bool = false


# =============================================================================
# INITIALIZATION
# =============================================================================

## Carrega todos os ItemData e CropData resources das pastas de dados.
static func initialize() -> void:
	if _initialized:
		return
	
	_load_items_from_directory("res://data/items/")
	_load_crops_from_directory("res://data/crops/")
	
	_initialized = true
	print("[ItemDatabase] Carregados %d itens e %d crops." % [_items.size(), _crops.size()])


## Carrega todos os .tres de uma pasta como ItemData.
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


## Carrega todos os .tres de uma pasta como CropData.
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
# ITEM QUERIES
# =============================================================================

## Retorna um ItemData pelo ID (ou null se não existir).
static func get_item(item_id: String) -> ItemData:
	return _items.get(item_id, null)


## Retorna se um item existe.
static func has_item(item_id: String) -> bool:
	return _items.has(item_id)


## Retorna todos os itens de um tipo específico.
static func get_items_by_type(type: Constants.ItemType) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in _items.values():
		if (item as ItemData).item_type == type:
			result.append(item)
	return result


## Retorna todos os itens vendidos em uma loja.
static func get_shop_items(shop_id: String) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in _items.values():
		if (item as ItemData).buy_price > 0:
			result.append(item)
	return result


## Retorna o preço de venda de um item.
static func get_sell_price(
	item_id: String,
	quality: Constants.ItemQuality = Constants.ItemQuality.NORMAL
) -> int:
	var item := get_item(item_id)
	if item:
		return item.get_sell_price(quality)
	return 0


# =============================================================================
# CROP QUERIES
# =============================================================================

## Retorna um CropData pelo ID.
static func get_crop(crop_id: String) -> CropData:
	return _crops.get(crop_id, null)


## Retorna o CropData associado a uma semente.
static func get_crop_for_seed(seed_item_id: String) -> CropData:
	var item := get_item(seed_item_id)
	if item and item.is_seed() and item.plants_crop_id != "":
		return get_crop(item.plants_crop_id)
	return null


## Retorna se um crop existe.
static func has_crop(crop_id: String) -> bool:
	return _crops.has(crop_id)


## Retorna crops disponíveis numa estação.
static func get_crops_for_season(season: Constants.Season) -> Array[CropData]:
	var result: Array[CropData] = []
	for crop in _crops.values():
		if (crop as CropData).can_grow_in_season(season):
			result.append(crop)
	return result


# =============================================================================
# REGISTRATION (para mods/expansões)
# =============================================================================

## Registra um item manualmente.
static func register_item(item: ItemData) -> void:
	_items[item.id] = item


## Registra um crop manualmente.
static func register_crop(crop: CropData) -> void:
	_crops[crop.id] = crop
