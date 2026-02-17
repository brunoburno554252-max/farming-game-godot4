## autoloads/database_manager.gd
## DatabaseManager — Camada de persistência SQLite.
## Gerencia conexão, criação de tabelas, e operações CRUD.
## SERÁ TOTALMENTE IMPLEMENTADO NA ETAPA 3.
extends Node

## Referência ao banco de dados SQLite (via addon ou GDExtension)
## Nota: Requer o addon godot-sqlite (https://github.com/2shady4u/godot-sqlite)
var _db: SQLite = null
var _db_path: String = ""
var _is_open: bool = false


func _ready() -> void:
	# O SQLite será inicializado quando um save for criado ou carregado
	pass


## Cria um novo save com tabelas vazias.
func create_new_save(slot: int) -> void:
	_db_path = Constants.SAVE_DB_NAME % slot
	_open_database()
	_create_tables()
	_insert_default_data()
	print("[DatabaseManager] Novo save criado: %s" % _db_path)


## Carrega um save existente.
func load_save(slot: int) -> bool:
	_db_path = Constants.SAVE_DB_NAME % slot
	if not FileAccess.file_exists(_db_path):
		push_error("[DatabaseManager] Save não encontrado: %s" % _db_path)
		return false
	_open_database()
	print("[DatabaseManager] Save carregado: %s" % _db_path)
	return true


## Abre a conexão com o banco.
func _open_database() -> void:
	if _is_open:
		close_database()
	
	_db = SQLite.new()
	_db.path = _db_path
	_db.open_db()
	_is_open = true
	
	# Otimizações SQLite para mobile
	_db.query("PRAGMA journal_mode=WAL;")
	_db.query("PRAGMA synchronous=NORMAL;")
	_db.query("PRAGMA cache_size=-2000;")  # 2MB cache


## Fecha a conexão com o banco.
func close_database() -> void:
	if _db and _is_open:
		_db.close_db()
		_is_open = false
		_db = null


