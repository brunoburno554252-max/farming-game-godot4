## autoloads/inventory_system.gd
## InventorySystem — Gerencia itens, hotbar e dinheiro do jogador.
## SERÁ EXPANDIDO NA ETAPA 5.
extends Node

var gold: int = 500
var hotbar_selected: int = 0
var _slots: Array = []  # Array de {item_id: String, quantity: int}


func initialize_new_game() -> void:
	gold = 500
	hotbar_selected = 0
	_slots.clear()
	_slots.resize(Constants.TOTAL_INVENTORY_SLOTS)
	for i in range(_slots.size()):
		_slots[i] = {"item_id": "", "quantity": 0}


func add_item(item_id: String, quantity: int = 1) -> bool:
	# Primeiro tenta stackar em slot existente
	for i in range(_slots.size()):
		if _slots[i].item_id == item_id:
			_slots[i].quantity += quantity
			EventBus.inventory_changed.emit()
			EventBus.item_added.emit(item_id, quantity)
			return true
	# Depois procura slot vazio
	for i in range(_slots.size()):
		if _slots[i].item_id == "":
			_slots[i].item_id = item_id
			_slots[i].quantity = quantity
			EventBus.inventory_changed.emit()
			EventBus.item_added.emit(item_id, quantity)
			return true
	return false  # Inventário cheio


func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(_slots.size()):
		if _slots[i].item_id == item_id and _slots[i].quantity >= quantity:
			_slots[i].quantity -= quantity
			if _slots[i].quantity <= 0:
				_slots[i].item_id = ""
				_slots[i].quantity = 0
			EventBus.inventory_changed.emit()
			EventBus.item_removed.emit(item_id, quantity)
			return true
	return false


func has_item(item_id: String, quantity: int = 1) -> bool:
	var total := 0
	for slot in _slots:
		if slot.item_id == item_id:
			total += slot.quantity
	return total >= quantity


func get_slot(index: int) -> Dictionary:
	if index >= 0 and index < _slots.size():
		return _slots[index]
	return {"item_id": "", "quantity": 0}


func get_selected_item_id() -> String:
	return get_slot(hotbar_selected).item_id


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		EventBus.gold_changed.emit(gold, -amount)
		return true
	return false


func earn_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold, amount)


func save_data() -> void:
	pass  # Etapa 3


func load_data() -> void:
	pass  # Etapa 3
