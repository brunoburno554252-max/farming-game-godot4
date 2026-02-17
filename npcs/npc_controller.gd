## npcs/npc_controller.gd
## NPCController — Controla um NPC no mundo.
## Segue schedule, anda entre pontos, interage com o jogador.
## Equivalente ao NPC class do Stardew Valley.
class_name NPCController
extends CharacterBody2D


# =============================================================================
# CONFIG
# =============================================================================

@export var npc_id: String = ""
const MOVE_SPEED: float = 40.0
const ARRIVE_THRESHOLD: float = 4.0


# =============================================================================
# STATE
# =============================================================================

var npc_data: NPCData
var facing_direction: Constants.Direction = Constants.Direction.DOWN
var is_talking: bool = false
var talked_today: bool = false
var gifts_this_week: int = 0

## Schedule state
var _current_schedule: Array[Dictionary] = []
var _current_schedule_index: int = 0
var _target_position: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _waiting_for_location_change: bool = false

## Visual
var _sprite: AnimatedSprite2D
var _collision: CollisionShape2D
var _name_label: Label


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Setup physics
	_collision = CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 5.0
	shape.height = 14.0
	_collision.shape = shape
	_collision.position.y = -3
	add_child(_collision)
	
	# Setup sprite placeholder
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Sprite"
	add_child(_sprite)
	
	# Name label above head
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 8)
	_name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.position = Vector2(-30, -24)
	_name_label.size.x = 60
	add_child(_name_label)
	
	# Add to group for easy finding
	add_to_group("npcs")
	add_to_group("interactable")
	
	# Load data
	if not npc_id.is_empty():
		initialize(npc_id)
	
	# Connect signals
	EventBus.day_started.connect(_on_day_started)
	EventBus.hour_changed.connect(_on_hour_changed)


func initialize(p_npc_id: String) -> void:
	npc_id = p_npc_id
	npc_data = NPCDatabase.get_npc(npc_id)
	if not npc_data:
		push_error("[NPCController] NPC '%s' não encontrado no NPCDatabase!" % npc_id)
		return
	
	name = "NPC_%s" % npc_id
	_name_label.text = npc_data.display_name
	
	# Set initial schedule
	_update_schedule()
	_advance_to_current_point()


# =============================================================================
# PHYSICS
# =============================================================================

func _physics_process(delta: float) -> void:
	if is_talking or not _is_moving:
		return
	
	var direction := _target_position - global_position
	var distance := direction.length()
	
	if distance <= ARRIVE_THRESHOLD:
		_arrive_at_target()
		return
	
	velocity = direction.normalized() * MOVE_SPEED
	_update_facing(velocity)
	move_and_slide()


# =============================================================================
# SCHEDULE
# =============================================================================

func _update_schedule() -> void:
	if not npc_data:
		return
	
	_current_schedule_index = 0
	_current_schedule.clear()
	
	var raw := npc_data.get_schedule_for_day(
		TimeSystem.current_day,
		TimeSystem.current_season,
		TimeSystem.get_day_of_week(),
		WeatherSystem.is_raining()
	)
	for entry in raw:
		_current_schedule.append(entry)


func _advance_to_current_point() -> void:
	if _current_schedule.is_empty():
		_is_moving = false
		return
	
	# Find the point we should be at based on current hour
	var current_hour := TimeSystem.current_hour
	var best_index := 0
	
	for i in _current_schedule.size():
		if _current_schedule[i].get("hour", 0) <= current_hour:
			best_index = i
	
	_current_schedule_index = best_index
	_go_to_schedule_point(best_index)


func _go_to_schedule_point(index: int) -> void:
	if index >= _current_schedule.size():
		_is_moving = false
		return
	
	var entry: Dictionary = _current_schedule[index]
	var target_location: String = entry.get("location", "")
	var target_tile := Vector2i(entry.get("tile", Vector2i.ZERO))
	
	# If NPC needs to change location
	if not target_location.is_empty() and target_location != LocationManager.current_location_id:
		# NPC is in a different location, teleport (simplified)
		_target_position = Vector2(target_tile) * Constants.TILE_SIZE_F
		global_position = _target_position
		_is_moving = false
		_set_facing_from_entry(entry)
		return
	
	# Same location: move to tile
	_target_position = Vector2(target_tile) * Constants.TILE_SIZE_F
	_is_moving = true


func _arrive_at_target() -> void:
	_is_moving = false
	global_position = _target_position
	
	if _current_schedule_index < _current_schedule.size():
		_set_facing_from_entry(_current_schedule[_current_schedule_index])
		
		EventBus.npc_arrived_at_schedule_point.emit(
			npc_id,
			LocationManager.current_location_id,
			Vector2i(_target_position / Constants.TILE_SIZE_F)
		)


