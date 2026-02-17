## data/crops/crop_data.gd
## CropData — Resource que define os dados de um tipo de planta.
## Equivalente à entrada no Data/Crops.xnb do Stardew Valley.
## Cada crop tem fases de crescimento, estações válidas, item de colheita, etc.
##
## COMO USAR:
## 1. Crie um .tres no editor: New Resource → CropData
## 2. Preencha os campos (id, nome, fases, estações, etc.)
## 3. O CropSystem usa esses dados para gerenciar o crescimento.
class_name CropData
extends Resource


# =============================================================================
# IDENTIFICATION
# =============================================================================

## ID único do crop (ex: "parsnip", "cauliflower", "melon")
@export var id: String = ""

## Nome exibido ao jogador
@export var display_name: String = ""

## Descrição
@export var description: String = ""

## ID da semente que planta este crop
@export var seed_item_id: String = ""

## ID do item produzido na colheita
@export var harvest_item_id: String = ""


# =============================================================================
# GROWTH
# =============================================================================

## Dias necessários em cada fase de crescimento.
## Ex: [1, 2, 2, 2, 1] = 5 fases, total 8 dias para crescer.
## A última fase é a fase "pronta para colheita".
@export var phase_days: Array[int] = []

## Estações em que esta planta pode crescer.
## Planta morre se a estação mudar para uma que não está na lista.
@export var valid_seasons: Array[Constants.Season] = []

## Se a planta renasce após colheita (como tomate, morango).
@export var regrows_after_harvest: bool = false

## Dias para renascer após colheita (se regrows_after_harvest = true).
@export var days_to_regrow: int = 0

## Fase para qual a planta volta após colheita (se renasce).
## Ex: tomate volta para fase 3 (fase anterior à madura).
@export var regrow_phase: int = 0


# =============================================================================
# HARVEST
# =============================================================================

## Quantidade mínima colhida
@export var min_harvest: int = 1

## Quantidade máxima colhida
@export var max_harvest: int = 1

## Chance de colheita extra (0.0 a 1.0)
@export var extra_harvest_chance: float = 0.0

## XP de farming ganho ao colher
@export var harvest_xp: int = 0


# =============================================================================
# VISUAL
# =============================================================================

## Spritesheet com todas as fases de crescimento
@export var growth_spritesheet: Texture2D = null

## Largura de cada frame no spritesheet (em pixels)
@export var frame_width: int = 16

## Altura de cada frame no spritesheet (em pixels)
@export var frame_height: int = 32

## Se a planta balança com o vento
@export var sways_in_wind: bool = true

## Se a planta usa o sprite "giant crop" quando 3x3 do mesmo tipo
@export var can_be_giant: bool = false


# =============================================================================
# PRICING
# =============================================================================

## Preço de venda base do item colhido
@export var base_sell_price: int = 0

## Preço de compra da semente
@export var seed_buy_price: int = 0


# =============================================================================
# COMPUTED
# =============================================================================

## Retorna o total de dias para crescer do zero até colheita.
func get_total_grow_days() -> int:
	var total := 0
	for days in phase_days:
		total += days
	return total


## Retorna o número total de fases (incluindo a fase "pronta").
func get_total_phases() -> int:
	return phase_days.size()


## Retorna se a planta pode crescer numa estação específica.
func can_grow_in_season(season: Constants.Season) -> bool:
	return season in valid_seasons


## Calcula a quantidade de colheita (com RNG).
func calculate_harvest_amount(quality_bonus: float = 0.0) -> int:
	var amount := min_harvest
	if max_harvest > min_harvest:
		amount = randi_range(min_harvest, max_harvest)
	
	# Chance de colheita extra baseada no farming level e fertilizante
	if extra_harvest_chance > 0.0:
		var chance := extra_harvest_chance + quality_bonus * 0.1
		if randf() < chance:
			amount += 1
	
	return amount


## Calcula a qualidade do item colhido baseado no fertilizante e skill.
func calculate_harvest_quality(
	fertilizer_bonus: float,
	farming_level: int
) -> Constants.ItemQuality:
	# Lógica baseada no Stardew Valley:
	# Base chance para gold quality = farming_level * 0.01
	# + fertilizer_bonus
	var gold_chance := farming_level * 0.01 + fertilizer_bonus
	var silver_chance := gold_chance * 2.0
	
	var roll := randf()
	if roll < gold_chance * 0.5:
		return Constants.ItemQuality.IRIDIUM
	elif roll < gold_chance:
		return Constants.ItemQuality.GOLD
	elif roll < silver_chance:
		return Constants.ItemQuality.SILVER
	
	return Constants.ItemQuality.NORMAL
