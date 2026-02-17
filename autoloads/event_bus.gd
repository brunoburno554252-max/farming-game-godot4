## autoloads/event_bus.gd
## EventBus — Barramento de sinais centralizado.
## PRIMEIRO autoload a ser carregado. Todos os sistemas se comunicam através daqui.
## Isso evita que sistemas dependam uns dos outros diretamente (desacoplamento).
extends Node


# =============================================================================
# GAME STATE
# =============================================================================

## Emitido quando o estado do jogo muda (ex: PLAYING → PAUSED)
signal game_state_changed(old_state: Constants.GameState, new_state: Constants.GameState)

## Emitido quando o jogo está pronto para jogar (todos os sistemas inicializados)
signal game_ready()

## Emitido quando um novo jogo é iniciado
signal new_game_started()

## Emitido quando um save é carregado
signal game_loaded(save_slot: int)

## Emitido quando o jogo é salvo
signal game_saved(save_slot: int)


# =============================================================================
# TIME
# =============================================================================

## Emitido a cada tick de tempo (a cada 10 minutos no jogo)
signal time_tick(hour: int, minute: int)

## Emitido quando a hora muda
signal hour_changed(hour: int)

## Emitido no início de um novo dia
signal day_started(day: int, season: Constants.Season, year: int)

## Emitido no fim do dia (jogador dormiu ou desmaiou)
signal day_ended()

## Emitido durante a transição de dia (para processar crescimento, etc.)
signal day_transition_process()

## Emitido quando a estação muda
signal season_changed(new_season: Constants.Season)

## Emitido quando o ano muda
signal year_changed(new_year: int)


# =============================================================================
# WEATHER
# =============================================================================

## Emitido quando o clima muda
signal weather_changed(new_weather: Constants.Weather)


# =============================================================================
# PLAYER
# =============================================================================

## Emitido quando o jogador muda de posição no grid
signal player_tile_changed(tile_pos: Vector2i)

## Emitido quando o jogador usa uma ferramenta
signal player_used_tool(tool_type: Constants.ToolType, tile_pos: Vector2i)

## Emitido quando a energia do jogador muda
signal player_energy_changed(current: float, maximum: float)

## Emitido quando o jogador interage com algo
signal player_interact(target: Node, tile_pos: Vector2i)

## Emitido quando o jogador muda a direção que está olhando
signal player_direction_changed(direction: Constants.Direction)

## Emitido quando o jogador desmaia (energia zerou ou passou das 2AM)
signal player_passed_out(reason: String)

## Emitido quando o jogador vai dormir voluntariamente
signal player_slept()


# =============================================================================
# INVENTORY
# =============================================================================

## Emitido quando qualquer slot do inventário muda
signal inventory_changed()

## Emitido quando o item selecionado na hotbar muda
signal hotbar_selection_changed(slot_index: int, item_id: String)

## Emitido quando o dinheiro do jogador muda
signal gold_changed(new_amount: int, delta: int)

## Emitido quando um item é adicionado ao inventário
signal item_added(item_id: String, quantity: int)

## Emitido quando um item é removido do inventário
signal item_removed(item_id: String, quantity: int)


# =============================================================================
# FARMING
# =============================================================================

## Emitido quando o solo é arado
signal soil_tilled(location_id: String, tile_pos: Vector2i)

## Emitido quando o solo é regado
signal soil_watered(location_id: String, tile_pos: Vector2i)

## Emitido quando uma semente é plantada
signal crop_planted(location_id: String, tile_pos: Vector2i, crop_id: String)

## Emitido quando uma planta cresce um estágio
signal crop_grew(location_id: String, tile_pos: Vector2i, new_stage: int)

## Emitido quando uma planta está pronta para colheita
signal crop_ready_to_harvest(location_id: String, tile_pos: Vector2i, crop_id: String)

## Emitido quando uma planta é colhida
signal crop_harvested(location_id: String, tile_pos: Vector2i, crop_id: String, item_id: String, quantity: int)

## Emitido quando uma planta murcha (estação errada, sem água por muito tempo)
signal crop_withered(location_id: String, tile_pos: Vector2i)


# =============================================================================
# OBJECTS (Placed in world)
# =============================================================================

## Emitido quando um objeto é colocado no mundo
signal object_placed(location_id: String, tile_pos: Vector2i, object_id: String)

## Emitido quando um objeto é removido do mundo
signal object_removed(location_id: String, tile_pos: Vector2i, object_id: String)

## Emitido quando um objeto produz algo (ex: keg terminou, furnace pronta)
signal object_produced(location_id: String, tile_pos: Vector2i, product_id: String)


# =============================================================================
# LOCATION / SCENE
# =============================================================================

## Emitido quando uma transição de cena começa
signal scene_transition_started(from_location: String, to_location: String)

## Emitido quando uma transição de cena termina
signal scene_transition_completed(location_id: String)

## Emitido quando a location atual é totalmente carregada e pronta
signal location_ready(location_id: String)


# =============================================================================
# NPC
# =============================================================================

## Emitido quando o jogador fala com um NPC
signal npc_talked(npc_id: String)

## Emitido quando o jogador dá um presente a um NPC
signal npc_gift_given(npc_id: String, item_id: String, taste: Constants.GiftTaste)

## Emitido quando o nível de amizade muda
signal friendship_changed(npc_id: String, new_points: int, new_hearts: int)

## Emitido quando um NPC chega a um ponto do schedule
signal npc_arrived_at_schedule_point(npc_id: String, location_id: String, tile_pos: Vector2i)


# =============================================================================
# UI
# =============================================================================

## Emitido quando um menu é aberto
signal menu_opened(menu_name: String)

## Emitido quando um menu é fechado
signal menu_closed(menu_name: String)

## Emitido quando todos os menus são fechados
signal all_menus_closed()

## Emitido quando uma notificação/toast deve aparecer
signal show_notification(text: String, icon: Texture2D)

## Emitido quando o HUD deve mostrar um item obtido
signal show_item_obtained(item_id: String, quantity: int)


# =============================================================================
# DIALOGUE
# =============================================================================

## Emitido quando um diálogo começa
signal dialogue_started(speaker_name: String)

## Emitido quando um diálogo termina
signal dialogue_ended()

## Emitido quando o jogador escolhe uma opção no diálogo
signal dialogue_choice_selected(choice_index: int, choice_text: String)


# =============================================================================
# SKILLS & PROGRESSION
# =============================================================================

## Emitido quando XP é ganho em uma skill
signal skill_xp_gained(skill_type: Constants.SkillType, amount: int)

## Emitido quando uma skill sobe de nível
signal skill_level_up(skill_type: Constants.SkillType, new_level: int)

## Emitido quando uma receita é desbloqueada
signal recipe_unlocked(recipe_id: String)


# =============================================================================
# AUDIO
# =============================================================================

## Emitido para tocar um SFX
signal play_sfx(sfx_name: String)

## Emitido para trocar a música
signal change_music(music_name: String, fade_duration: float)

## Emitido para parar a música
signal stop_music(fade_duration: float)