func _set_facing_from_entry(entry: Dictionary) -> void:
	if entry.has("facing"):
		facing_direction = entry.facing as Constants.Direction


func _on_hour_changed(hour: int) -> void:
	if _current_schedule.is_empty():
		return
	
	# Check if there's a new schedule point for this hour
	for i in _current_schedule.size():
		if _current_schedule[i].get("hour", 0) == hour:
			_current_schedule_index = i
			_go_to_schedule_point(i)
			return


func _on_day_started(_day: int, _season: Constants.Season, _year: int) -> void:
	talked_today = false
	_update_schedule()
	_advance_to_current_point()
	
	# Reset gift counter on Monday
	if TimeSystem.get_day_of_week() == Constants.DayOfWeek.MONDAY:
		gifts_this_week = 0


# =============================================================================
# INTERACTION
# =============================================================================

## Called when the player interacts with this NPC.
func interact() -> void:
	if is_talking:
		return
	
	is_talking = true
	_face_player()
	
	var hearts := FriendshipSystem.get_hearts(npc_id)
	var dialogue_text := npc_data.get_dialogue(
		hearts,
		TimeSystem.current_season,
		TimeSystem.get_day_of_week(),
		WeatherSystem.is_raining(),
		TimeSystem.current_day
	)
	
	DialogueManager.start_dialogue(npc_data.display_name, [dialogue_text])
	EventBus.npc_talked.emit(npc_id)
	
	# Give friendship for first daily talk
	if not talked_today:
		talked_today = true
		FriendshipSystem.add_friendship(npc_id, 20)
	
	# Wait for dialogue to end
	EventBus.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)


## Called when the player gives a gift to this NPC.
func receive_gift(item_id: String) -> Constants.GiftTaste:
	if gifts_this_week >= Constants.GIFTS_PER_WEEK_LIMIT:
		DialogueManager.say(npc_data.display_name, "Obrigado, mas já recebi muitos presentes esta semana.")
		return Constants.GiftTaste.NEUTRAL
	
	var taste := npc_data.get_gift_taste(item_id)
	gifts_this_week += 1
	
	# Apply friendship points
	var points: int = Constants.GIFT_TASTE_POINTS.get(taste, 0)
	
	# Birthday bonus
	if int(npc_data.birthday_season) == int(TimeSystem.current_season) and npc_data.birthday_day == TimeSystem.current_day:
		points *= 8
	
	FriendshipSystem.add_friendship(npc_id, points)
	
	# Dialogue reaction
	var reaction := ""
	match taste:
		Constants.GiftTaste.LOVE:
			reaction = "Adorei! É exatamente o que eu queria! Muito obrigado!"
		Constants.GiftTaste.LIKE:
			reaction = "Que legal! Gostei bastante, obrigado!"
		Constants.GiftTaste.NEUTRAL:
			reaction = "Ah, obrigado pelo presente."
		Constants.GiftTaste.DISLIKE:
			reaction = "Hmm... não é bem o meu estilo, mas obrigado."
		Constants.GiftTaste.HATE:
			reaction = "Isso... não é algo que eu goste. Mas agradeço a intenção."
	
	DialogueManager.say(npc_data.display_name, reaction)
	EventBus.npc_gift_given.emit(npc_id, item_id, taste)
	
	return taste


func _on_dialogue_ended() -> void:
	is_talking = false


func _face_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	var diff: Vector2 = player.global_position - global_position
	if abs(diff.x) > abs(diff.y):
		facing_direction = Constants.Direction.RIGHT if diff.x > 0 else Constants.Direction.LEFT
	else:
		facing_direction = Constants.Direction.DOWN if diff.y > 0 else Constants.Direction.UP


# =============================================================================
# FACING
# =============================================================================

func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() < 1.0:
		return
	if abs(vel.x) > abs(vel.y):
		facing_direction = Constants.Direction.RIGHT if vel.x > 0 else Constants.Direction.LEFT
	else:
		facing_direction = Constants.Direction.DOWN if vel.y > 0 else Constants.Direction.UP


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> Dictionary:
	return {
		"npc_id": npc_id,
		"position_x": global_position.x,
		"position_y": global_position.y,
		"facing": int(facing_direction),
		"talked_today": talked_today,
		"gifts_this_week": gifts_this_week,
	}

func load_data(data: Dictionary) -> void:
	global_position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	facing_direction = data.get("facing", 2) as Constants.Direction
	talked_today = data.get("talked_today", false)
	gifts_this_week = data.get("gifts_this_week", 0)
