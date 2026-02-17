## classes/constants.gd
## Todas as constantes e enums globais do jogo.
## Importado como classe estática — use: Constants.Season.SPRING, Constants.GameState.PLAYING, etc.
class_name Constants


# =============================================================================
# GAME STATES
# =============================================================================

enum GameState {
	INITIALIZING,   ## Carregando sistemas
	MAIN_MENU,      ## Menu principal
	LOADING,        ## Carregando save
	PLAYING,        ## Jogando normalmente
	PAUSED,         ## Jogo pausado (menu aberto)
	DIALOGUE,       ## Em diálogo com NPC
	CUTSCENE,       ## Evento/cutscene
	SHOPPING,       ## Na loja
	CRAFTING,       ## Menu de crafting
	INVENTORY,      ## Inventário aberto
	FISHING,        ## Minigame de pesca
	DAY_TRANSITION, ## Transição de dia (dormindo/desmaiou)
	SAVING,         ## Salvando jogo
}


# =============================================================================
# TIME
# =============================================================================

enum Season {
	SPRING,
	SUMMER,
	FALL,
	WINTER,
}

const SEASON_NAMES: Array[String] = ["Primavera", "Verão", "Outono", "Inverno"]
const DAYS_PER_SEASON: int = 28
const SEASONS_PER_YEAR: int = 4
const DAYS_PER_YEAR: int = DAYS_PER_SEASON * SEASONS_PER_YEAR  ## 112

## Tempo do jogo: 6:00 AM até 2:00 AM (20 horas de jogo)
const DAY_START_HOUR: int = 6       ## 6:00 AM
const DAY_END_HOUR: int = 26        ## 2:00 AM (formato 26h como Stardew)
const MINUTES_PER_GAME_HOUR: int = 60
const GAME_MINUTES_PER_TICK: int = 10  ## A cada tick, 10 minutos passam
const REAL_SECONDS_PER_TICK: float = 7.0  ## ~7 segundos reais = 10 min no jogo

## Hora em que o jogador começa a ficar cansado
const EXHAUSTION_HOUR: int = 24     ## Midnight
## Hora em que o jogador desmaia
const PASSOUT_HOUR: int = 26        ## 2:00 AM

enum DayOfWeek {
	MONDAY,
	TUESDAY,
	WEDNESDAY,
	THURSDAY,
	FRIDAY,
	SATURDAY,
	SUNDAY,
}

const DAY_NAMES: Array[String] = [
	"Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"
]


# =============================================================================
# WEATHER
# =============================================================================

enum Weather {
	SUNNY,
	RAINY,
	STORMY,    ## Chuva + raios
	SNOWY,     ## Inverno
	WINDY,     ## Debris voando
}


# =============================================================================
# DIRECTIONS
# =============================================================================

enum Direction {
	DOWN,    ## 0 — frente (padrão)
	UP,      ## 1
	LEFT,    ## 2
	RIGHT,   ## 3
}

## Vetores de direção correspondentes
const DIRECTION_VECTORS: Array[Vector2] = [
	Vector2(0, 1),   # DOWN
	Vector2(0, -1),  # UP
	Vector2(-1, 0),  # LEFT
	Vector2(1, 0),   # RIGHT
]


# =============================================================================
# TILES & GRID
# =============================================================================

const TILE_SIZE: int = 16           ## Pixels por tile (padrão pixel art)
const TILE_SIZE_F: float = 16.0


# =============================================================================
# PLAYER
# =============================================================================

const DEFAULT_MAX_ENERGY: int = 270
const DEFAULT_MOVE_SPEED: float = 80.0  ## Pixels por segundo
const ENERGY_REGEN_ON_SLEEP: float = 1.0  ## 100% ao dormir

enum ToolType {
	NONE,
	HOE,
	WATERING_CAN,
	AXE,
	PICKAXE,
	SCYTHE,
	FISHING_ROD,
	SWORD,
}

## Custo de energia por ferramenta (base, antes de upgrades)
const TOOL_ENERGY_COST: Dictionary = {
	ToolType.HOE: 2,
	ToolType.WATERING_CAN: 2,
	ToolType.AXE: 3,
	ToolType.PICKAXE: 3,
	ToolType.SCYTHE: 1,
	ToolType.FISHING_ROD: 4,
	ToolType.SWORD: 1,
}

