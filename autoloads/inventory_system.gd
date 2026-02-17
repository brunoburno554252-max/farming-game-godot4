## autoloads/inventory_system.gd
## InventorySystem — Gerencia inventário, hotbar, e ouro do jogador.
## Suporta qualidade de itens, stack limits, ferramentas, swap/move de slots.
extends Node


# =============================================================================
# SLOT STRUCTURE
# =============================================================================

## Cada slot é um Dictionary com:
## {
##   "item_id": String,    — ID do item (vazio = slot livre)
##   "quantity": int,       — Quantidade no stack
##   "quality": int,        — Constants.ItemQuality (0 = NORMAL)
## }

const EMPTY_SLOT: Dictionary = {"item_id": "", "quantity": 0, "quality": 0}


# =============================================================================
# STATE
# =============================================================================

var gold: int = 500
var hotbar_selected: int = 0
var _slots: Array[Dictionary] = []


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	pass


func initialize_new_game() -> void:
	gold = 500
	hotbar_selected = 0
	_slots.clear()
	_slots.resize(Constants.TOTAL_INVENTORY_SLOTS)
	for i in range(_slots.size()):
		_slots[i] = EMPTY_SLOT.duplicate()
	
	# Ferramentas iniciais na hotbar
	_set_slot(0, "hoe", 1, 0)
	_set_slot(1, "watering_can", 1, 0)
	_set_slot(2, "axe", 1, 0)
	_set_slot(3, "pickaxe", 1, 0)
	_set_slot(4, "scythe", 1, 0)
	# Slot 5-11: vazio (resto da hotbar)
	# Dar sementes iniciais
	_set_slot(5, "parsnip_seeds", 15, 0)


# =============================================================================
# ADD ITEMS
# =============================================================================

## Adiciona um item ao inventário. Respeita max_stack e qualidade.
## Itens de qualidade diferente NÃO stackam juntos.
## Retorna a quantidade que NÃO coube (0 = tudo adicionado).
func add_item(
	item_id: String,
	quantity: int = 1,
	quality: Constants.ItemQuality = Constants.ItemQuality.NORMAL
) -> int:
	if item_id == "" or quantity <= 0:
		return quantity
	
	var remaining := quantity
	var max_stack := _get_max_stack(item_id)
	var quality_int := int(quality)
	
	# 1. Tentar stackar em slots existentes com mesmo item + qualidade
	if max_stack > 1:
		for i in range(_slots.size()):
			if remaining <= 0:
				break
			if _slots[i].item_id == item_id and _slots[i].quality == quality_int:
				var space: int = max_stack - _slots[i].quantity
				if space > 0:
					var to_add := mini(remaining, space)
					_slots[i].quantity += to_add
					remaining -= to_add
	
	# 2. Colocar em slots vazios
	for i in range(_slots.size()):
		if remaining <= 0:
			break
		if _slots[i].item_id == "":
			var to_add := mini(remaining, max_stack)
			_slots[i] = {"item_id": item_id, "quantity": to_add, "quality": quality_int}
			remaining -= to_add
	
	# Emitir sinais
	var added := quantity - remaining
	if added > 0:
		EventBus.inventory_changed.emit()
		EventBus.item_added.emit(item_id, added)
		EventBus.show_item_obtained.emit(item_id, added)
	
	return remaining  # 0 se tudo coube


## Adiciona um item e descarta se não couber.
func add_item_or_drop(
	item_id: String,
	quantity: int = 1,
	quality: Constants.ItemQuality = Constants.ItemQuality.NORMAL
) -> void:
	var leftover := add_item(item_id, quantity, quality)
	if leftover > 0:
		# TODO: dropar no chão (na Fase 4)
		push_warning("[Inventory] %d x %s não couberam!" % [leftover, item_id])


# =============================================================================
# REMOVE ITEMS
# =============================================================================

## Remove uma quantidade de um item (qualquer qualidade).
## Retorna true se conseguiu remover tudo.
func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not has_item(item_id, quantity):
		return false
	
	var remaining := quantity
	for i in range(_slots.size()):
		if remaining <= 0:
			break
		if _slots[i].item_id == item_id:
			var to_remove := mini(remaining, _slots[i].quantity)
			_slots[i].quantity -= to_remove
			remaining -= to_remove
			if _slots[i].quantity <= 0:
				_slots[i] = EMPTY_SLOT.duplicate()
	
	EventBus.inventory_changed.emit()
	EventBus.item_removed.emit(item_id, quantity)
	return true


## Remove um item de um slot específico.
func remove_from_slot(slot_index: int, quantity: int = 1) -> bool:
	if not _is_valid_slot(slot_index):
		return false
	if _slots[slot_index].item_id == "" or _slots[slot_index].quantity < quantity:
		return false
	
	var item_id: String = _slots[slot_index].item_id
	_slots[slot_index].quantity -= quantity
	if _slots[slot_index].quantity <= 0:
		_slots[slot_index] = EMPTY_SLOT.duplicate()
	
	EventBus.inventory_changed.emit()
	EventBus.item_removed.emit(item_id, quantity)
	return true


## Consome 1 do item selecionado na hotbar. Retorna o item_id consumido.
func consume_selected() -> String:
	var slot := _slots[hotbar_selected]
	if slot.item_id == "":
		return ""
	
	var item_id: String = slot.item_id
	remove_from_slot(hotbar_selected, 1)
	return item_id


# =============================================================================
# QUERIES
# =============================================================================

