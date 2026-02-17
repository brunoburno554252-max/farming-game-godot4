## autoloads/audio_manager.gd
## AudioManager — Gerencia música, SFX e ambient sounds.
## SERÁ EXPANDIDO NA ETAPA 7.
extends Node

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_music: String = ""

const MAX_SFX_PLAYERS: int = 8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)
	
	EventBus.play_sfx.connect(play_sfx)
	EventBus.change_music.connect(change_music)
	EventBus.stop_music.connect(stop_music)


func play_sfx(sfx_name: String) -> void:
	# Encontrar um player livre
	for player in _sfx_players:
		if not player.playing:
			var path := "res://audio/sfx/%s.ogg" % sfx_name
			if ResourceLoader.exists(path):
				player.stream = load(path)
				player.play()
			return


func change_music(music_name: String, fade_duration: float = 1.0) -> void:
	if music_name == _current_music:
		return
	_current_music = music_name
	var path := "res://audio/music/%s.ogg" % music_name
	if ResourceLoader.exists(path):
		# TODO: Implementar fade na Etapa 7
		_music_player.stream = load(path)
		_music_player.play()


func stop_music(fade_duration: float = 1.0) -> void:
	_current_music = ""
	_music_player.stop()
