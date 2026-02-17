## ui/menus/skills_menu.gd
## SkillsMenu — Mostra níveis e progresso das 5 habilidades.
extends Control


var _bg_panel: Panel
var _skill_rows: Array[Dictionary] = []


func _ready() -> void:
	name = "SkillsMenu"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.set_anchors_preset(PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	var pw: int = 340
	var ph: int = 340
	_bg_panel = Panel.new()
	_bg_panel.set_anchors_preset(PRESET_CENTER)
	_bg_panel.position = Vector2(-pw / 2.0, -ph / 2.0)
	_bg_panel.size = Vector2(pw, ph)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.4, 0.35, 0.5, 0.7)
	_bg_panel.add_theme_stylebox_override("panel", style)
	add_child(_bg_panel)
	
	var title := Label.new()
	title.text = "Habilidades"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	title.position = Vector2(0, 12)
	title.size.x = pw
	_bg_panel.add_child(title)
	
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(20, 50)
	vbox.custom_minimum_size.x = pw - 40
	vbox.add_theme_constant_override("separation", 12)
	_bg_panel.add_child(vbox)
	
	var skill_names := ["Agricultura", "Mineração", "Coleta", "Pesca", "Combate"]
	var skill_colors := [
		Color(0.4, 0.8, 0.3), Color(0.6, 0.5, 0.4), Color(0.3, 0.7, 0.5),
		Color(0.3, 0.5, 0.9), Color(0.8, 0.3, 0.3)
	]
	
	for i in Constants.SkillType.size():
		var row := {}
		var skill_type: Constants.SkillType = i as Constants.SkillType
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		
		var name_lbl := Label.new()
		name_lbl.text = skill_names[i]
		name_lbl.custom_minimum_size.x = 90
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", skill_colors[i])
		hbox.add_child(name_lbl)
		
		var level_lbl := Label.new()
		level_lbl.custom_minimum_size.x = 35
		level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_lbl.add_theme_font_size_override("font_size", 14)
		level_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		hbox.add_child(level_lbl)
		
		var bar_bg := Panel.new()
		bar_bg.custom_minimum_size = Vector2(120, 14)
		var bar_style := StyleBoxFlat.new()
		bar_style.bg_color = Color(0.15, 0.13, 0.2, 0.9)
		bar_style.corner_radius_top_left = 3
		bar_style.corner_radius_top_right = 3
		bar_style.corner_radius_bottom_left = 3
		bar_style.corner_radius_bottom_right = 3
		bar_bg.add_theme_stylebox_override("panel", bar_style)
		hbox.add_child(bar_bg)
		
		var bar_fill := ColorRect.new()
		bar_fill.color = skill_colors[i]
		bar_fill.position = Vector2(2, 2)
		bar_fill.size = Vector2(0, 10)
		bar_bg.add_child(bar_fill)
		
		vbox.add_child(hbox)
		row["level_label"] = level_lbl
		row["bar_fill"] = bar_fill
		row["skill_type"] = skill_type
		_skill_rows.append(row)


func open() -> void:
	_refresh()
	UIManager.open_menu(self)


func close() -> void:
	UIManager.close_top_menu()


func _refresh() -> void:
	for row in _skill_rows:
		var skill: Constants.SkillType = row.skill_type
		var level := SkillSystem.get_level(skill)
		var progress := SkillSystem.get_xp_progress(skill)
		
		row.level_label.text = "Lv.%d" % level
		row.bar_fill.size.x = 116.0 * progress


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
		close()
		get_viewport().set_input_as_handled()
