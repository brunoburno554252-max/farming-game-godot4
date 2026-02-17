## autoloads/audio_manager.gd
## AudioManager — Gerencia música, SFX e sons ambiente.
## Pool de SFX players, fade-in/fade-out de música, e troca automática por location.
## Funciona mesmo sem arquivos de áudio (fail-safe).
extends Node


# =============================================================================
# CONFIG
# =============================================================================

const MAX_SFX_PLAYERS: int = 8
const DEFAULT_MUSIC_VOLUME: float = 0.7
const DEFAULT_SFX_VOLUME: float = 0.8


# =============================================================================
# STATE
# =============================================================================

var _music_player: AudioStreamPlayer
var _music_fade_player: AudioStreamPlayer  ## Player auxiliar para crossfade
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_music: String = ""
var _music_volume: float = DEFAULT_MUSIC_VOLUME
var _sfx_volume: float = DEFAULT_SFX_VOLUME
var _is_fading: bool = false

## Mapa de location_id → nome da música
var _location_music: Dictionary = {
	Constants.LOCATION_FARM: "farm",
	Constants.LOCATION_FARMHOUSE: "home",
	Constants.LOCATION_TOWN: "town",
	Constants.LOCATION_BEACH: "beach",
	Constants.LOCATION_MOUNTAIN: "nature",
	Constants.LOCATION_FOREST: "nature",
	Constants.LOCATION_MINE: "mine",
	Constants.LOCATION_GENERAL_STORE: "shop",
	Constants.LOCATION_BLACKSMITH: "shop",
	Constants.LOCATION_SALOON: "saloon",
}

## Música por estação (para a fazenda)
var _season_farm_music: Dictionary = {
	Constants.Season.SPRING: "farm_spring",
	Constants.Season.SUMMER: "farm_summer",
	Constants.Season.FALL: "farm_fall",
	Constants.Season.WINTER: "farm_winter",
}


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Music players
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = linear_to_db(_music_volume)
	add_child(_music_player)
	
	_music_fade_player = AudioStreamPlayer.new()
	_music_fade_player.name = "MusicFadePlayer"
	_music_fade_player.volume_db = -80.0
	add_child(_music_fade_player)
	
	# SFX pool
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.name = "SFX_%d" % i
		player.volume_db = linear_to_db(_sfx_volume)
		add_child(player)
		_sfx_players.append(player)
	
	# Connect signals
	EventBus.play_sfx.connect(play_sfx)
	EventBus.change_music.connect(change_music)
	EventBus.stop_music.connect(stop_music)
	EventBus.location_ready.connect(_on_location_ready)
	EventBus.season_changed.connect(_on_season_changed)


# =============================================================================
# SFX
# =============================================================================

## Toca um efeito sonoro pelo nome.
## Procura em res://audio/sfx/{name}.ogg e .wav
func play_sfx(sfx_name: String) -> void:
	var stream := _load_audio("res://audio/sfx/%s" % sfx_name)
	if not stream:
		return  # Silently fail if no audio file
	
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(_sfx_volume)
			player.play()
			return
	
	# All players busy, steal the oldest (first one)
	_sfx_players[0].stream = stream
	_sfx_players[0].play()


## Define o volume de SFX (0.0 - 1.0)
func set_sfx_volume(vol: float) -> void:
	_sfx_volume = clampf(vol, 0.0, 1.0)
	for player in _sfx_players:
		player.volume_db = linear_to_db(_sfx_volume)


# =============================================================================
# MUSIC
# =============================================================================

## Troca a música com fade.
func change_music(music_name: String, fade_duration: float = 1.0) -> void:
	if music_name == _current_music:
		return
	if music_name.is_empty():
		stop_music(fade_duration)
		return
	
	var stream := _load_audio("res://audio/music/%s" % music_name)
	if not stream:
		# Não tem o arquivo de áudio, apenas registrar
		_current_music = music_name
		return
	
	_current_music = music_name
	
	if fade_duration <= 0 or not _music_player.playing:
		# Troca instantânea
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(_music_volume)
		_music_player.play()
		return
	
	# Crossfade
	_crossfade_music(stream, fade_duration)


## Para a música com fade out.
func stop_music(fade_duration: float = 1.0) -> void:
	_current_music = ""
	if fade_duration <= 0 or not _music_player.playing:
		_music_player.stop()
		return
	
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
	tween.tween_callback(_music_player.stop)


## Define o volume da música (0.0 - 1.0)
func set_music_volume(vol: float) -> void:
	_music_volume = clampf(vol, 0.0, 1.0)
	if _music_player.playing and not _is_fading:
		_music_player.volume_db = linear_to_db(_music_volume)


func _crossfade_music(new_stream: AudioStream, duration: float) -> void:
	_is_fading = true
	
	# Configurar o player de fade com a nova música
	_music_fade_player.stream = new_stream
	_music_fade_player.volume_db = -40.0
	_music_fade_player.play()
	
	# Fade out do player atual, fade in do novo
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_music_player, "volume_db", -40.0, duration)
	tween.tween_property(_music_fade_player, "volume_db", linear_to_db(_music_volume), duration)
	
	await tween.finished
	
	# Swap: mover a nova música para o player principal
	_music_player.stop()
	_music_player.stream = new_stream
	_music_player.volume_db = linear_to_db(_music_volume)
	_music_player.play()
	# Sincronizar posição
	_music_player.seek(_music_fade_player.get_playback_position())
	_music_fade_player.stop()
	
	_is_fading = false


# =============================================================================
# LOCATION-BASED MUSIC
# =============================================================================

func _on_location_ready(location_id: String) -> void:
	var music_name := ""
	
	# Fazenda: música varia por estação
	if location_id == Constants.LOCATION_FARM:
		music_name = _season_farm_music.get(TimeSystem.current_season, "farm")
	else:
		music_name = _location_music.get(location_id, "")
	
	if not music_name.is_empty():
		change_music(music_name, 1.5)


func _on_season_changed(_new_season: Constants.Season) -> void:
	# Se estamos na fazenda, trocar música da estação
	if LocationManager.current_location_id == Constants.LOCATION_FARM:
		var music_name: String = _season_farm_music.get(_new_season, "farm")
		change_music(music_name, 2.0)


# =============================================================================
# UTILITY
# =============================================================================

## Tenta carregar um arquivo de áudio (tenta .ogg e .wav)
func _load_audio(base_path: String) -> AudioStream:
	for ext in [".ogg", ".wav", ".mp3"]:
		var path := base_path + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null
