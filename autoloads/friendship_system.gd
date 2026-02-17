## autoloads/friendship_system.gd
## FriendshipSystem — Gerencia amizade com NPCs.
## Rastreia pontos, corações, presentes dados, e persiste no SQLite.
## Equivalente ao Farmer.friendshipData do Stardew Valley.
extends Node


# =============================================================================
# STATE
# =============================================================================

## {npc_id: {points: int, gifts_this_week: int, talked_today: bool, status: String}}
var _friendships: Dictionary = {}


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)


func initialize_new_game() -> void:
	_friendships.clear()
	# Inicializar todos os NPCs com 0 pontos
	for npc_id in NPCDatabase.get_all_npc_ids():
		_friendships[npc_id] = {
			"points": 0,
			"gifts_this_week": 0,
			"talked_today": false,
			"status": "stranger",  # stranger, friend, dating, married
		}


# =============================================================================
# FRIENDSHIP MANAGEMENT
# =============================================================================

func add_friendship(npc_id: String, amount: int) -> void:
	_ensure_entry(npc_id)
	var old_points: int = _friendships[npc_id].points
	var old_hearts := get_hearts(npc_id)
	
	_friendships[npc_id].points = clampi(
		old_points + amount,
		0,
		Constants.MAX_FRIENDSHIP_POINTS
	)
	
	var new_hearts := get_hearts(npc_id)
	EventBus.friendship_changed.emit(npc_id, _friendships[npc_id].points, new_hearts)
	
	if new_hearts > old_hearts:
		EventBus.show_notification.emit(
			"%s: %d ❤" % [_get_display_name(npc_id), new_hearts], null
		)


func get_points(npc_id: String) -> int:
	_ensure_entry(npc_id)
	return _friendships[npc_id].points


func get_hearts(npc_id: String) -> int:
	var points := get_points(npc_id)
	return mini(points / Constants.POINTS_PER_HEART, Constants.MAX_HEARTS)


func get_status(npc_id: String) -> String:
	_ensure_entry(npc_id)
	return _friendships[npc_id].status


func set_status(npc_id: String, status: String) -> void:
	_ensure_entry(npc_id)
	_friendships[npc_id].status = status


## Retorna todos os NPCs com ao menos 1 coração, ordenados por pontos.
func get_friends() -> Array[Dictionary]:
	var friends: Array[Dictionary] = []
	for npc_id in _friendships:
		var points: int = _friendships[npc_id].points
		if points >= Constants.POINTS_PER_HEART:
			friends.append({
				"npc_id": npc_id,
				"points": points,
				"hearts": get_hearts(npc_id),
				"status": _friendships[npc_id].status,
			})
	friends.sort_custom(func(a, b): return a.points > b.points)
	return friends


# =============================================================================
# DAILY RESET
# =============================================================================

func _on_day_started(_day: int, _season: Constants.Season, _year: int) -> void:
	for npc_id in _friendships:
		_friendships[npc_id].talked_today = false
	
	# Reset gifts on Monday
	if TimeSystem.get_day_of_week() == Constants.DayOfWeek.MONDAY:
		for npc_id in _friendships:
			_friendships[npc_id].gifts_this_week = 0


# =============================================================================
# HELPERS
# =============================================================================

func _ensure_entry(npc_id: String) -> void:
	if not _friendships.has(npc_id):
		_friendships[npc_id] = {
			"points": 0,
			"gifts_this_week": 0,
			"talked_today": false,
			"status": "stranger",
		}


func _get_display_name(npc_id: String) -> String:
	var npc := NPCDatabase.get_npc(npc_id)
	return npc.display_name if npc else npc_id


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_data() -> void:
	for npc_id in _friendships:
		var data: Dictionary = _friendships[npc_id]
		DatabaseManager.query(
			"INSERT OR REPLACE INTO npc_friendship (npc_id, friendship_points, gifts_this_week, status) VALUES ('%s', %d, %d, '%s');" % [
				npc_id, data.points, data.gifts_this_week, data.status
			]
		)


func load_data() -> void:
	_friendships.clear()
	var rows := DatabaseManager.query("SELECT * FROM npc_friendship;")
	for row in rows:
		_friendships[row.npc_id] = {
			"points": row.get("friendship_points", 0),
			"gifts_this_week": row.get("gifts_this_week", 0),
			"talked_today": false,
			"status": row.get("status", "stranger"),
		}
	
	# Ensure all NPCs from database have entries
	for npc_id in NPCDatabase.get_all_npc_ids():
		_ensure_entry(npc_id)
