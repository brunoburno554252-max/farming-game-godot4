## ui/minigames/fishing_minigame.gd
## FishingMinigame — Minigame de pesca estilo Stardew Valley.
## Barra vertical: peixe se move, jogador controla a zona verde.
## Manter o peixe dentro da zona verde enche o medidor de captura.
## Equivalente ao BobberBar do Stardew Valley.
extends Control


# =============================================================================
# CONSTANTS
# =============================================================================

const BAR_WIDTH: int = 40
const BAR_HEIGHT: int = 300
const BAR_MARGIN: int = 60

const CATCH_ZONE_MIN: float = 0.15
const CATCH_ZONE_MAX: float = 0.4
const GRAVITY: float = 800.0
const BOUNCE_FORCE: float = -380.0
const MAX_VELOCITY: float = 600.0

const CATCH_FILL_SPEED: float = 0.4
const CATCH_DRAIN_SPEED: float = 0.25
const FISH_SPEED_BASE: float = 120.0


# =============================================================================
# STATE
# =============================================================================

var _is_active: bool = false
var _fish_data: Dictionary = {}
var _difficulty: float = 0.5

## Fish position (0.0 = bottom, 1.0 = top of bar)
var _fish_pos: float = 0.5
var _fish_velocity: float = 0.0
var _fish_target: float = 0.5
var _fish_change_timer: float = 0.0

## Catch zone position (0.0 = bottom, 1.0 = top)
var _zone_pos: float = 0.3
var _zone_velocity: float = 0.0
var _zone_size: float = 0.25

## Catch progress (0.0 = nothing, 1.0 = caught)
var _catch_progress: float = 0.3

## Quality tracking
var _time_in_zone: float = 0.0
var _total_time: float = 0.0

## Visual
var _bg_rect: ColorRect
var _bar_bg: Panel
var _fish_indicator: ColorRect
var _zone_rect: ColorRect
var _progress_bg: Panel
var _progress_fill: ColorRect
var _fish_name_label: Label
var _hint_label: Label


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	name = "FishingMinigame"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_build_ui()


func _build_ui() -> void:
	# Dimmer
	_bg_rect = ColorRect.new()
	_bg_rect.color = Color(0, 0, 0, 0.4)
	_bg_rect.set_anchors_preset(PRESET_FULL_RECT)
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg_rect)
	
	# Bar background
	_bar_bg = Panel.new()
	_bar_bg.set_anchors_preset(PRESET_CENTER)
	_bar_bg.position = Vector2(-BAR_WIDTH / 2.0, -BAR_HEIGHT / 2.0)
	_bar_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.1, 0.15, 0.3, 0.9)
	bar_style.corner_radius_top_left = 6
	bar_style.corner_radius_top_right = 6
	bar_style.corner_radius_bottom_left = 6
	bar_style.corner_radius_bottom_right = 6
	bar_style.border_width_top = 2
	bar_style.border_width_bottom = 2
	bar_style.border_width_left = 2
	bar_style.border_width_right = 2
	bar_style.border_color = Color(0.3, 0.4, 0.6, 0.8)
	_bar_bg.add_theme_stylebox_override("panel", bar_style)
	add_child(_bar_bg)
	
	# Catch zone (green bar the player controls)
	_zone_rect = ColorRect.new()
	_zone_rect.color = Color(0.2, 0.7, 0.3, 0.5)
	_bar_bg.add_child(_zone_rect)
	
	# Fish indicator (small orange rect)
	_fish_indicator = ColorRect.new()
	_fish_indicator.color = Color(1.0, 0.5, 0.1, 0.9)
	_fish_indicator.size = Vector2(BAR_WIDTH - 8, 10)
	_bar_bg.add_child(_fish_indicator)
	
	# Progress bar (right side)
	_progress_bg = Panel.new()
	_progress_bg.set_anchors_preset(PRESET_CENTER)
	_progress_bg.position = Vector2(BAR_WIDTH / 2.0 + 15, -BAR_HEIGHT / 2.0)
	_progress_bg.size = Vector2(12, BAR_HEIGHT)
	var prog_style := StyleBoxFlat.new()
	prog_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	prog_style.corner_radius_top_left = 3
	prog_style.corner_radius_top_right = 3
	prog_style.corner_radius_bottom_left = 3
	prog_style.corner_radius_bottom_right = 3
	_progress_bg.add_theme_stylebox_override("panel", prog_style)
	add_child(_progress_bg)
	
	_progress_fill = ColorRect.new()
	_progress_fill.color = Color(0.3, 0.9, 0.4)
	_progress_fill.position = Vector2(2, 0)
	_progress_fill.size = Vector2(8, 0)
	_progress_bg.add_child(_progress_fill)
	
	# Fish name
	_fish_name_label = Label.new()
	_fish_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fish_name_label.set_anchors_preset(PRESET_CENTER_TOP)
	_fish_name_label.position.y = -BAR_HEIGHT / 2.0 - 30
	_fish_name_label.add_theme_font_size_override("font_size", 14)
	_fish_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	add_child(_fish_name_label)
	
	# Hint
	_hint_label = Label.new()
	_hint_label.text = "Toque/Clique para subir"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.set_anchors_preset(PRESET_CENTER_BOTTOM)
	_hint_label.position.y = BAR_HEIGHT / 2.0 + 10
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	add_child(_hint_label)