enum ToolLevel {
	BASIC,
	COPPER,
	STEEL,
	GOLD,
	IRIDIUM,
}


# =============================================================================
# ITEMS
# =============================================================================

enum ItemType {
	TOOL,
	SEED,
	CROP_HARVEST,    ## Item produzido por uma planta
	RESOURCE,        ## Madeira, pedra, minério
	CRAFTABLE,       ## Objeto que pode ser colocado no mundo
	FOOD,            ## Consumível
	FURNITURE,       ## Decoração
	FISH,
	MINERAL,
	ARTIFACT,
	GIFT,
	SPECIAL,
}

enum ItemQuality {
	NORMAL,
	SILVER,
	GOLD,
	IRIDIUM,
}

const QUALITY_PRICE_MULTIPLIER: Dictionary = {
	ItemQuality.NORMAL: 1.0,
	ItemQuality.SILVER: 1.25,
	ItemQuality.GOLD: 1.5,
	ItemQuality.IRIDIUM: 2.0,
}

const DEFAULT_STACK_SIZE: int = 999
const HOTBAR_SIZE: int = 12
const INVENTORY_ROWS: int = 3
const INVENTORY_COLS: int = 12
const TOTAL_INVENTORY_SLOTS: int = HOTBAR_SIZE + (INVENTORY_ROWS * INVENTORY_COLS)


# =============================================================================
# TERRAIN FEATURES
# =============================================================================

enum SoilState {
	UNTILLED,
	TILLED,
	WATERED,
}

enum FertilizerType {
	NONE,
	BASIC,           ## Pequeno boost de qualidade
	QUALITY,         ## Médio boost de qualidade
	DELUXE,          ## Grande boost de qualidade
	SPEED_GRO,       ## 10% mais rápido
	DELUXE_SPEED,    ## 25% mais rápido
	HYPER_SPEED,     ## 33% mais rápido
}


# =============================================================================
# NPC & FRIENDSHIP
# =============================================================================

const MAX_FRIENDSHIP_POINTS: int = 2500  ## 10 corações × 250 pontos
const POINTS_PER_HEART: int = 250
const MAX_HEARTS: int = 10
const MAX_HEARTS_DATING: int = 14  ## Após namorar
const GIFTS_PER_WEEK_LIMIT: int = 2

enum GiftTaste {
	LOVE,       ## +80 pontos
	LIKE,       ## +45 pontos
	NEUTRAL,    ## +20 pontos
	DISLIKE,    ## -20 pontos
	HATE,       ## -40 pontos
}

const GIFT_TASTE_POINTS: Dictionary = {
	GiftTaste.LOVE: 80,
	GiftTaste.LIKE: 45,
	GiftTaste.NEUTRAL: 20,
	GiftTaste.DISLIKE: -20,
	GiftTaste.HATE: -40,
}


# =============================================================================
# SKILLS
# =============================================================================

enum SkillType {
	FARMING,
	MINING,
	FORAGING,
	FISHING,
	COMBAT,
}

const MAX_SKILL_LEVEL: int = 10

## XP necessário para cada nível (acumulativo)
const SKILL_XP_TABLE: Array[int] = [
	0, 100, 380, 770, 1300, 2150, 3300, 4800, 6900, 10000
]


# =============================================================================
# LOCATIONS
# =============================================================================

## IDs das locations base do jogo
const LOCATION_FARM: String = "farm"
const LOCATION_FARMHOUSE: String = "farmhouse"
const LOCATION_TOWN: String = "town"
const LOCATION_BEACH: String = "beach"
const LOCATION_MOUNTAIN: String = "mountain"
const LOCATION_FOREST: String = "forest"
const LOCATION_MINE: String = "mine"
const LOCATION_GENERAL_STORE: String = "general_store"
const LOCATION_BLACKSMITH: String = "blacksmith"
const LOCATION_SALOON: String = "saloon"


# =============================================================================
# SAVE/LOAD
# =============================================================================

const SAVE_DB_NAME: String = "user://farmgame_save_%d.db"
const MAX_SAVE_SLOTS: int = 3
const AUTOSAVE_ENABLED: bool = true


# =============================================================================
# MOBILE OPTIMIZATIONS
# =============================================================================

const TARGET_FPS: int = 60
const CULLING_MARGIN: int = 2  ## Tiles extras além da viewport para culling
const MAX_PARTICLES: int = 50  ## Limite de partículas simultâneas (mobile)