## Verifica se o jogador tem pelo menos X de um item (soma de todos os slots).
func has_item(item_id: String, quantity: int = 1) -> bool:
	return count_item(item_id) >= quantity


## Conta o total de um item no inventário.
func count_item(item_id: String) -> int:
	var total := 0
	for slot in _slots:
		if slot.item_id == item_id:
			total += slot.quantity
	return total


## Retorna os dados de um slot.
func get_slot(index: int) -> Dictionary:
	if _is_valid_slot(index):
		return _slots[index]
	return EMPTY_SLOT.duplicate()


## Retorna o item selecionado na hotbar.
func get_selected_slot() -> Dictionary:
	return get_slot(hotbar_selected)


## Retorna o ID do item selecionado.
func get_selected_item_id() -> String:
	return get_slot(hotbar_selected).item_id


## Retorna o ItemData do item selecionado (ou null).
func get_selected_item_data() -> ItemData:
	var item_id := get_selected_item_id()
	if item_id != "":
		return ItemDatabase.get_item(item_id)
	return null


## Verifica se o inventário está cheio.
func is_full() -> bool:
	for slot in _slots:
		if slot.item_id == "":
			return false
	return true


## Retorna quantos slots livres restam.
func get_free_slots_count() -> int:
	var count := 0
	for slot in _slots:
		if slot.item_id == "":
			count += 1
	return count


# =============================================================================
# SLOT MANIPULATION
# =============================================================================

## Troca o conteúdo de dois slots (drag & drop).
func swap_slots(from_index: int, to_index: int) -> void:
	if not _is_valid_slot(from_index) or not _is_valid_slot(to_index):
		return
	if from_index == to_index:
		return
	
	# Se são o mesmo item + qualidade, tentar merge
	if _slots[from_index].item_id == _slots[to_index].item_id and \
	   _slots[from_index].quality == _slots[to_index].quality and \
	   _slots[to_index].item_id != "":
		var max_stack := _get_max_stack(_slots[to_index].item_id)
		var space: int = max_stack - _slots[to_index].quantity
		if space >= _slots[from_index].quantity:
			# Merge completo
			_slots[to_index].quantity += _slots[from_index].quantity
			_slots[from_index] = EMPTY_SLOT.duplicate()
		else:
			# Merge parcial
			_slots[to_index].quantity = max_stack
			_slots[from_index].quantity -= space
	else:
		# Swap simples
		var temp := _slots[from_index].duplicate()
		_slots[from_index] = _slots[to_index].duplicate()
		_slots[to_index] = temp
	
	EventBus.inventory_changed.emit()


# =============================================================================
# HOTBAR
# =============================================================================

## Seleciona um slot da hotbar (0-11).
func select_hotbar(index: int) -> void:
	if index < 0 or index >= Constants.HOTBAR_SIZE:
		return
	hotbar_selected = index
	var item_id := _slots[hotbar_selected].item_id
	EventBus.hotbar_selection_changed.emit(hotbar_selected, item_id)


## Avança a seleção da hotbar.
func hotbar_next() -> void:
	select_hotbar((hotbar_selected + 1) % Constants.HOTBAR_SIZE)


## Retrocede a seleção da hotbar.
func hotbar_prev() -> void:
	select_hotbar((hotbar_selected - 1 + Constants.HOTBAR_SIZE) % Constants.HOTBAR_SIZE)


# =============================================================================
# GOLD
# =============================================================================

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		EventBus.gold_changed.emit(gold, -amount)
		return true
	return false


func earn_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold, amount)


func can_afford(amount: int) -> bool:
	return gold >= amount


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	# Salvar gold
	DatabaseManager.query(
		"UPDATE player SET gold=%d WHERE id=1;" % gold
	)
	
	# Limpar inventário antigo e reinserir
	DatabaseManager.query("DELETE FROM inventory;")
	for i in range(_slots.size()):
		if _slots[i].item_id != "":
			DatabaseManager.query(
				"INSERT INTO inventory (slot_index, item_id, quantity, quality) VALUES (%d, '%s', %d, %d);" % [
					i, _slots[i].item_id, _slots[i].quantity, _slots[i].quality
				]
			)


func load_data() -> void:
	# Carregar gold
	var player_data := DatabaseManager.query("SELECT gold FROM player WHERE id=1;")
	if player_data.size() > 0:
		gold = player_data[0].get("gold", 500)
	
	# Carregar inventário
	_slots.clear()
	_slots.resize(Constants.TOTAL_INVENTORY_SLOTS)
	for i in range(_slots.size()):
		_slots[i] = EMPTY_SLOT.duplicate()
	
	var inv_data := DatabaseManager.query("SELECT * FROM inventory ORDER BY slot_index;")
	for row in inv_data:
		var idx: int = row.get("slot_index", -1)
		if _is_valid_slot(idx):
			_slots[idx] = {
				"item_id": row.get("item_id", ""),
				"quantity": row.get("quantity", 0),
				"quality": row.get("quality", 0),
			}
	
	EventBus.inventory_changed.emit()


# =============================================================================
# HELPERS
# =============================================================================

func _is_valid_slot(index: int) -> bool:
	return index >= 0 and index < _slots.size()


func _set_slot(index: int, item_id: String, quantity: int, quality: int) -> void:
	if _is_valid_slot(index):
		_slots[index] = {"item_id": item_id, "quantity": quantity, "quality": quality}


func _get_max_stack(item_id: String) -> int:
	var item := ItemDatabase.get_item(item_id)
	if item:
		return item.max_stack if item.is_stackable else 1
	return Constants.DEFAULT_STACK_SIZE