# =============================================================================
# START / STOP
# =============================================================================

func start(fish_data: Dictionary) -> void:
	_fish_data = fish_data
	_difficulty = fish_data.get("difficulty", 50) / 100.0
	
	_fish_pos = 0.5
	_fish_velocity = 0.0
	_fish_target = randf()
	_fish_change_timer = 1.0
	
	_zone_pos = 0.3
	_zone_velocity = 0.0
	_zone_size = lerpf(CATCH_ZONE_MAX, CATCH_ZONE_MIN, _difficulty)
	
	_catch_progress = 0.3
	_time_in_zone = 0.0
	_total_time = 0.0
	
	_fish_name_label.text = fish_data.get("display_name", "???")
	
	_is_active = true
	visible = true


func _finish(success: bool) -> void:
	_is_active = false
	visible = false
	
	var quality_bonus := 0.0
	if _total_time > 0:
		quality_bonus = _time_in_zone / _total_time
	
	var result := FishingSystem.finish_fishing(success, quality_bonus)
	
	if success and not result.is_empty():
		var quality_names := ["", " (Prata)", " (Ouro)", " (Irídio)"]
		var q_str: String = quality_names[result.get("quality", 0)]
		EventBus.show_notification.emit(
			"Pescou %s%s! (%dcm)" % [result.display_name, q_str, result.get("size", 0)], null
		)
	elif not success:
		EventBus.show_notification.emit("O peixe escapou...", null)
	
	EventBus.play_sfx.emit("fishing_complete" if success else "fishing_fail")


# =============================================================================
# PROCESS
# =============================================================================

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	_total_time += delta
	_update_fish(delta)
	_update_zone(delta)
	_update_catch(delta)
	_update_visuals()
	
	# Win / Lose
	if _catch_progress >= 1.0:
		_finish(true)
	elif _catch_progress <= 0.0:
		_finish(false)


