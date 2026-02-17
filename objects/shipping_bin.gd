## objects/shipping_bin.gd
## ShippingBin — Caixa de envio na fazenda. Itens colocados são vendidos no fim do dia.
## Equivalente ao ShippingBin do Stardew Valley.
class_name ShippingBin
extends Node2D


# =============================================================================
# STATE
# =============================================================================

## Array de {item_id: String, quantity: int, quality: int, price: int}
var _items: Array[Dictionary] = []
var _interaction_area: Area2D


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	name = "ShippingBin"
	add_to_group("interactable")
	add_to_group("shipping_bin")
	
	# Interaction area
	_interaction_area = Area2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	_interaction_area.add_child(col)
	_interaction_area.collision_layer = 0
	_interaction_area.collision_mask = 1  # Player layer
	add_child(_interaction_area)
	
	# Connect day end to process shipped items
	EventBus.day_transition_process.connect(_on_day_transition)


# =============================================================================
# SHIPPING
# =============================================================================

## Adiciona o item selecionado da hotbar à caixa de envio.
func ship_selected_item() -> bool:
	var slot := InventorySystem.get_selected_slot()
	if slot.item_id.is_empty():
		return false
	
	var item := ItemDatabase.get_item(slot.item_id)
	if not item or not item.is_sellable or item.sell_price <= 0:
		EventBus.show_notification.emit("Este item não pode ser vendido.", null)
		return false
	
	# Calcular preço com qualidade
	var quality_mult := 1.0
	match slot.get("quality", 0):
		1: quality_mult = 1.25  # Silver
		2: quality_mult = 1.5   # Gold
		3: quality_mult = 2.0   # Iridium
	
	var price := int(item.sell_price * quality_mult)
	
	_items.append({
		"item_id": slot.item_id,
		"quantity": 1,
		"quality": slot.get("quality", 0),
		"price": price,
	})
	
	InventorySystem.consume_selected()
	
	EventBus.show_notification.emit("%s enviado! (+%dG)" % [item.display_name, price], null)
	EventBus.play_sfx.emit("ship_item")
	
	return true


## Retorna os itens enviados hoje para o resumo.
func get_shipped_items() -> Array[Dictionary]:
	return _items.duplicate()


## Processa o envio no fim do dia.
func _on_day_transition() -> void:
	if _items.is_empty():
		return
	
	var total := 0
	for item in _items:
		total += item.price * item.quantity
		# Log para o shipping_log
		DatabaseManager.query(
			"INSERT INTO shipping_log (item_id, quantity, quality, total_price, day, season, year) VALUES ('%s', %d, %d, %d, %d, %d, %d);" % [
				item.item_id, item.quantity, item.quality, item.price,
				TimeSystem.current_day, int(TimeSystem.current_season), TimeSystem.current_year
			]
		)
	
	# Dar o dinheiro ao jogador
	InventorySystem.earn_gold(total)
	
	_items.clear()


## Retorna o total pendente de envio.
func get_pending_total() -> int:
	var total := 0
	for item in _items:
		total += item.price * item.quantity
	return total
