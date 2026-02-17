## data/items/item_data.gd
## ItemData — Resource que define os dados de um item.
## Base para todos os itens do jogo: sementes, ferramentas, colheitas, recursos, etc.
## Equivalente ao ObjectInformation do Stardew Valley.
class_name ItemData
extends Resource


# =============================================================================
# IDENTIFICATION
# =============================================================================

## ID único do item (ex: "parsnip_seeds", "parsnip", "wood", "copper_hoe")
@export var id: String = ""

## Nome exibido ao jogador
@export var display_name: String = ""

## Descrição exibida no tooltip
@export var description: String = ""


# =============================================================================
# CLASSIFICATION
# =============================================================================

## Tipo principal do item
@export var item_type: Constants.ItemType = Constants.ItemType.RESOURCE

## Subcategoria (para agrupamento em menus, coleta, etc.)
@export var category: String = ""


# =============================================================================
# VISUAL
# =============================================================================

## Ícone do item (16x16 ou 32x32)
@export var icon: Texture2D = null

## Sprite do item quando colocado no mundo (para craftables)
@export var world_sprite: Texture2D = null


# =============================================================================
# ECONOMICS
# =============================================================================

## Preço de venda base
@export var sell_price: int = 0

## Preço de compra em lojas (0 = não vendido em lojas)
@export var buy_price: int = 0

## Se pode ser vendido
@export var is_sellable: bool = true


# =============================================================================
# STACKING
# =============================================================================

## Tamanho máximo do stack
@export var max_stack: int = 999

## Se pode ser stackado (ferramentas geralmente não)
@export var is_stackable: bool = true


# =============================================================================
# TOOL DATA (se item_type == TOOL)
# =============================================================================

## Tipo de ferramenta
@export var tool_type: Constants.ToolType = Constants.ToolType.NONE

## Nível da ferramenta
@export var tool_level: Constants.ToolLevel = Constants.ToolLevel.BASIC


# =============================================================================
# SEED DATA (se item_type == SEED)
# =============================================================================

## ID do CropData que esta semente planta
@export var plants_crop_id: String = ""


# =============================================================================
# FOOD DATA (se item_type == FOOD)
# =============================================================================

## Energia restaurada ao consumir
@export var energy_restored: float = 0.0

## HP restaurado ao consumir (para combate)
@export var health_restored: float = 0.0


# =============================================================================
# CRAFTABLE DATA (se item_type == CRAFTABLE)
# =============================================================================

## Se pode ser colocado no mundo
@export var is_placeable: bool = false

## Cena do objeto colocado no mundo
@export var placed_scene: PackedScene = null


# =============================================================================
# GIFT DATA (para sistema de presentes NPC)
# =============================================================================

## Gift tastes por NPC: { "npc_id": GiftTaste }
## NPCs não listados aqui usam taste NEUTRAL.
@export var gift_tastes: Dictionary = {}


# =============================================================================
# COMPUTED
# =============================================================================

## Retorna o preço de venda ajustado pela qualidade.
func get_sell_price(quality: Constants.ItemQuality = Constants.ItemQuality.NORMAL) -> int:
	var mult: float = Constants.QUALITY_PRICE_MULTIPLIER.get(quality, 1.0)
	return int(sell_price * mult)


## Retorna se é uma ferramenta.
func is_tool() -> bool:
	return item_type == Constants.ItemType.TOOL


## Retorna se é uma semente.
func is_seed() -> bool:
	return item_type == Constants.ItemType.SEED


## Retorna se é comida.
func is_food() -> bool:
	return item_type == Constants.ItemType.FOOD


## Retorna o gift taste para um NPC específico.
func get_gift_taste(npc_id: String) -> Constants.GiftTaste:
	return gift_tastes.get(npc_id, Constants.GiftTaste.NEUTRAL)