func _update_fish(delta: float) -> void:
	# Fish AI - moves toward random targets
	_fish_change_timer -= delta
	if _fish_change_timer <= 0:
		_fish_target = randf()
		_fish_change_timer = randf_range(0.5, 2.0) * (1.0 - _difficulty * 0.5)
	
	var fish_speed := FISH_SPEED_BASE * (0.5 + _difficulty)
	var behavior: String = _fish_data.get("behavior", "mixed")
	
	match behavior:
		"dart":
			# Moves in sharp bursts
			if absf(_fish_pos - _fish_target) > 0.1:
				_fish_velocity = signf(_fish_target - _fish_pos) * fish_speed * 2.0
			else:
				_fish_velocity *= 0.9
		"smooth":
			# Slow, steady movement
			_fish_velocity = lerpf(_fish_velocity, (_fish_target - _fish_pos) * fish_speed * 0.5, delta * 3.0)
		"sinker":
			# Tends to sink, then jumps up
			_fish_velocity += 50.0 * delta  # Gravity bias
			if _fish_pos > 0.9:
				_fish_velocity = -fish_speed
			elif absf(_fish_pos - _fish_target) > 0.2:
				_fish_velocity += signf(_fish_target - _fish_pos) * fish_speed * delta * 3.0
		_:  # "mixed"
			_fish_velocity = lerpf(_fish_velocity, (_fish_target - _fish_pos) * fish_speed, delta * 5.0)
	
	_fish_pos += _fish_velocity * delta / BAR_HEIGHT
	_fish_pos = clampf(_fish_pos, 0.0, 1.0)
	
	# Bounce at edges
	if _fish_pos <= 0.0 or _fish_pos >= 1.0:
		_fish_velocity *= -0.5


func _update_zone(delta: float) -> void:
	var pressing := Input.is_action_pressed("use_tool") or Input.is_action_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if pressing:
		_zone_velocity -= GRAVITY * 1.5 * delta  # Go up (inverted)
	else:
		_zone_velocity += GRAVITY * delta  # Fall down
	
	_zone_velocity = clampf(_zone_velocity, -MAX_VELOCITY, MAX_VELOCITY)
	_zone_pos -= _zone_velocity * delta / BAR_HEIGHT
	
	# Clamp and bounce
	if _zone_pos < 0.0:
		_zone_pos = 0.0
		_zone_velocity *= -0.3
	elif _zone_pos + _zone_size > 1.0:
		_zone_pos = 1.0 - _zone_size
		_zone_velocity *= -0.3


func _update_catch(delta: float) -> void:
	var fish_in_zone := _fish_pos >= _zone_pos and _fish_pos <= _zone_pos + _zone_size
	
	if fish_in_zone:
		_catch_progress += CATCH_FILL_SPEED * delta
		_time_in_zone += delta
		_fish_indicator.color = Color(0.2, 1.0, 0.3, 0.9)  # Green when caught
	else:
		_catch_progress -= CATCH_DRAIN_SPEED * delta
		_fish_indicator.color = Color(1.0, 0.5, 0.1, 0.9)  # Orange when free
	
	_catch_progress = clampf(_catch_progress, 0.0, 1.0)


func _update_visuals() -> void:
	# Zone rect (position from top)
	var zone_pixel_y := (1.0 - _zone_pos - _zone_size) * (BAR_HEIGHT - 8) + 4
	var zone_pixel_h := _zone_size * (BAR_HEIGHT - 8)
	_zone_rect.position = Vector2(4, zone_pixel_y)
	_zone_rect.size = Vector2(BAR_WIDTH - 8, zone_pixel_h)
	
	# Fish indicator (position from top)
	var fish_pixel_y := (1.0 - _fish_pos) * (BAR_HEIGHT - 18) + 4
	_fish_indicator.position = Vector2(4, fish_pixel_y)
	
	# Progress bar (fills from bottom)
	var fill_h := _catch_progress * (BAR_HEIGHT - 4)
	_progress_fill.position.y = BAR_HEIGHT - 2 - fill_h
	_progress_fill.size.y = fill_h
	
	# Progress color
	if _catch_progress > 0.7:
		_progress_fill.color = Color(0.3, 0.9, 0.4)
	elif _catch_progress > 0.3:
		_progress_fill.color = Color(0.9, 0.8, 0.2)
	else:
		_progress_fill.color = Color(0.9, 0.3, 0.2)