## Cria todas as tabelas do jogo.
func _create_tables() -> void:
	if not _db:
		return
	
	# ---- CORE ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS game_state (
			id INTEGER PRIMARY KEY DEFAULT 1,
			player_name TEXT NOT NULL DEFAULT '',
			farm_name TEXT NOT NULL DEFAULT '',
			current_day INTEGER NOT NULL DEFAULT 1,
			current_season INTEGER NOT NULL DEFAULT 0,
			current_year INTEGER NOT NULL DEFAULT 1,
			current_hour INTEGER NOT NULL DEFAULT 6,
			current_minute INTEGER NOT NULL DEFAULT 0,
			weather_today INTEGER NOT NULL DEFAULT 0,
			weather_tomorrow INTEGER NOT NULL DEFAULT 0,
			total_days_played INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	# ---- PLAYER ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS player (
			id INTEGER PRIMARY KEY DEFAULT 1,
			gold INTEGER NOT NULL DEFAULT 500,
			energy REAL NOT NULL DEFAULT 270.0,
			max_energy REAL NOT NULL DEFAULT 270.0,
			current_location TEXT NOT NULL DEFAULT 'farm',
			pos_x REAL NOT NULL DEFAULT 0.0,
			pos_y REAL NOT NULL DEFAULT 0.0,
			facing_direction INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	# ---- INVENTORY ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS inventory (
			slot_index INTEGER PRIMARY KEY,
			item_id TEXT NOT NULL DEFAULT '',
			quantity INTEGER NOT NULL DEFAULT 0,
			quality INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	# ---- EQUIPMENT / TOOLS ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS equipment (
			slot_type TEXT PRIMARY KEY,
			item_id TEXT NOT NULL DEFAULT '',
			upgrade_level INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	# ---- TERRAIN FEATURES (HoeDirt, Trees, etc.) ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS terrain_features (
			location_id TEXT NOT NULL,
			tile_x INTEGER NOT NULL,
			tile_y INTEGER NOT NULL,
			feature_type TEXT NOT NULL,
			state_data TEXT NOT NULL DEFAULT '{}',
			PRIMARY KEY (location_id, tile_x, tile_y)
		);
	""")
	
	# ---- CROPS ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS crops (
			location_id TEXT NOT NULL,
			tile_x INTEGER NOT NULL,
			tile_y INTEGER NOT NULL,
			crop_id TEXT NOT NULL,
			current_phase INTEGER NOT NULL DEFAULT 0,
			day_of_current_phase INTEGER NOT NULL DEFAULT 0,
			fully_grown INTEGER NOT NULL DEFAULT 0,
			days_without_water INTEGER NOT NULL DEFAULT 0,
			fertilizer_id INTEGER NOT NULL DEFAULT 0,
			PRIMARY KEY (location_id, tile_x, tile_y)
		);
	""")
	
	# ---- PLACED OBJECTS (sprinklers, chests, machines) ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS placed_objects (
			location_id TEXT NOT NULL,
			tile_x INTEGER NOT NULL,
			tile_y INTEGER NOT NULL,
			object_id TEXT NOT NULL,
			state_data TEXT NOT NULL DEFAULT '{}',
			PRIMARY KEY (location_id, tile_x, tile_y)
		);
	""")
	
	# ---- NPC FRIENDSHIP ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS npc_friendship (
			npc_id TEXT PRIMARY KEY,
			friendship_points INTEGER NOT NULL DEFAULT 0,
			gifts_this_week INTEGER NOT NULL DEFAULT 0,
			talked_today INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	# ---- SKILLS ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS skills (
			skill_type INTEGER PRIMARY KEY,
			level INTEGER NOT NULL DEFAULT 0,
			experience INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	# ---- UNLOCKED RECIPES ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS unlocked_recipes (
			recipe_id TEXT PRIMARY KEY,
			date_unlocked INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	# ---- COMPLETED EVENTS ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS completed_events (
			event_id TEXT PRIMARY KEY
		);
	""")
	
	# ---- SHIPPING LOG ----
	_db.query("""
		CREATE TABLE IF NOT EXISTS shipping_log (
			item_id TEXT PRIMARY KEY,
			quantity_shipped INTEGER NOT NULL DEFAULT 0
		);
	""")


## Insere dados padrão para um novo jogo.
func _insert_default_data() -> void:
	if not _db:
		return
	
	_db.query("INSERT OR REPLACE INTO game_state (id) VALUES (1);")
	_db.query("INSERT OR REPLACE INTO player (id) VALUES (1);")
	
	# Inicializar slots de inventário
	for i in range(Constants.TOTAL_INVENTORY_SLOTS):
		_db.query("INSERT INTO inventory (slot_index, item_id, quantity) VALUES (%d, '', 0);" % i)
	
	# Inicializar skills
	for skill in Constants.SkillType.values():
		_db.query("INSERT INTO skills (skill_type, level, experience) VALUES (%d, 0, 0);" % skill)


## Retorna os dados do game_state como Dictionary.
func get_game_state() -> Dictionary:
	if not _db:
		return {}
	_db.query("SELECT * FROM game_state WHERE id = 1;")
	if _db.query_result.size() > 0:
		return _db.query_result[0]
	return {}


## Executa uma query genérica. Retorna o resultado.
func query(sql: String) -> Array:
	if not _db:
		return []
	_db.query(sql)
	return _db.query_result


## Commit das mudanças (WAL flush).
func commit_save() -> void:
	if _db:
		_db.query("PRAGMA wal_checkpoint(TRUNCATE);")


## Verifica se um save slot existe.
static func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(Constants.SAVE_DB_NAME % slot)


## Deleta um save slot.
static func delete_save(slot: int) -> void:
	var path := Constants.SAVE_DB_NAME % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		# Também remove o WAL e SHM se existirem
		if FileAccess.file_exists(path + "-wal"):
			DirAccess.remove_absolute(path + "-wal")
		if FileAccess.file_exists(path + "-shm"):
			DirAccess.remove_absolute(path + "-shm")
