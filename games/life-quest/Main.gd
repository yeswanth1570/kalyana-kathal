extends Node2D

const School = preload("res://SchoolChapter.gd")
const SchoolScenes = preload("res://SchoolScenes.gd")
const Story = preload("res://Stages.gd")
const DISPLAY_FONT: Font = preload("res://fonts/CinzelDecorative-Bold.ttf")
const COVER: Texture2D = preload("res://art/cover-v2.png")
const HERO_SHEET: Texture2D = preload("res://art/hero_sheet-v2.png")
const HERO_RUN: Texture2D = preload("res://art/hero-run-alpha-v3.png")
const REACTION_FACES: Texture2D = preload("res://art/reaction-faces-v5.png")
const SCHOOL_OPENING: Texture2D = preload("res://art/school-opening-v6.png")
const SchoolArt = preload("res://SchoolArt.gd")
const SchoolMotion = preload("res://SchoolMotion.gd")
const CAST_SHEET: Texture2D = preload("res://art/cast_sheet-v2.png")
const SCENERY: Array[Texture2D] = [preload("res://art/school-v2.png"),preload("res://art/college-v2.png"),preload("res://art/office-v2.png"),preload("res://art/family-v2.png"),preload("res://art/wedding-v2.png")]
const INK := Color("203936")
const PAPER := Color("f6e9cf")
const GOLD := Color("dca74e")
const ROSE := Color("bf505e")
const TEAL := Color("347c75")
const SAVE := "user://school-preview.cfg"
const LEGACY_SAVE := "user://life-quest.cfg"
const THRESHOLDS := [70.0, 40.0, 12.0]
const ACTIVITIES := {
	1: {"name":"GYM BENCH", "action":"Train", "reward":"Gym strength · faster dash recovery"},
	3: {"name":"BARBER CHAIR", "action":"Get a haircut", "reward":"Fresh cut · +40 charm"}
}

var school := School.new()
var school_resolution := ""
var school_action_button: Button
var school_ducking := false
var school_duck_latched := false
var school_move_touches: Dictionary = {}
var school_speed := 0.0
var school_duck_blend := 0.0
var school_step_phase := 0.0
var school_moving := false
var school_mood: int = SchoolMotion.Mood.FOCUSED
var school_relief := 0.0
var school_whistle := 0.0
var master_stride := 0.0
var school_bell_pulse := 0.0
var school_last_bell := false
var school_breeze := 0.0
var school_breeze_triggered := false
var school_has_spoken := false
var state := "title"
var previous_state := "title"
var stage := 0
var phase := 0
var unlocked := 0
var completed := false
var gentle := true
var sound_on := true
var reduce_motion := false
var auto_fire := false
var age := 0.0
var elapsed := 0.0
var player := Vector2.ZERO
var velocity := Vector2.ZERO
var facing := 1.0
var hp := 5
var max_hp := 5
var resistance := 100.0
var approval := 20
var charm := 0.0
var shot_clock := 0.0
var attack_pose := 0.0
var landing_pose := 0.0
var run_cycle := 0.0
var camera_x := 0.0
var impact_position := Vector2.ZERO
var impact_text := ""
var impact_time := 0.0
var face_frame := 0
var face_time := 0.0
var activity_claimed := false
var activity_button: Button
var windup := 0.0
var master_x := 0.0
var master_facing := 1.0
var master_turn := 0.0
var awareness := 0.0
var hidden_in_cover := false
var offline_run := false
var dialogue_id := 0
var notice := ""
var notice_time := 0.0
var hazard_clock := 1.5
var hazard_count := 0
var invincible := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var parry_time := 0.0
var parry_cooldown := 0.0
var used_tiffin := false
var attack_speed := 1.0
var shake := 0.0
var flashes := 0.0
var boss_flash := 0.0
var shots: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var held: Dictionary = {}
var pointer_actions: Dictionary = {}
var control_rects: Dictionary = {}
var response := ""
var last_score := 0
var last_question := ""
var font: Font
var ui: CanvasLayer
var root: Control
var screen: Control
var hud: Control
var hp_label: Label
var progress_label: Label
var status_label: Label
var boss_label: Label
var resistance_bar: ProgressBar
var charm_bar: ProgressBar
var talk_button: Button
var heal_button: Button
var dialogue_input: LineEdit
var qwen: Node
var chat_messages: Array[Dictionary] = []
var agent_histories: Dictionary = {}
var title_chat_notice := ""
var chat_only := false
var chat_turns := 0
var phase_gain := 0
var chat_error := ""
var chat_pending := false
var chat_draft := ""
var web_callback
var chat_status: Label
var chat_send: Button
var chat_back: Button
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var viewport_size := Vector2(1100, 700)
var portrait := false
var ui_scale := 1.0
var rng := RandomNumberGenerator.new()
var paint_styles: Dictionary = {}

func _ready() -> void:
	font = ThemeDB.fallback_font
	font.fallbacks = [preload("res://fonts/NotoSansTamil-Regular.ttf")]
	rng.randomize()
	_load_progress()
	_setup_audio()
	qwen = preload("res://QwenClient.gd").new()
	add_child(qwen)
	qwen.replied.connect(_apply_agent_reply)
	qwen.failed.connect(_agent_failed)
	if OS.has_feature("web"):
		web_callback = JavaScriptBridge.create_callback(_web_chat_event)
		JavaScriptBridge.get_interface("window").kalyanaGameEvent = web_callback
	ui = CanvasLayer.new()
	add_child(ui)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	get_viewport().size_changed.connect(_resize)
	_resize()
	get_window().focus_exited.connect(_lost_focus)
	_show_title()

func _setup_audio() -> void:
	music = AudioStreamPlayer.new()
	music.stream = preload("res://audio/cinema.wav")
	music.finished.connect(music.play)
	music.volume_db = -22
	add_child(music)
	sfx = AudioStreamPlayer.new()
	sfx.volume_db = -14
	sfx.max_polyphony = 6
	add_child(sfx)

func _sound(kind: String) -> void:
	if not sound_on:
		return
	match kind:
		"bell": sfx.stream = preload("res://audio/school-bell.wav")
		"whistle": sfx.stream = preload("res://audio/school-whistle.wav")
		"hit": sfx.stream = preload("res://audio/hit.wav")
		"parry": sfx.stream = preload("res://audio/parry.wav")
		"win": sfx.stream = preload("res://audio/win.wav")
		_: sfx.stream = preload("res://audio/letter.wav")
	sfx.play()

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK or cfg.load(LEGACY_SAVE) == OK:
		unlocked = clampi(int(cfg.get_value("progress", "unlocked", 0)), 0, 4)
		completed = bool(cfg.get_value("progress", "completed", false))
		school.unlocked = clampi(int(cfg.get_value("school", "unlocked", 2 if unlocked > 0 else 0)),0,2)
		school.checkpoint = clampi(int(cfg.get_value("school", "checkpoint", 0)),0,school.unlocked)
		school.level = school.checkpoint
		school.honor_pass = bool(cfg.get_value("school", "honor_pass", false))
		school.supervised = school.checkpoint < School.Level.WALK_HOME and bool(cfg.get_value("school", "supervised", cfg.get_value("school", "repair", false)))
		school.meeting_pending = school.checkpoint < School.Level.WALK_HOME and bool(cfg.get_value("school", "meeting", false))
		if school.meeting_pending:
			var saved_decision = cfg.get_value("school","meeting_resolution","")
			school.meeting_resolution = saved_decision if saved_decision in ["conditional","retry"] else ""
			school.turns = clampi(int(cfg.get_value("school","meeting_turns",0)),0,school.turn_limit())
			var saved_concerns = cfg.get_value("school","meeting_concerns",[])
			if saved_concerns is Array:
				for concern in school.required_concerns():
					if concern in saved_concerns: school.concerns_met.append(concern)
		gentle = bool(cfg.get_value("settings", "gentle", true))
		sound_on = bool(cfg.get_value("settings", "sound", true))
		reduce_motion = bool(cfg.get_value("settings", "reduce_motion", false))
		auto_fire = bool(cfg.get_value("settings", "auto_fire", false)) if int(cfg.get_value("settings", "controls_version", 0)) >= 3 else false

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "completed", completed)
	cfg.set_value("school", "unlocked", school.unlocked)
	cfg.set_value("school", "checkpoint", school.checkpoint)
	cfg.set_value("school", "honor_pass", school.honor_pass)
	cfg.set_value("school", "supervised", school.supervised)
	cfg.set_value("school", "meeting", school.meeting_pending)
	if school.meeting_pending:
		cfg.set_value("school", "meeting_resolution", school.meeting_resolution)
		cfg.set_value("school", "meeting_turns", school.turns)
		cfg.set_value("school", "meeting_concerns", school.concerns_met)
	cfg.set_value("settings", "gentle", gentle)
	cfg.set_value("settings", "sound", sound_on)
	cfg.set_value("settings", "reduce_motion", reduce_motion)
	cfg.set_value("settings", "auto_fire", auto_fire)
	cfg.set_value("settings", "controls_version", 3)
	var error := cfg.save(SAVE)
	if error != OK:
		push_warning("Progress could not be saved on this device (%s)." % error)

func floor_y() -> float:
	return viewport_size.y * (0.715 if stage == 0 else 0.72) if portrait else viewport_size.y - 172.0

func boss_position() -> Vector2:
	return Vector2(master_x if stage == 0 else viewport_size.x - 150, floor_y())

func _stage_width() -> float:
	if stage != 0: return viewport_size.x
	if school.level == School.Level.CORRIDOR: return viewport_size.x+168.0
	var art := SchoolScenes.background(school.level).get_size()
	return maxf(viewport_size.x+440.0,(floor_y()-200.0)*art.x/(art.y*0.80))

func _follow_camera(dt: float) -> void:
	if stage != 0:
		camera_x = 0.0
		return
	var target := clampf(player.x - viewport_size.x * 0.44, 0.0, _stage_width()-viewport_size.x)
	camera_x = target if reduce_motion else lerpf(camera_x,target,1.0-exp(-12.0*dt))

func _resize() -> void:
	var old_floor := floor_y()
	var scene_position := player.x/maxf(1.0,_stage_width())
	viewport_size = get_viewport_rect().size
	portrait = viewport_size.y > viewport_size.x
	ui_scale = 2.0 if portrait else 1.0
	if stage == 0 and school.level != School.Level.CORRIDOR:
		player.x = scene_position*_stage_width()
	player.x = clampf(player.x, 48, _stage_width() - (55 if stage == 0 else 295))
	master_x = clampf(master_x, viewport_size.x * 0.40, _stage_width() - 220)
	camera_x = clampf(player.x - viewport_size.x * 0.44,0.0,_stage_width()-viewport_size.x) if stage == 0 else 0.0
	player.y = floor_y() + minf(player.y - old_floor, 0)
	shots.clear()
	hazards.clear()
	_clear_input()
	_apply_theme()
	if is_instance_valid(screen):
		match state:
			"title": _show_title()
			"map": _show_map()
			"intro": _show_intro()
			"school_map": _show_school_map()
			"school_result": _show_school_result()
			"school_ending": _show_school_ending()
			"dialogue": _show_dialogue()
			"clear": _show_clear()
			"defeat": _show_defeat()
			"credits": _show_credits()
			"paused": _show_pause()
			"settings": _show_settings()
			"help": _show_help()
			_: _make_hud()
	queue_redraw()

func _apply_theme() -> void:
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = int(24 * ui_scale)
	theme.set_color("font_color", "Label", PAPER)
	for kind in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bg := TEAL
		if kind == "hover": bg = Color("46998c")
		if kind == "pressed": bg = Color("b16454")
		if kind == "disabled": bg = Color("52605a")
		var style := _style(bg, GOLD if kind == "focus" else bg.lightened(0.14), 14)
		style.content_margin_left = 22
		style.content_margin_right = 22
		style.content_margin_top = 16 * ui_scale
		style.content_margin_bottom = 16 * ui_scale
		theme.set_stylebox(kind, "Button", style)
		theme.set_color("font_" + ("color" if kind == "normal" else kind + "_color"), "Button", PAPER)
	theme.set_stylebox("normal", "LineEdit", _style(Color("f4e4c5"), GOLD, 12))
	theme.set_stylebox("focus", "LineEdit", _style(Color("fff4db"), TEAL, 12))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color("65736a"))
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_stylebox("background", "ProgressBar", _style(Color("263e39"), Color("527068"), 5))
	theme.set_stylebox("fill", "ProgressBar", _style(ROSE, ROSE, 5))
	root.theme = theme

func _style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var key := "%s/%s/%d" % [bg.to_html(),border.to_html(),radius]
	if paint_styles.has(key): return paint_styles[key]
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0.02,0.08,0.06,0.30)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0,4)
	paint_styles[key] = box
	return box

func _clear_screen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("document").body.dataset.scene = state
	_clear_input()
	if is_instance_valid(screen):
		root.remove_child(screen)
		screen.queue_free()
	if is_instance_valid(hud):
		root.remove_child(hud)
		hud.queue_free()
		hud = null
	screen = Control.new()
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen)

func _modal(width: float = 850.0) -> VBoxContainer:
	_clear_screen()
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.11, 0.10, 0.87)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 30
	center.offset_right = -30
	center.offset_top = 24
	center.offset_bottom = -24
	screen.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = viewport_size.x - 60 if portrait else minf(width, viewport_size.x - 60)
	panel.add_theme_stylebox_override("panel", _style(Color(0.07,0.16,0.14,0.96), Color("b99b61"), 20))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(14 * ui_scale))
	margin.add_child(column)
	return column

func _label(parent: Node, text: String, size: int = 24, color: Color = PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(size * ui_scale))
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, title: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 62 * ui_scale
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		var main_style := _style(ROSE, Color("e38f85"), 14)
		main_style.content_margin_left = 22
		main_style.content_margin_right = 22
		main_style.content_margin_top = 16*ui_scale
		main_style.content_margin_bottom = 16*ui_scale
		button.add_theme_stylebox_override("normal", main_style)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	return row

func _show_title() -> void:
	state = "title"
	_clear_screen()
	var panel := PanelContainer.new()
	panel.position = Vector2(54, 46 if not portrait else 130)
	panel.size = Vector2(viewport_size.x - 108 if portrait else minf(600, viewport_size.x - 108), 0)
	panel.add_theme_stylebox_override("panel", _style(Color(0.055,0.15,0.14,0.78), Color("bc9b60"), 20))
	screen.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(12 * ui_scale))
	margin.add_child(col)
	_label(col, "A TAMIL CINEMA ADVENTURE", 18, GOLD)
	_label(col, "KALYANA\nKATHAL", 58 if portrait else 49, PAPER).add_theme_font_override("font",DISPLAY_FONT)
	_label(col, "T H E   L I F E   Q U E S T", 19, Color("a9c8b8"))
	_label(col, "Dodge the drama. Find the words.\nFrom a folded note to forever.", 23)
	var play := _button(col, "Choose your act  >" if unlocked > 0 else "Let the story begin  >", _show_map, true)
	_button(col,"Chat with Sharmila · Qwen",_meet_sharmila)
	if not title_chat_notice.is_empty(): _label(col, title_chat_notice, 16, GOLD)
	var row := _row(col)
	_button(row, "How to play", _show_help)
	_button(row, "Settings", _open_settings)
	_label(col, "5 ACTS  /  TOUCH + KEYBOARD  /  SAVED ON DEVICE", 13, Color("b6c6b5"))
	play.grab_focus()

func _meet_sharmila() -> void:
	stage = 1
	_start_stage()
	chat_only = true
	_open_dialogue()

func _show_map() -> void:
	state = "map"
	var col := _modal(880)
	_label(col, "THE REELS OF YOUR LIFE", 18, GOLD)
	_label(col, "Every chapter has a boss.", 35)
	for i in range(5):
		var act: Dictionary = Story.ACTS[i]
		var unlocked_act := i <= unlocked
		var title := "%02d   %s   ·   %s" % [i + 1, act.name, act.year]
		if not unlocked_act: title += "  [locked]"
		var button := _button(col, title, _select_act.bind(i), i == unlocked)
		button.icon = SCENERY[i]
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",int(86*ui_scale))
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not unlocked_act
		button.add_theme_font_size_override("font_size", int(22 * ui_scale))
	_label(col, "Replay any unlocked act. New acts unlock when you clear the last.", 18, Color("b9c9b8"))
	_button(col, "<  Title screen", _show_title)

func _select_act(index: int) -> void:
	stage = index
	if stage == 0:
		_show_school_map()
	else:
		_show_intro()

func _show_school_map() -> void:
	state = "school_map"
	var col := _modal()
	_label(col,"SCHOOL  /  1999",16,GOLD)
	_label(col,"The Folded Note",38)
	for i in range(3):
		var marker := ""
		if i == school.checkpoint:
			if school.meeting_pending: marker = "  •  Meeting"
			elif school.supervised: marker = "  •  Supervised retry"
		var button := _button(col, "%d   %s%s" % [i+1,school.TITLES[i],marker],_select_school_level.bind(i),i==school.checkpoint)
		button.disabled = i > school.unlocked
	_button(col,"<  All chapters",_show_map)

func _select_school_level(index: int) -> void:
	if index != school.checkpoint:
		school.meeting_pending = false
		school.meeting_resolution = ""
		school.supervised = false
	school.level = index
	school.checkpoint = index
	_save_progress()
	_show_intro()

func _show_intro() -> void:
	if stage == 0 and school.meeting_pending:
		school.outcome = "failure"
		school.reason = "caught"
		school_resolution = school.meeting_resolution
		_show_school_result()
		return
	state = "intro"
	var col := _modal()
	if stage == 0:
		_label(col,"THE FOLDED NOTE  /  SCENE %d OF 3" % (school.level+1),16,GOLD)
		_label(col,school.TITLES[school.level],37)
		var still := TextureRect.new()
		still.texture = SCHOOL_OPENING if school.level == School.Level.CORRIDOR else SchoolScenes.background(school.level)
		still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		still.custom_minimum_size.y = 330.0 if portrait else 145.0
		col.add_child(still)
		if not reduce_motion:
			still.modulate.a = 0.0
			still.create_tween().tween_property(still,"modulate:a",1.0,0.35)
		_label(col,school.INTRO[school.level],22)
		_label(col,school.PROMPTS[school.level],18,Color("b9d0ba"))
		if school.supervised: _label(col,"Supervised retry • More time between looks",17,GOLD)
		_button(col,"Action!  >",_start_stage,true).grab_focus()
		_button(col,"<  School scenes",_show_school_map)
		return
	var act: Dictionary = Story.ACTS[stage]
	_label(col, "ACT %02d  /  %s" % [stage + 1, act.year], 18, GOLD)
	_label(col, act.name, 46)
	_label(col, act.place + "  ·  " + act.boss, 20, Color("b9d0ba"))
	_label(col, act.intro, 25)
	_label(col, "Lower the resistance shield to open three conversations.\nEarn 72 trust to clear this act. If Qwen is offline, conversations are skipped.", 20)
	_label(col, "DIRECTOR'S NOTE: " + act.hint, 18, GOLD)
	_button(col, "Action!  >", _start_stage, true).grab_focus()
	_button(col, "<  All acts", _show_map)

func _start_stage() -> void:
	title_chat_notice = ""
	qwen.cancel()
	chat_only = false
	state = "playing"
	if stage == 0:
		school.reset_attempt()
		school_resolution = ""
		school_ducking = false
		school_duck_latched = false
		school_speed = 0.0
		school_duck_blend = 0.0
		school_step_phase = 0.0
		school_moving = false
		school_mood = SchoolMotion.Mood.FOCUSED
		school_relief = 0.0
		school_whistle = 0.0
		master_stride = 0.0
		school_bell_pulse = 0.85
		school_last_bell = false
		school_breeze = 0.0
		school_breeze_triggered = false
		school_has_spoken = false
		chat_messages.clear()
		chat_error = ""
		response = ""
	phase = 0
	max_hp = 6 if gentle else 4
	hp = max_hp
	resistance = 100
	approval = 20
	charm = 0
	player = Vector2(112 if stage == 0 else 160, floor_y())
	if stage == 0 and school.level == School.Level.CLASSROOM:
		player.x = _stage_width()*float(School.BENCHES[0])
	velocity = Vector2.ZERO
	facing = 1
	shot_clock = 0
	attack_pose = 0
	landing_pose = 0
	run_cycle = 0
	camera_x = 0.0
	face_time = 0.0
	activity_claimed = false
	impact_time = 0.0
	flashes = 0.0
	boss_flash = 0.0
	shake = 0.0
	windup = 0
	master_x = viewport_size.x * 0.57
	master_facing = 1
	master_turn = 0
	awareness = 0
	hidden_in_cover = false
	offline_run = false
	notice = ""
	notice_time = 0
	_clear_input()
	hazard_clock = 2.4
	hazard_count = 0
	elapsed = 0
	invincible = 1.5
	dash_time = 0
	dash_cooldown = 0
	parry_time = 0
	parry_cooldown = 0
	attack_speed = 1
	used_tiffin = false
	shots.clear()
	hazards.clear()
	particles.clear()
	_make_hud()
	if sound_on and not music.playing:
		music.play()

func _make_hud() -> void:
	_clear_screen()
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := PanelContainer.new()
	top.position = Vector2(22,22)
	top.size.x = viewport_size.x - 44
	top.add_theme_stylebox_override("panel", _style(Color(0.10,0.23,0.21,0.95), Color("8e916a"), 16))
	hud.add_child(top)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	top.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)
	var line := _row(col)
	hp_label = _label(line, "", 20, PAPER)
	var pause_button := _button(line, "II  Pause", _pause)
	pause_button.custom_minimum_size = Vector2(155 * ui_scale, 0)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_compact_button(pause_button)
	progress_label = _label(col, "", 14, GOLD)
	boss_label = _label(col, Story.ACTS[stage].boss.to_upper() + "  /  RESISTANCE", 14, Color("d7c9b3"))
	resistance_bar = ProgressBar.new()
	resistance_bar.custom_minimum_size.y = 12 * ui_scale
	resistance_bar.show_percentage = false
	col.add_child(resistance_bar)
	charm_bar = ProgressBar.new()
	charm_bar.custom_minimum_size.y = 6 * ui_scale
	charm_bar.show_percentage = false
	charm_bar.add_theme_stylebox_override("fill", _style(GOLD, GOLD, 4))
	col.add_child(charm_bar)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 14)
	col.add_child(tools)
	heal_button = _button(tools, "Tiffin +2 HP [H]", _heal)
	talk_button = _button(tools, "Speak · fill gold meter [R]", _manual_talk)
	talk_button.disabled = true
	_compact_button(heal_button)
	_compact_button(talk_button)
	status_label = Label.new()
	status_label.position = Vector2(28, floor_y() + 28)
	status_label.size = Vector2(viewport_size.x - 56, 48 * ui_scale)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", int(19 * ui_scale))
	hud.add_child(status_label)
	var h := 80.0 * ui_scale
	var y := viewport_size.y - h - 24
	var b := (viewport_size.x - 80) / 6.0
	control_rects = {
		"left": Rect2(22,y,b,h), "right": Rect2(30+b,y,b,h),
		"dash": Rect2(viewport_size.x-4*b-50,y,b,h),
		"parry": Rect2(viewport_size.x-3*b-40,y,b,h),
		"jump": Rect2(viewport_size.x-2*b-30,y,b,h),
		"fire": Rect2(viewport_size.x-b-22,y,b,h)
	}
	if stage == 0:
		heal_button.hide()
		talk_button.hide()
		charm_bar.hide()
		_school_control_layout(y,h)
	if stage == 0 and school.level == School.Level.CLASSROOM:
		school_action_button = _button(hud,"Offer Note [E]",_school_interact,true)
		_compact_button(school_action_button)
		school_action_button.position = Vector2(viewport_size.x-204*ui_scale,y-62*ui_scale)
		school_action_button.focus_mode = Control.FOCUS_NONE
		school_action_button.hide()
	if ACTIVITIES.has(stage):
		activity_button = _button(hud, ACTIVITIES[stage].action + " [E]", _use_activity, true)
		_compact_button(activity_button)
		activity_button.focus_mode = Control.FOCUS_NONE
		activity_button.hide()
	_update_hud()

func _school_control_layout(y: float, height: float) -> void:
	var width := viewport_size.x
	var move_width := clampf(width*0.38, 280.0, 450.0)
	var gap := 10.0
	var left_button := (move_width-gap)/2.0
	control_rects = {
		"left":Rect2(22,y,left_button,height),
		"right":Rect2(22+left_button+gap,y,left_button,height),
	}
	var actions: Array = ["dash","sneak"] if school.level == School.Level.CORRIDOR else ["sneak"]
	if school.level == School.Level.WALK_HOME: return
	var group_width := minf(width-44.0-move_width-40.0, 560.0)
	var button_width := (group_width-gap*(actions.size()-1))/float(actions.size())
	var start_x := width-22.0-group_width
	for i in actions.size():
		control_rects[actions[i]] = Rect2(start_x+i*(button_width+gap),y,button_width,height)

func _activity_position() -> Vector2:
	return Vector2(viewport_size.x*0.46,floor_y())

func _near_activity() -> bool:
	return state == "playing" and ACTIVITIES.has(stage) and not activity_claimed and player.distance_to(_activity_position()) <= 92.0

func _use_activity() -> void:
	if not _near_activity(): return
	activity_claimed = true
	if stage == 1: dash_cooldown = minf(dash_cooldown,0.55)
	if stage == 3: charm = minf(100.0,charm+40.0)
	face_frame = 2
	face_time = 0.8
	notice = ACTIVITIES[stage].reward
	notice_time = 3.2
	_burst(_activity_position()+Vector2(0,-75),GOLD,18)
	_sound("parry")
	_update_hud()

func _compact_button(button: Button) -> void:
	button.custom_minimum_size.y = 42*ui_scale
	button.add_theme_font_size_override("font_size",int(18*ui_scale))
	for key in ["normal","hover","pressed","focus","disabled"]:
		var style := button.get_theme_stylebox(key).duplicate() as StyleBoxFlat
		style.content_margin_top = 8*ui_scale
		style.content_margin_bottom = 8*ui_scale
		style.content_margin_left = 12
		style.content_margin_right = 12
		button.add_theme_stylebox_override(key,style)

func _update_hud() -> void:
	if not is_instance_valid(hud): return
	if is_instance_valid(activity_button):
		activity_button.visible = _near_activity()
		if activity_button.visible:
			var pos := _activity_position()
			activity_button.position = Vector2(pos.x-camera_x-activity_button.size.x/2,pos.y-128*ui_scale)
	hp_label.text = "MURUGAN   ·   HP %d / %d" % [hp, max_hp]
	if stage == 0:
		var time_left := maxi(0,ceili(school.TIMES[school.level]-elapsed))
		var street := school.level == School.Level.WALK_HOME
		hp_label.text = "SCHOOL %d / 3" % (school.level+1)
		if not street: hp_label.text += "   |   %ds" % time_left
		progress_label.text = school.TITLES[school.level] + ("   |   HONOR PASS" if school.honor_pass else "")
		if is_instance_valid(school_action_button):
			school_action_button.visible = _can_offer_note()
		boss_label.visible = not street
		resistance_bar.visible = not street
		boss_label.text = "SUNDARAM’S AWARENESS" if school.level == School.Level.CORRIDOR else _classroom_cue()
		resistance_bar.value = awareness
		resistance_bar.add_theme_stylebox_override("fill", _style(ROSE if awareness > 60 else GOLD, GOLD, 4))
		status_label.text = "Hidden" if hidden_in_cover else ("Seen • Get behind cover" if awareness > 5 else ("Tap Duck to stand" if school_duck_latched else "Tap Duck to sneak"))
		if school.level == School.Level.CLASSROOM:
			status_label.text = "Hidden behind a desk" if hidden_in_cover else "Move between desks while she writes"
			if _can_offer_note(): status_label.text = "Sharmila is within reach"
			if school.note_time > 0.0: status_label.text = "Sharmila takes the note"
		elif street:
			status_label.text = "Meet Sharmila at the bus stop"
		if notice_time > 0: status_label.text = notice
		return
	progress_label.text = "ACT %02d / 05   %s   ·   TRUST %d/72   ·   TALK %d/3" % [stage+1, Story.ACTS[stage].place, approval, mini(phase+1,3)]
	resistance_bar.value = resistance
	charm_bar.value = charm
	talk_button.disabled = charm < 100
	talk_button.text = "Speak now [R]" if charm >= 100 else "Speak · parry for gold [R]"
	heal_button.disabled = used_tiffin or hp >= max_hp
	heal_button.text = "Tiffin used" if used_tiffin else "Tiffin +2 HP [H]"
	status_label.text = "Windup! Get ready to dodge" if windup > 0 else ("Pink petals can be parried · %s" % ("Auto letters ON" if auto_fire else "Hold LETTER / J to fire"))
	if notice_time > 0: status_label.text = notice

func _process(delta: float) -> void:
	var dt := minf(delta, 0.04)
	age += dt
	flashes = maxf(0, flashes - dt)
	boss_flash = maxf(0, boss_flash - dt)
	shake = maxf(0, shake - dt * 25)
	_update_particles(dt)
	if state == "playing":
		_tick(dt)
	queue_redraw()

func _tick(dt: float) -> void:
	elapsed += dt
	invincible = maxf(0, invincible - dt)
	dash_time = maxf(0, dash_time - dt)
	dash_cooldown = maxf(0, dash_cooldown - dt)
	parry_time = maxf(0, parry_time - dt)
	parry_cooldown = maxf(0, parry_cooldown - dt)
	shot_clock -= dt
	attack_pose = maxf(0, attack_pose-dt)
	landing_pose = maxf(0, landing_pose-dt)
	notice_time = maxf(0, notice_time-dt)
	impact_time = maxf(0, impact_time-dt)
	face_time = maxf(0, face_time-dt)
	var axis := 0.0
	if _held("left") or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): axis -= 1
	if _held("right") or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): axis += 1
	if stage != 0 and axis != 0 and dash_time <= 0: facing = axis
	school_ducking = stage == 0 and school.level != School.Level.WALK_HOME and dash_time <= 0 and _sneaking()
	if stage == 0 and (school.stumble > 0.0 or school.note_time > 0.0): axis = 0.0
	if stage == 0:
		var speed_limit := 144.0 if school_ducking else 270.0
		if school.level == School.Level.WALK_HOME and absf(player.x-_stage_width()*School.STALL) < 90.0:
			speed_limit = 155.0
		var target_speed := axis*speed_limit
		school_speed = move_toward(school_speed,target_speed,(3100.0 if axis == 0 else 2650.0)*dt)
		school_duck_blend = move_toward(school_duck_blend,float(school_ducking),dt*(13.0 if reduce_motion else 6.8))
		if dash_time <= 0 and absf(school_speed)>22.0: facing = signf(school_speed)
	var old_x := player.x
	if dash_time > 0:
		player.x += facing * (650.0 if stage==0 else 800.0) * dt
		if int(age * 50) % 3 == 0: _burst(player + Vector2(0,-35), TEAL, 1)
	else:
		player.x += (school_speed if stage == 0 else axis*270.0)*dt
	player.x = clampf(player.x, 48, _stage_width() - (55 if stage == 0 else 295))
	run_cycle += absf(player.x-old_x) / 30.0
	if player.y < floor_y() or velocity.y < 0:
		velocity.y += 1250 * dt
		player.y += velocity.y * dt
		if player.y >= floor_y():
			player.y = floor_y()
			velocity.y = 0
			landing_pose = 0.16
			_burst(player, Color("d5c8a8"), 4)
	if stage == 0:
		var distance := absf(player.x-old_x)
		school_moving = distance > 12.0*dt
		if school_moving and dash_time <= 0.0:
			school_step_phase = SchoolMotion.advance_step(school_step_phase,distance,school_ducking)
		match school.level:
			School.Level.CORRIDOR: _tick_stealth(dt)
			School.Level.CLASSROOM: _tick_classroom(dt)
			School.Level.WALK_HOME: _tick_walk_home(dt,old_x)
		_follow_camera(dt)
		_update_hud()
		return
	if (auto_fire or _held("fire") or Input.is_physical_key_pressed(KEY_J) or Input.is_physical_key_pressed(KEY_X)) and shot_clock <= 0:
		_fire()
	if windup > 0:
		windup = maxf(0, windup-dt)
		if windup <= 0:
			_spawn_pattern()
			hazard_clock = maxf(1.0, (1.8 if gentle else 1.45) - phase * 0.12) / attack_speed
	else:
		hazard_clock -= dt
		if hazard_clock <= 0: windup = 0.65
	for i in range(shots.size()-1,-1,-1):
		var bullet: Dictionary = shots[i]
		bullet.p += bullet.v * dt
		var target := boss_position() + Vector2(0,-62)
		if absf(bullet.p.x-target.x) < 48 and absf(bullet.p.y-target.y) < 88:
			resistance = maxf(0, resistance - 3.5)
			boss_flash = 0.10
			charm = minf(100, charm + 2)
			_burst(bullet.p, ROSE, 8)
			_impact(bullet.p, "POW!")
			if not reduce_motion: shake = maxf(shake, 2.4)
			shots.remove_at(i)
		elif bullet.p.x > viewport_size.x + 30 or bullet.p.x < -30 or bullet.p.y < -40 or bullet.p.y > viewport_size.y:
			shots.remove_at(i)
	for i in range(hazards.size()-1,-1,-1):
		if state != "playing": break
		var hazard: Dictionary = hazards[i]
		hazard.v.y += hazard.gravity * dt
		hazard.p += hazard.v * dt
		hazard.life -= dt
		if hazard.kind == "beam":
			if hazard.life < 0.65 and absf((player.y-40) - hazard.p.y) < 30 and invincible <= 0:
				_take_hit()
		else:
			var distance: float = hazard.p.distance_to(player + Vector2(0,-43))
			if hazard.pink and parry_time > 0 and distance < 90:
				charm = minf(100, charm + 34)
				invincible = maxf(invincible, 0.25)
				_burst(hazard.p, GOLD, 14)
				_impact(hazard.p, "PARRY!")
				face_frame = 2
				face_time = 0.65
				if player.y < floor_y() - 1: velocity.y = -310.0
				_sound("parry")
				hazards.remove_at(i)
				continue
			if distance < 31 and invincible <= 0:
				hazards.remove_at(i)
				_take_hit()
				continue
		if hazard.p.x < -80 or hazard.p.y > floor_y()+120 or hazard.life <= 0:
			hazards.remove_at(i)
	if state == "playing" and resistance <= THRESHOLDS[phase]:
		_open_dialogue()
	_update_hud()

func _sneaking() -> bool:
	return school_duck_latched or _held("sneak") or _held("hide") or Input.is_physical_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)

func _cover_positions() -> Array[float]:
	var w := _stage_width()
	if school.level == School.Level.CLASSROOM:
		var desks: Array[float] = []
		for bench in School.BENCHES:
			desks.append(w*bench)
		return desks
	return [w*0.251,w*0.492,w*0.735]

func _school_cover_radius(index: int) -> float:
	if school.level == School.Level.CLASSROOM:
		return 98.0 if portrait else 74.0
	return SchoolArt.COVER_RADII[index]*(1.0 if portrait else 0.84)

func _update_cover() -> bool:
	var was_hidden := hidden_in_cover
	hidden_in_cover = false
	if school_ducking:
		var cover := _cover_positions()
		for i in cover.size():
			if absf(player.x-cover[i]) <= _school_cover_radius(i):
				hidden_in_cover = true
				break
	return not was_hidden and hidden_in_cover

func _note_position() -> float:
	return _stage_width()*float(School.BENCHES[-1])

func _can_offer_note() -> bool:
	return stage == 0 and state == "playing" and school.level == School.Level.CLASSROOM and school.note_time == 0.0 and school.gaze(elapsed) == School.Gaze.WRITING and absf(player.x-_note_position()) <= 75.0

func _school_interact() -> void:
	if not _can_offer_note(): return
	school.note_time = 0.46
	school_speed = 0.0
	facing = 1.0
	_sound("letter")
	_update_hud()

func _classroom_cue() -> String:
	match school.gaze(elapsed):
		School.Gaze.WRITING: return "REVATHI • WRITING"
		School.Gaze.WATCHING: return "REVATHI • WATCHING"
		_: return "REVATHI • TURNING"

func _tick_classroom(dt: float) -> void:
	if school.note_time > 0.0:
		school.note_time = maxf(0.0,school.note_time-dt)
		if school.note_time == 0.0:
			if school.concern_peak < 35.0 and not school.honor_pass:
				school.honor_pass = true
				_save_progress()
			_end_school("success","note_delivered")
		return
	var entered_cover := _update_cover()
	var watched := school.gaze(elapsed) != School.Gaze.WRITING and not hidden_in_cover
	_update_school_awareness(dt,watched,64.0 if school_ducking else 92.0,entered_cover)
	if awareness >= 100.0:
		_end_school("failure","caught")
	elif elapsed >= School.TIMES[School.Level.CLASSROOM]:
		_end_school("failure","bell")

func _tick_stealth(dt: float) -> void:
	school_whistle = maxf(0.0,school_whistle-dt)
	school_bell_pulse = maxf(0.0,school_bell_pulse-dt)
	school_breeze = maxf(0.0,school_breeze-dt)
	if not school_breeze_triggered and player.x >= _cover_positions()[0]:
		school_breeze_triggered = true
		school_breeze = 3.4
	if not school_last_bell and elapsed >= School.TIMES[School.Level.CORRIDOR]-7.0:
		school_last_bell = true
		school_bell_pulse = 1.5
		_sound("bell")

	var entered_cover := _update_cover()
	if master_turn > 0.0:
		master_turn = maxf(0.0,master_turn-dt)
		if master_turn <= 0.60: master_facing = school.turn_face
	else:
		var bounds_left := _stage_width()*0.40
		var bounds_right := _stage_width()-190.0
		var previous_master_x := master_x
		master_x = clampf(master_x+master_facing*78.0*dt,bounds_left,bounds_right)
		if master_x >= bounds_right or master_x <= bounds_left:
			school.turn_face = -master_facing
			master_turn = 3.2 if school.supervised else 1.2
			school_whistle = 0.55
			if absf(player.x-master_x) < viewport_size.x: _sound("whistle")
		master_stride += absf(master_x-previous_master_x)
	var distance := player.x-master_x
	var seen := master_turn <= 1.2 and not hidden_in_cover and (absf(distance)<48.0 or (distance*master_facing>0.0 and absf(distance)<250.0))
	_update_school_awareness(dt,seen,22.0 if school_ducking else 62.0,entered_cover)
	if awareness >= 100.0:
		_end_school("failure","caught")
	elif player.x >= _stage_width()-76 and awareness < 70.0:
		_end_school("success","reached")
	elif elapsed >= School.TIMES[School.Level.CORRIDOR]:
		_end_school("failure","bell")

func _update_school_awareness(dt: float, seen: bool, rate: float, entered_cover: bool) -> void:
	var previous := awareness
	if school.honor_pass: rate *= 0.75
	awareness = clampf(awareness+(rate if seen else -45.0)*dt,0.0,100.0)
	school.concern_peak = maxf(school.concern_peak,awareness)
	_update_school_mood(dt,previous,entered_cover)

func _tick_walk_home(dt: float, old_x: float) -> void:
	school.stumble = maxf(0.0,school.stumble-dt)
	if school.stumble > 0.0: return
	for i in School.CROSSINGS.size():
		var crossing := _stage_width()*float(School.CROSSINGS[i])
		var progress := School.bike_progress(i,elapsed)
		if progress < 0.22 or progress > 0.80: continue
		if maxf(player.x,old_x)<crossing-42.0 or minf(player.x,old_x)>crossing+42.0: continue
		school.stumble = 0.62
		school.stumble_face = facing
		school_speed = 0.0
		player.x = crossing-73.0 if old_x <= crossing else crossing+73.0
		notice = "Whoa! Wait for the bicycle."
		notice_time = 1.25
		_impact(player+Vector2(0,-115),"WHOA!")
		_sound("parry")
		return
	if player.x >= _stage_width()*School.BUS_STOP-45.0:
		_end_school("success","bus_stop")

func _update_school_mood(dt: float, previous_awareness: float, entered_cover: bool) -> void:
	school_relief = maxf(0.0,school_relief-dt)
	if entered_cover and (previous_awareness >= 35.0 or school_mood in [SchoolMotion.Mood.WORRIED,SchoolMotion.Mood.ALARMED]):
		school_relief = SchoolMotion.RELIEF_SECONDS
	if not hidden_in_cover:
		school_relief = 0.0
	school_mood = SchoolMotion.mood_after(awareness,school_mood,school_relief)

func _end_school(outcome: String, reason: String) -> void:
	if stage != 0 or state != "playing" or not school.outcome.is_empty(): return
	school.outcome = outcome
	school.reason = reason
	school_resolution = ""
	if reason == "caught":
		school.meeting_pending = true
		school.meeting_resolution = ""
		_save_progress()
	camera_x = clampf(camera_x,0.0,_stage_width()-viewport_size.x)
	_clear_input()
	_sound("win" if outcome == "success" else "hit")
	_show_school_result()

func _show_school_result() -> void:
	state = "school_result"
	var col := _modal(850)
	if school.reason == "bell":
		_label(col,"THE BELL RANG",16,GOLD)
		_label(col,"Class is starting",34)
		_label(col,"Try again and watch for a safe opening.",22)
		_button(col,"Retry scene",_resolve_school.bind("retry"),true).grab_focus()
		_button(col,"School scenes",_show_school_map)
		return

	var header := _row(col)
	_add_school_portrait(header)
	_label(header,school.actor().to_upper(),16,GOLD)
	var titles := {"reached":"You slipped past","note_delivered":"The note made it","bus_stop":"At the bus stop","caught":"Parent–teacher meeting"}
	_label(col,titles.get(school.reason,"School debrief"),32)
	_label(col,school.opening(),21)

	if not school_resolution.is_empty():
		if not response.is_empty(): _label(col,response,19)
		if school_resolution == "conditional":
			_label(col,"Supervised retry earned • More time to move",18,GOLD)
		elif school_resolution == "retry":
			_label(col,"Try the scene again at normal difficulty.",18,GOLD)
		var label := "Continue" if school_resolution == "pass" else "Start supervised retry" if school_resolution == "conditional" else "Retry scene"
		_button(col,label,_resolve_school.bind(school_resolution),true).grab_focus()
		return

	if school.meeting_pending:
		_label(col,"Explain what happened and how you’ll put it right.  •  %d / 4 turns" % school.turns,16,Color("b9d0ba"))
	elif school.reason == "note_delivered" and school.honor_pass:
		_label(col,"Honor Pass • Slower detection",16,GOLD)
	if not chat_error.is_empty(): _label(col,chat_error,16,GOLD)
	var talk := _button(col,"Type a reply · Qwen",_open_school_chat,true)
	talk.disabled = school.turns >= school.turn_limit()
	if school.level == School.Level.WALK_HOME:
		_school_written_button(col,"Do you have a minute?",_finish_home.bind("talk"))
		_school_written_button(col,"Read it when you’re ready.",_finish_home.bind("later"))
		_school_written_button(col,"Friends first sounds good.",_finish_home.bind("friends"))
	else:
		_school_written_button(col,school.written_reply(),_school_choice.bind(not school.meeting_pending))
		_button(col,"Retry scene",_resolve_school.bind("retry"))
	_button(col,"School scenes",_show_school_map)

func _add_school_portrait(parent: Control) -> void:
	if school.level == School.Level.CORRIDOR:
		_school_portrait(parent,SchoolArt.MASTER,SchoolArt.MASTER_FRAMES[5])
	elif school.level == School.Level.CLASSROOM:
		_school_portrait(parent,SchoolScenes.CAST,SchoolScenes.CAST_FRAMES[2])
	else:
		_school_portrait(parent,SchoolScenes.CAST,SchoolScenes.CAST_FRAMES[4])
	if school.meeting_pending:
		_school_portrait(parent,SchoolScenes.CAST,SchoolScenes.CAST_FRAMES[5])

func _school_portrait(parent: Control, texture: Texture2D, pose: Rect2) -> void:
	var portrait_art := TextureRect.new()
	var face := AtlasTexture.new()
	face.atlas = texture
	face.region = Rect2(pose.position+Vector2(pose.size.x*0.12,0.0),Vector2(pose.size.x*0.76,pose.size.y*0.40))
	portrait_art.texture = face
	portrait_art.custom_minimum_size = Vector2.ONE*54.0*ui_scale
	portrait_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(portrait_art)

func _school_written_button(parent: Control, line: String, callback: Callable) -> void:
	var choice := _button(parent,line,callback)
	choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _school_choice(success: bool) -> void:
	if state != "school_result" or not school_resolution.is_empty(): return
	response = ""
	school_resolution = "pass" if success else "conditional"
	_remember_school_decision()
	_show_school_result()

func _remember_school_decision() -> void:
	if school.meeting_pending:
		school.meeting_resolution = school_resolution
		_save_progress()

func _finish_home(ending: String) -> void:
	if state != "school_result" or school.level != School.Level.WALK_HOME: return
	school.ending = ending
	_resolve_school("pass")

func _open_school_chat() -> void:
	if state != "school_result": return
	qwen.cancel()
	state = "dialogue"
	dialogue_id += 1
	chat_error = ""
	chat_pending = false
	chat_draft = ""
	if not school_has_spoken:
		chat_messages.assign([{"role":"assistant","content":school.opening()}])
		school_has_spoken = true
	if not OS.has_feature("web") and (qwen.endpoint.is_empty() or qwen.access_code.is_empty()):
		_school_chat_fallback()
		return
	_show_dialogue()
	if not OS.has_feature("web"): qwen.check_connection()

func _school_chat_fallback() -> void:
	qwen.cancel()
	chat_pending = false
	chat_error = "Use the written response below, or connect Qwen to type freely."
	_show_school_result()

func _resolve_school(decision: String) -> void:
	if state != "school_result": return
	var was_meeting := school.meeting_pending
	school.meeting_pending = false
	school.meeting_resolution = ""
	match decision:
		"retry":
			if was_meeting or school.reason == "bell": school.supervised = false
			_save_progress()
			_start_stage()
		"conditional":
			school.supervised = true
			_save_progress()
			_show_intro()
		"pass":
			school.supervised = false
			if school.level == School.Level.WALK_HOME:
				unlocked = maxi(unlocked,1)
				_save_progress()
				_show_school_ending()
			else:
				school.level += 1
				school.checkpoint = school.level
				school.unlocked = maxi(school.unlocked,school.level)
				_save_progress()
				_show_intro()

func _show_school_ending() -> void:
	state = "school_ending"
	var col := _modal()
	_label(col,"AFTER SCHOOL",16,GOLD)
	_label(col,"At the bus stop",38)
	_school_portrait(col,SchoolScenes.CAST,SchoolScenes.CAST_FRAMES[4])
	_label(col,School.HOME_LINES[school.ending],23)
	_label(col,"The bus pulls away. Murugan pockets the loose page and heads home.",20)
	_button(col,"Continue to college",_select_act.bind(1),true)
	_button(col,"All chapters",_show_map)

func _fire() -> void:
	if stage == 0 or state != "playing": return
	shot_clock = 0.34
	attack_pose = 0.18
	var origin := player + Vector2(65*facing,-108)
	var aim := Vector2(facing,0)
	# W/S or arrow keys allow 8-direction manual aiming while firing.
	var up := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var down := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	if up: aim.y -= 1
	if down: aim.y += 1
	shots.append({"p": origin, "v": aim.normalized()*660})
	if shots.size()%3 == 1: _sound("letter")

func _spawn_pattern() -> void:
	hazard_count += 1
	var origin := boss_position() + Vector2(-42,-57)
	var speed := (220.0 + stage * 18 + phase * 22) * attack_speed * (0.85 if gentle else 1.0)
	if hazard_count % 4 == 0:
		_hazard(origin, Vector2(-speed*0.72,0), "petal", true)
		return
	match stage:
		0:
			_hazard(origin, Vector2(-speed,0), "chalk")
			if phase > 0: _hazard(origin+Vector2(0,-70), Vector2(-speed,0), "chalk")
		1:
			_hazard(origin, Vector2(-speed,-260), "samosa", false, 470)
			if phase > 0: _hazard(origin, Vector2(-speed*1.1,0), "paper")
		2:
			if hazard_count % 3 == 0:
				var beam_y := floor_y()-48 if hazard_count % 2 == 0 else floor_y()-133
				_hazard(Vector2(viewport_size.x/2,beam_y), Vector2.ZERO, "beam", false, 0, 1.65)
			else:
				_hazard(origin, Vector2(-speed,0), "ticket")
				if phase > 0: _hazard(origin+Vector2(0,-100), Vector2(-speed,0), "ticket")
		3:
			_hazard(origin+Vector2(0,35), Vector2(-speed*1.1,0), "scroll")
			if phase > 0: _hazard(origin, Vector2(-speed,-220), "coin", false, 380)
		4:
			_hazard(origin, Vector2(-speed,0), "gossip")
			if phase > 0:
				var spawn := Vector2(rng.randf_range(180,viewport_size.x-280), floor_y()-310)
				_hazard(spawn, Vector2(-40,75), "paper", false, 100)

func _hazard(pos: Vector2, motion: Vector2, kind: String, pink: bool=false, gravity: float=0, life: float=8) -> void:
	hazards.append({"p":pos,"v":motion,"kind":kind,"pink":pink,"gravity":gravity,"life":life})

func _jump() -> void:
	if stage != 0 and state == "playing" and player.y >= floor_y()-1:
		velocity.y = -555
		_burst(player, Color("d5c8a8"), 6)

func _dash() -> void:
	if state == "playing" and dash_cooldown <= 0 and (stage != 0 or school.level == School.Level.CORRIDOR):
		dash_time = 0.17 if stage==0 else 0.22
		dash_cooldown = 0.55 if stage == 1 and activity_claimed else 1.0
		invincible = maxf(invincible, 0.26)
		_sound("letter")

func _parry() -> void:
	if stage != 0 and state == "playing" and parry_cooldown <= 0:
		parry_time = 0.24
		parry_cooldown = 0.5

func _heal() -> void:
	if stage != 0 and state == "playing" and not used_tiffin and hp < max_hp:
		hp = mini(max_hp, hp+2)
		used_tiffin = true
		_burst(player+Vector2(0,-70), TEAL, 20)
		_sound("parry")
		_update_hud()

func _take_hit() -> void:
	if state != "playing" or invincible > 0: return
	hp -= 1
	invincible = 1.35 if gentle else 1.0
	shake = 5 if not reduce_motion else 0
	flashes = 0.18
	face_frame = 1
	face_time = 0.7
	_burst(player+Vector2(0,-40), ROSE, 10)
	_sound("hit")
	if hp <= 0:
		_show_defeat()

func _manual_talk() -> void:
	if stage != 0 and state == "playing" and charm >= 100:
		charm = 0
		resistance = minf(resistance, THRESHOLDS[phase])
		_open_dialogue()

func _open_dialogue() -> void:
	if state != "playing": return
	state = "dialogue"
	dialogue_id += 1
	_clear_input()
	windup = 0
	shots.clear()
	hazards.clear()
	chat_messages.assign(agent_histories.get(_agent_name(), []))
	chat_turns = 0
	phase_gain = 0
	chat_error = ""
	chat_draft = ""
	chat_pending = false
	chat_messages.append({"role":"assistant","content":Story.ACTS[stage].talks[phase].q})
	if not OS.has_feature("web") and (qwen.endpoint.is_empty() or qwen.access_code.is_empty()):
		_skip_dialogue("Qwen is not connected")
		return
	_show_dialogue()
	if not OS.has_feature("web"): qwen.check_connection()

func _agent_name() -> String:
	if stage == 0 and not school.outcome.is_empty(): return school.actor()
	return ["Sundaram", "Sharmila", "Karthik", "Amma & Appa", "Sharmila"][stage]

func _show_dialogue() -> void:
	state = "dialogue"
	if OS.has_feature("web"):
		_clear_screen()
		var payload := {"id":dialogue_id,"actor":_agent_name(),"stage":stage,"phase":phase,"approval":approval,"messages":chat_messages,"turns":chat_turns,"hint":Story.ACTS[stage].hint,"chat_only":chat_only}
		if stage == 0 and not school.outcome.is_empty():
			payload["school"] = school.context()
			payload["hint"] = school.opening()
			payload["turn_limit"] = school.turn_limit()
			payload["turns"] = school.turns
		JavaScriptBridge.eval("window.kalyanaChat.open(%s)" % JSON.stringify(payload))
		return
	var col := _modal(960)
	_label(col, "LIVE CHARACTER CHAT  /  QWEN ON YOUR PC", 16, GOLD)
	var live_school := stage == 0 and not school.outcome.is_empty()
	_label(col, _agent_name()+("  •  Turn %d / %d" % [school.turns,school.turn_limit()] if live_school else "  ·  Trust %d / 72" % approval), 30)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 220 * ui_scale
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var messages := VBoxContainer.new()
	messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(messages)
	for message in chat_messages:
		_label(messages,("YOU: " if message.role=="user" else _agent_name().to_upper()+": ")+message.content,22,Color("c6d9c3") if message.role=="user" else PAPER)
	chat_status = _label(col,"Qwen is thinking…" if chat_pending else chat_error,18,GOLD)
	dialogue_input = LineEdit.new()
	dialogue_input.placeholder_text = "Type your reply · Tamil / Tanglish / English"
	dialogue_input.max_length = 500
	dialogue_input.text = chat_draft
	dialogue_input.custom_minimum_size.y = 68 * ui_scale
	dialogue_input.text_changed.connect(func(text: String): chat_draft = text)
	dialogue_input.text_submitted.connect(_submit_text)
	col.add_child(dialogue_input)
	var row := _row(col)
	chat_send = _button(row,"Send to Qwen",_submit_current_text,true)
	chat_send.disabled = chat_pending
	_button(row,"Connect PC",_show_agent_connection)
	chat_back = _button(col,"Use written response" if live_school else ("Back to title  >" if chat_only else "Back to the scene  >"),_finish_chat)
	chat_back.disabled = not live_school and (chat_pending or (chat_turns==0 and not chat_only))
	if not live_school: _button(col, "Skip conversation · keep playing", _skip_dialogue)
	_label(col,"Replies are generated by your PC's Qwen model. No preset reply choices.",16,Color("afc4b2"))
	scroll.set_deferred("scroll_vertical",100000)

func _submit_current_text() -> void:
	if is_instance_valid(dialogue_input): _submit_text(dialogue_input.text)

func _submit_text(text: String) -> void:
	if state != "dialogue" or chat_pending: return
	var clean := text.strip_edges()
	if clean.length()<2:
		chat_error="Write a message before sending."
		_show_dialogue()
		return
	chat_draft = clean
	chat_error = ""
	chat_pending = true
	_show_dialogue()
	var context := school.context() if stage == 0 and not school.outcome.is_empty() else {}
	qwen.send_message(clean,stage,phase,approval,chat_messages,context)

func _agent_failed(message: String) -> void:
	chat_pending=false
	if state=="dialogue": _skip_dialogue(message)

func _apply_agent_reply(data: Dictionary) -> void:
	if state != "dialogue": return
	if stage == 0 and not school.outcome.is_empty():
		_apply_school_reply(data)
		return
	chat_pending=false
	if not chat_draft.is_empty():
		chat_messages.append({"role":"user","content":chat_draft})
	chat_messages.append({"role":"assistant","content":str(data.get("reply",""))})
	chat_messages = chat_messages.slice(-12)
	agent_histories[_agent_name()] = chat_messages.duplicate(true)
	chat_draft=""
	chat_turns+=1
	var amount := clampi(int(data.get("approval_delta",0)),-15,30)
	last_score = mini(amount,maxi(0,36-phase_gain)) if amount>0 else amount
	phase_gain+=maxi(last_score,0)
	approval=clampi(approval+last_score,0,100)
	response=str(data.get("reply",""))
	var pattern: String=str(data.get("attack_pattern","normal"))
	attack_speed=0.88 if pattern=="calmer" else (1.13 if pattern=="faster" else 1.0)
	_sound("parry" if last_score>0 else "hit")
	if not OS.has_feature("web"): _show_dialogue()

func _apply_school_reply(data: Dictionary) -> void:
	if not school_resolution.is_empty(): return
	chat_pending = false
	var addressed = data.get("addressed",null)
	if not addressed is Array or data.get("school_protocol") != 3:
		_skip_dialogue("This Qwen server needs the school update.")
		return
	if not chat_draft.is_empty(): chat_messages.append({"role":"user","content":chat_draft})
	response = str(data.get("reply",""))
	chat_messages.append({"role":"assistant","content":response})
	chat_draft = ""
	if school.level == School.Level.WALK_HOME:
		var ending: String = str(data.get("ending",""))
		if not School.HOME_LINES.has(ending):
			_skip_dialogue("Qwen returned an incomplete ending.")
			return
		school.ending = ending
	school_resolution = school.accept_reply(addressed)
	_remember_school_decision()
	if not school_resolution.is_empty():
		if OS.has_feature("web"): JavaScriptBridge.eval("window.kalyanaChat.hide()")
		_show_school_result()
	elif not OS.has_feature("web"):
		_show_dialogue()

func _skip_dialogue(reason: String = "Conversation skipped") -> void:
	if state != "dialogue": return
	qwen.cancel()
	chat_pending = false
	if OS.has_feature("web"): JavaScriptBridge.eval("window.kalyanaChat.hide()")
	if stage == 0 and not school.outcome.is_empty():
		_school_chat_fallback()
		return
	if chat_only:
		chat_only = false
		if reason != "Conversation skipped": title_chat_notice = "Qwen is offline. Pair your PC in Settings or choose an act to play."
		_show_title()
		return
	offline_run = true
	notice = "Conversation skipped · continue the story"
	notice_time = 4.0
	_continue_after_reply()

func _finish_chat() -> void:
	if stage == 0 and not school.outcome.is_empty():
		_skip_dialogue()
		return
	if state != "dialogue" or chat_pending or (chat_turns==0 and not chat_only):return
	qwen.cancel()
	if OS.has_feature("web"):JavaScriptBridge.eval("window.kalyanaChat.hide()")
	if chat_only:
		chat_only=false
		_show_title()
	else:
		_continue_after_reply()

func _web_chat_event(args: Array) -> void:
	if args.is_empty():return
	var data = JSON.parse_string(str(args[0]))
	if not data is Dictionary:return
	if state != "dialogue" or int(data.get("id", -1)) != dialogue_id: return
	match str(data.get("kind","")):
		"reply":
			chat_draft=str(data.get("user_text",""))
			_apply_agent_reply(data)
		"continue": _finish_chat()
		"skip": _skip_dialogue(str(data.get("reason", "Conversation skipped")))

func _show_agent_connection() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.kalyanaChat.connect()")
		return
	var col := _modal(900)
	_label(col,"CONNECT QWEN ON YOUR PC",26,GOLD)
	_label(col,"Use the HTTPS relay address and access code from Start-Phone-Chat.ps1. Keep them private.",22)
	var address := LineEdit.new()
	address.placeholder_text="https://your-relay.trycloudflare.com"
	address.text=qwen.endpoint
	address.custom_minimum_size.y=70
	col.add_child(address)
	var code := LineEdit.new()
	code.placeholder_text="Private access code"
	code.secret=true
	code.text=qwen.access_code
	code.custom_minimum_size.y=70
	col.add_child(code)
	_button(col,"Connect and return",func():
		qwen.endpoint=address.text.strip_edges()
		qwen.access_code=code.text.strip_edges()
		if state=="dialogue":_show_dialogue()
		else:_show_settings(),true)
	_label(col,"The PC must stay on with Ollama and the relay running. The code stays in this session.",18)

func _continue_after_reply() -> void:
	if phase == 2 and (approval >= 72 or offline_run):
		_clear_stage()
		return
	if phase < 2:
		phase += 1
	else:
		# A missed conversation is recoverable; no softlock at zero resistance.
		resistance = 30
	state = "playing"
	invincible = 1.5
	hazard_clock = 2.4
	windup = 0
	_clear_input()
	shots.clear()
	hazards.clear()
	_make_hud()

func _clear_stage() -> void:
	if stage < 4: unlocked = maxi(unlocked,stage+1)
	else: completed = true
	_save_progress()
	_sound("win")
	_burst(boss_position()+Vector2(-30,-90), GOLD, 60)
	_show_clear()

func _show_clear() -> void:
	state = "clear"
	var col := _modal()
	_label(col, "ACT %02d  /  THAT'S A WRAP!" % (stage+1), 18, GOLD)
	_label(col, "The note made it!\nA perfect little escape." if stage == 0 else "A little less drama.\nA little more trust.", 38)
	_label(col, Story.ACTS[stage].ending, 24)
	if offline_run: _label(col, "CONVERSATIONS SKIPPED · NO QWEN TRUST AWARDED", 17, GOLD)
	_label(col, "TRUST %d  ·  %d HEARTS LEFT  ·  %ds  ·  PROGRESS SAVED" % [approval,hp,int(elapsed)], 17, Color("b6cbb6"))
	_button(col, "The next reel  >" if stage < 4 else "Exchange the garlands  >", _next_stage, true).grab_focus()
	_button(col, "All acts", _show_map)

func _next_stage() -> void:
	if stage < 4:
		stage += 1
		_show_intro()
	else: _show_credits()

func _show_credits() -> void:
	state = "credits"
	var col := _modal()
	_label(col, "SUBHAM  /  THE BEGINNING", 18, GOLD)
	_label(col, "Love is a team sport.", 43)
	_label(col, "From the school corridor to the wedding stage,\nMurugan and Sharmila learned to listen.\nNow the real life quest begins.", 27)
	_label(col, "Original procedural artwork, animation and music.\nInspired by your Kalyana Kathal game design document.\nQwen character chat on your PC. No voice recording or analytics.", 19, Color("b6cbb6"))
	_button(col, "Watch the reels again  >", _show_map, true)
	_button(col, "Title screen", _show_title)

func _show_defeat() -> void:
	state = "defeat"
	var col := _modal()
	_label(col, "CUT!  /  ONE MORE TAKE", 18, GOLD)
	_label(col, "Even heroes need a retake.", 38)
	_label(col, "Wait for Sundaram to look away. Hold HIDE behind carts.\nHis gold cone shows where he can see; the meter warns before capture." if stage == 0 else "Watch for the windup. Jump over low projectiles; dash through danger.\nParry pink petals. Your tiffin restores two hearts once per act.", 24)
	_button(col, "Retake this act  >", _start_stage, true).grab_focus()
	_button(col, "Choose an act", _show_map)
	_button(col, "Settings", _open_settings)

func _pause() -> void:
	if state == "playing": _show_pause()

func _show_pause() -> void:
	state = "paused"
	var col := _modal(700)
	_label(col, "INTERMISSION", 18, GOLD)
	_label(col, "Your story can wait.", 40)
	_button(col, "Back to the scene  >", _resume, true).grab_focus()
	_button(col, "Settings", _open_settings)
	_button(col, "How to play", _show_help)
	_button(col, "Leave act · all acts", _show_map)

func _resume() -> void:
	state = "playing"
	_clear_input()
	_make_hud()

func _open_settings() -> void:
	previous_state = state
	_show_settings()

func _show_settings() -> void:
	state = "settings"
	var col := _modal()
	_label(col, "THE PROJECTION ROOM", 18, GOLD)
	_label(col, "Make yourself comfortable.", 36)
	_toggle(col,"Gentle · more hearts, slower hazards",gentle,_set_gentle)
	_label(col,"Difficulty applies when you start or retry an act.",18,Color("b6cbb6"))
	_toggle(col,"Auto letters · focus on dodging",auto_fire,_set_auto)
	_toggle(col,"Music and sound effects",sound_on,_set_sound)
	_toggle(col,"Reduced motion · no shake or film flicker",reduce_motion,_set_motion)
	_button(col,"Connect Qwen on my PC",_show_agent_connection)
	_label(col,"Progress and settings save locally in this browser.\nQwen chat uses your PC. No microphone is used.",21)
	_button(col,"Done  >",_settings_back,true)

func _toggle(parent: Node, text: String, value: bool, callback: Callable) -> void:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = value
	check.custom_minimum_size.y = 68 * ui_scale
	check.add_theme_font_size_override("font_size", int(23 * ui_scale))
	check.toggled.connect(callback)
	parent.add_child(check)

func _set_gentle(value: bool) -> void:
	gentle = value
	_save_progress()

func _set_auto(value: bool) -> void:
	auto_fire = value
	_save_progress()

func _set_sound(value: bool) -> void:
	sound_on = value
	if not sound_on: music.stop()
	elif not music.playing: music.play()
	_save_progress()

func _set_motion(value: bool) -> void:
	reduce_motion = value
	_save_progress()

func _settings_back() -> void:
	if previous_state == "paused": _show_pause()
	elif previous_state == "defeat": _show_defeat()
	else: _show_title()

func _show_help() -> void:
	var from_pause := state == "paused" or (state == "help" and previous_state == "paused")
	previous_state = "paused" if from_pause else "title"
	state = "help"
	var col := _modal(900)
	_label(col,"THE HERO'S HANDBOOK",18,GOLD)
	_label(col,"A little action. A lot of heart.",36)
	_label(col,"TOUCH  ·  Hold arrows to move. Tap JUMP, DASH or PARRY.\nHold LETTER to throw; auto letters are optional in Settings. Multiple fingers work together.",23)
	_label(col,"KEYBOARD  ·  A/D or Left/Right move · SPACE jump · SHIFT dash\nJ/X fire · W/S or Up/Down aim · K parry · H heal · R speak\nESC/P pause · Type freely to talk to the Qwen character",21)
	_label(col,"SCHOOL: tap DUCK to switch stance, or hold S on a keyboard. Crouch behind furniture to hide. Use Offer Note or E at the front bench.\nOTHER ACTS: lower the shield to talk. Offline Qwen? Skip and play on.\nAt a marked stop, use the nearby button or press E.",23)
	_label(col,"A short dash makes you invincible. A tiffin heals once per act.\nOn a phone, landscape gives you more room to dodge.",21,Color("b9cbb6"))
	_button(col,"Got it  >",_settings_back,true).grab_focus()

func _lost_focus() -> void:
	_clear_input()
	if state == "playing": _show_pause()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_lost_focus()

func _clear_input() -> void:
	held.clear()
	pointer_actions.clear()
	school_move_touches.clear()
	school_speed = 0.0

func _held(action: String) -> bool:
	return action in pointer_actions.values() or bool(held.get(action,false))

func _input(event: InputEvent) -> void:
	if stage == 0 and state == "playing" and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		_school_touch(event)
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var id: int = event.index
		if event is InputEventScreenTouch and not event.pressed:
			pointer_actions.erase(id)
			return
		if state != "playing": return
		var action := _control_at(event.position)
		pointer_actions[id] = action
		if event is InputEventScreenTouch and event.pressed: _action(action)
		if action != "": get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Emulated mouse still reaches UI buttons, but cannot toggle a canvas control twice.
		if stage==0 and event.device==-1: return
		if not event.pressed:
			pointer_actions.erase(-1)
		elif state == "playing":
			var action := _control_at(event.position)
			pointer_actions[-1] = action
			_action(action)
			if action != "": get_viewport().set_input_as_handled()

func _school_touch(event: InputEvent) -> void:
	var id: int = event.index
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			school_move_touches.erase(id)
			pointer_actions.erase(id)
			return
		var action := _control_at(event.position)
		if action.is_empty(): return
		pointer_actions[id] = action
		if action in ["left","right"]:
			school_move_touches[id] = true
		else:
			_action(action)
		get_viewport().set_input_as_handled()
	elif school_move_touches.has(id):
		var pad: Rect2 = control_rects["left"].merge(control_rects["right"])
		# Catch small thumb drift and allow reversing by sliding across the pad.
		pointer_actions[id] = ""
		if pad.grow(24.0).has_point(event.position):
			pointer_actions[id] = "left" if event.position.x < pad.get_center().x else "right"
		get_viewport().set_input_as_handled()
	elif pointer_actions.has(id):
		get_viewport().set_input_as_handled()

func _control_at(point: Vector2) -> String:
	for key in control_rects:
		if control_rects[key].has_point(point): return key
	return ""

func _action(action: String) -> void:
	match action:
		"fire":
			if shot_clock <= 0: _fire()
		"jump": _jump()
		"dash": _dash()
		"parry": _parry()
		"sneak":
			if stage==0: school_duck_latched = not school_duck_latched

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		if state == "playing": _pause()
		elif state == "paused": _resume()
		elif state == "dialogue" and stage == 0: _skip_dialogue()
		elif state == "dialogue": pass
		elif state == "settings" or state == "help": _settings_back()
		else: _show_title()
		get_viewport().set_input_as_handled()
		return
	if state == "playing":
		match event.keycode:
			KEY_SPACE: _jump()
			KEY_J, KEY_X: _action("fire")
			KEY_SHIFT: _dash()
			KEY_K: _parry()
			KEY_E:
				if stage == 0: _school_interact()
				else: _use_activity()
			KEY_H: _heal()
			KEY_R: _manual_talk()

func _burst(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		if particles.size() >= 180: return
		particles.append({"p":pos,"v":Vector2(rng.randf_range(-130,130),rng.randf_range(-180,30)),"life":rng.randf_range(0.3,0.8),"color":color})

func _update_particles(dt: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		particles[i].p += particles[i].v * dt
		particles[i].v.y += 230 * dt
		particles[i].life -= dt
		if particles[i].life <= 0: particles.remove_at(i)

func _impact(pos: Vector2, caption: String) -> void:
	impact_position = pos
	impact_text = caption
	impact_time = 0.30

func _draw_impact(offset: Vector2) -> void:
	var progress := 1.0-impact_time/0.30
	var center := impact_position + offset + Vector2(-48,-35)
	center.x = clampf(center.x, 74, viewport_size.x-74)
	var stretch := 1.0 if reduce_motion else lerpf(0.78,1.13,minf(progress*4.0,1.0))
	var shape: Array[Vector2] = []
	for i in range(24):
		var angle := TAU*i/24.0
		var radius := 1.15 if i%2==0 else 0.74
		shape.append(center+Vector2(cos(angle)*64,sin(angle)*37)*radius*stretch)
	_polygon(shape,Color("ffca76") if impact_text=="POW!" else Color("ff98ba"))
	var label_size := 31 if impact_text=="POW!" else 24
	_text(impact_text,center+Vector2(0,10),label_size,INK,true)

func _draw_reaction(target: Vector2, frame: int, side: float, accent: Color) -> void:
	var radius := 48.0 if portrait else 35.0
	var center := target + Vector2(side*radius*1.38, -(246.0 if portrait else 166.0))
	center.x = clampf(center.x,radius+6.0,viewport_size.x-radius-6.0)
	var point := Vector2(target.x,target.y-(208.0 if portrait else 144.0))
	_polygon([point,center+Vector2(-19,19),center+Vector2(19,19)],PAPER)
	draw_circle(center,radius+3,INK,true)
	draw_circle(center,radius,PAPER,true)
	draw_arc(center,radius-3,0,TAU,32,accent,2,true)
	var cell := REACTION_FACES.get_size()/2.0
	var origin := Vector2(frame%2,frame/2)*cell+Vector2(3,3)
	var face_region := Rect2(origin,cell-Vector2(6,6))
	var face_size := Vector2.ONE*radius*1.54
	draw_texture_rect_region(REACTION_FACES,Rect2(center-face_size/2,face_size),face_region)

func _draw() -> void:
	if font == null: return
	var wobble := Vector2(sin(age*78)*shake,cos(age*69)*shake) if not reduce_motion else Vector2.ZERO
	draw_set_transform(wobble)
	_background()
	var world_offset := wobble - Vector2(camera_x,0)
	draw_set_transform(world_offset)
	if stage == 0 and state in ["playing","paused","school_result","school_ending"]:
		match school.level:
			School.Level.CORRIDOR: _draw_stealth_scene()
			School.Level.CLASSROOM: _draw_classroom()
			School.Level.WALK_HOME: _draw_walk_home()
	draw_set_transform(Vector2.ZERO)
	if state != "title":
		var animate := state == "playing" and (_held("left") or _held("right") or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT))
		var actor_scale := 1.55 if portrait else 1.0
		_character(player+world_offset,"hero",actor_scale,animate)
		var kind: String = ["teacher","senior","manager","father","aunty"][stage]
		if stage != 0 or school.level == School.Level.CORRIDOR:
			_character(boss_position()+world_offset,kind,actor_scale,stage == 0 and state == "playing" and master_turn <= 0)
		if stage == 3: _character(boss_position()+world_offset+Vector2(87,0),"aunty",actor_scale*0.85,false)
		if stage == 1 or stage == 4:
			_character(boss_position()+world_offset+Vector2(94,0),"sharmila",actor_scale*0.85,false)
	draw_set_transform(world_offset)
	if stage == 0 and school.level != School.Level.WALK_HOME and state in ["playing","paused","school_result"]:
		_draw_cover_props()
		if school.note_time > 0.0:
			var t := 1.0-school.note_time/0.46
			var origin := player+Vector2(34,-105)
			var to := _sharmila_desk()-Vector2(0,155)
			_envelope(origin.lerp(to,t)-Vector2(0,sin(t*PI)*42.0),GOLD,0.78)
	if state == "playing" and ACTIVITIES.has(stage): _draw_activity()
	if windup > 0 and state == "playing":
		var cue := boss_position()+Vector2(0,-205* (1.3 if portrait else 1.0))
		draw_circle(cue,24,GOLD)
		_text("!",cue+Vector2(0,9),30,INK,true)
	for shot in shots: _envelope(shot.p,ROSE,1)
	for hazard in hazards: _draw_hazard(hazard)
	if parry_time > 0 and state == "playing":
		draw_arc(player+Vector2(0,-43),77,0,TAU,32,GOLD,5,true)
		_heart(player+Vector2(0,-100),12,ROSE)
	for particle in particles:
		var color: Color = particle.color
		color.a = minf(1,particle.life*2)
		draw_rect(Rect2(particle.p,Vector2(5,5)),color)
	draw_set_transform(Vector2.ZERO)
	if state == "playing":
		if impact_time > 0: _draw_impact(world_offset)
		if stage == 0 and school.level == School.Level.CORRIDOR:
			var cue := boss_position()+world_offset+Vector2(0,-_school_actor_height(false)-27)
			var word := ""
			if awareness>=52: word = "!"
			elif master_turn>1.2: word = "WAITING"
			elif master_turn>0: word = "TURNING"
			if not word.is_empty():
				var badge_size := Vector2(45,38) if word=="!" else Vector2(139,38)
				draw_style_box(_style(INK,ROSE if word=="!" else GOLD,10),Rect2(cue-badge_size*0.5,badge_size))
				_text(word,cue+Vector2(0,6),18,PAPER,true)
		elif face_time > 0:
			_draw_reaction(player+world_offset,face_frame,-facing,ROSE if face_frame!=2 else GOLD)
	# Film perforations and subtle texture make the world feel like a printed reel.
	for x in range(10,int(viewport_size.x),36):
		draw_rect(Rect2(x,4,17,7),Color(0.06,0.12,0.10,0.65))
	if not reduce_motion:
		for i in range(38):
			var x := fmod(float(i*139+17),viewport_size.x)
			var y := fmod(float(i*71)+age*5,viewport_size.y)
			draw_line(Vector2(x,y),Vector2(x+2,y+3),Color(0.2,0.18,0.12,0.07),1)
	draw_set_transform(Vector2.ZERO)
	if state == "playing":
		_draw_controls()
		if flashes > 0: draw_rect(Rect2(Vector2.ZERO,viewport_size),Color(0.8,0.15,0.18,flashes*0.3))

func _background() -> void:
	var w := viewport_size.x
	var h := viewport_size.y
	if state == "title":
		var size := COVER.get_size()
		var scale_value := maxf(w/size.x,h/size.y)
		var image_size := size*scale_value
		var x := (w-image_size.x)*(0.80 if portrait else 0.5)
		draw_texture_rect(COVER,Rect2(Vector2(x,(h-image_size.y)/2),image_size),false)
		# The painting provides the scene; a gentle ink glaze gives menu text contrast.
		draw_rect(Rect2(0,0,w,h),Color(0.015,0.065,0.055,0.12))
		return
	var new_school_scene := stage == 0 and school.level != School.Level.CORRIDOR
	var texture: Texture2D = SchoolScenes.background(school.level) if new_school_scene else SCENERY[stage]
	var size := texture.get_size()
	var g := floor_y()
	# Scenery travels more slowly than carts, actors and the gate.
	var drift := 0.0 if reduce_motion else 68.0
	var travel := (_stage_width()-w)*0.6 if stage == 0 else drift
	var scale_value := maxf((w+travel)/size.x,(g-230.0)/(size.y*0.82))
	var image_size := size*scale_value
	var x := (w+travel-image_size.x)/2
	if stage == 0:
		x -= camera_x*0.6
	else:
		x -= drift*clampf(player.x/maxf(1.0,w-295.0),0.0,1.0)
	var point := Vector2(x,g-image_size.y*0.82)
	if new_school_scene:
		image_size = size*(_stage_width()/size.x)
		point = Vector2(-camera_x,g-image_size.y*0.80)
	draw_rect(Rect2(0,0,w,h),Color("283f34"))
	draw_texture_rect(texture,Rect2(point,image_size),false)
	if stage==0 and school.level == School.Level.CORRIDOR and state=="playing" and not reduce_motion:
		_draw_school_atmosphere(point,image_size)
	# Atmospheric pools of light and an inked stage apron separate controls from art.
	draw_rect(Rect2(0,h-(190 if portrait else 120),w,200),Color(0.035,0.10,0.085,0.70))
	if not reduce_motion:
		for i in range(12):
			var px := fmod(float(i*179)+age*9,w)
			var py := fmod(float(i*97)+sin(age*.4+i)*12,g)
			draw_circle(Vector2(px,py),1.5,Color(1,0.85,0.5,0.16))
func _draw_school_atmosphere(origin: Vector2, painted: Vector2) -> void:
	var girl_progress := SchoolMotion.student_progress(1,elapsed)
	var boy_progress := SchoolMotion.student_progress(0,elapsed)
	var girl_feet := SchoolMotion.student_feet(1,minf(girl_progress,1.0))
	var boy_feet := SchoolMotion.student_feet(0,minf(boy_progress,1.0))
	if girl_feet.y < boy_feet.y:
		_draw_school_student(1,girl_progress,girl_feet,origin,painted)
		_draw_school_student(0,boy_progress,boy_feet,origin,painted)
	else:
		_draw_school_student(0,boy_progress,boy_feet,origin,painted)
		_draw_school_student(1,girl_progress,girl_feet,origin,painted)
	var bell := origin + painted*Vector2(0.398,0.158)
	if school_bell_pulse>0.0:
		var wave := fposmod(1.5-school_bell_pulse,0.48)/0.48
		for side in [-1,1]:
			var center := bell+Vector2(side*22.0,0)
			var angle := PI if side<0 else 0.0
			draw_arc(center,19.0+wave*29.0,angle-0.63,angle+0.63,16,Color(1,0.88,0.55,(1-wave)*0.65),3.0,true)
	for i in range(8):
		var phase_leaf := fposmod(age*(0.17+i*0.012)+i*0.32,1.0)
		var at := Vector2(fposmod(i*211.0+phase_leaf*290.0-camera_x*0.37,viewport_size.x+90.0)-45.0,
				floor_y()-460.0+phase_leaf*320.0+sin(age*1.8+i)*21.0)
		var tone := Color(0.82,0.75,0.34,0.43) if i%3!=0 else Color(0.83,0.37,0.34,0.49)
		var twist := Vector2(cos(age*2.1+i),sin(age*2.1+i))*7.0
		draw_colored_polygon(PackedVector2Array([at-twist,at+twist.orthogonal()*0.39,at+twist,at-twist.orthogonal()*0.32]),tone)
	if school_breeze>0.0:
		var elapsed_breeze := 3.4-school_breeze
		for i in range(3):
			var t := clampf((elapsed_breeze-i*0.28)/2.8,0.0,1.0)
			if t<=0.0 or t>=1.0: continue
			var at := Vector2(_stage_width()*0.25-camera_x+72.0+t*240.0,floor_y()-155.0-sin(t*PI)*145.0-i*16.0)
			var direction := Vector2.from_angle(t*5.4+i)*13.0
			var edge := direction.orthogonal()*0.60
			draw_colored_polygon(PackedVector2Array([at-direction-edge,at+direction-edge,at+direction+edge,at-direction+edge]),Color(0.98,0.88,0.66,sin(t*PI)*0.72))

func _draw_school_student(index: int, progress: float, feet: Vector2, origin: Vector2, painted: Vector2) -> void:
	if progress >= 1.0: return
	var center := origin+painted*feet
	if center.x < -110.0 or center.x > viewport_size.x+110.0: return
	var alpha := smoothstep(0.025,0.145,progress)*(1.0-smoothstep(0.86,0.975,progress))
	var frame := index*6+int(progress*(7.0 if index==0 else 6.0)*6.0)%6
	var region: Rect2 = SchoolArt.STUDENTS_FRAMES[frame]
	var student_height := _school_actor_height(true)*SchoolMotion.student_scale(feet)
	var size := region.size*(student_height/region.size.y)
	_oval(center+Vector2(0,2),Vector2(student_height*0.16,student_height*0.028),Color(0.14,0.08,0.04,0.24*alpha))
	draw_set_transform(center,0.0,Vector2(1.0 if index==0 else -1.0,1.0))
	var anchor: float = SchoolArt.STUDENT_ANCHORS[frame]
	draw_texture_rect_region(SchoolArt.STUDENTS,Rect2(Vector2(-size.x*anchor,-size.y),size),region,Color(0.93,0.89,0.83,alpha))
	draw_set_transform(Vector2.ZERO)

func _character(pos: Vector2, kind: String, scale_factor: float, walking: bool) -> void:
	if stage == 0 and kind in ["hero","teacher"]:
		_draw_school_actor(pos,kind=="hero")
		return
	var using_run := kind == "hero" and (walking or player.y < floor_y()-1) and attack_pose <= 0
	var tex: Texture2D = (HERO_RUN if using_run else HERO_SHEET) if kind=="hero" else CAST_SHEET
	var grid := Vector2(4,4) if kind=="hero" else Vector2(3,2)
	var cell := tex.get_size()/grid
	var column := 0
	var row := 0
	var flip := false
	var pivot := 0.5
	var motion := Vector2.ONE
	var tilt := 0.0
	var bob := 0.0
	if kind=="hero":
		row = [0,1,2,2,3][stage]
		flip = facing < 0
		if walking:
			column = int(run_cycle)%4 if using_run else 0
			pivot = 0.53
			if not reduce_motion:
				bob = -absf(sin(run_cycle*PI))*3
				tilt = sin(run_cycle*PI)*0.025
		if player.y < floor_y()-1:
			column = 3 if using_run else 2
			pivot = 0.53 if using_run else 0.46
			if not reduce_motion: motion = Vector2(0.94,1.06)
		if attack_pose > 0 and state == "playing":
			column = 3
			pivot = 0.29 # Throw art has an extended arm; anchor the body, not the cell.
			if not reduce_motion: tilt = -facing*0.06*attack_pose/0.18
		if not reduce_motion:
			if dash_time > 0: motion = Vector2(1.17,0.85)
			elif landing_pose > 0: motion = Vector2(1+landing_pose*0.8,1-landing_pose*0.8)
			elif not walking: motion = Vector2(1+sin(age*3)*0.012,1-sin(age*3)*0.012)
			if flashes > 0:
				tilt = -facing*0.12
				motion = Vector2(1.06,0.94)
	else:
		var index: int = {"teacher":0,"senior":1,"manager":2,"father":3,"aunty":4,"sharmila":5}.get(kind,5)
		column = index%3
		row = index/3
		flip = kind in ["teacher","senior","father","aunty"]
		if not reduce_motion:
			motion = Vector2(1+sin(age*3)*0.012,1-sin(age*3)*0.012)
			if walking:
				tilt = sin(age*9)*0.045
				bob = -absf(sin(age*9))*3
			if windup > 0: motion = Vector2(1.08,0.92)
			if boss_flash > 0: tilt = 0.10
	var height := 176.0*scale_factor
	var size := Vector2(cell.x/cell.y*height,height)
	var shadow_scale := clampf(1.0-(floor_y()-pos.y)/400.0,0.3,1.0)
	_oval(Vector2(pos.x,floor_y()+5),Vector2(30*scale_factor*shadow_scale,7*scale_factor),Color(0.015,0.06,0.045,0.25*shadow_scale))
	draw_set_transform(pos+Vector2(0,bob),tilt,Vector2(-motion.x if flip else motion.x,motion.y))
	var tint := Color(1.5,1.4,1.1,1) if boss_flash>0 and kind!="hero" else Color.WHITE
	if kind == "hero" and state == "playing" and invincible > 0:
		tint = Color(0.85,1.0,0.95,0.86)
	# Crop the envelope painted into the throw pose; the live projectile animates it.
	var visible_width := 0.78 if kind == "hero" and not using_run and column == 3 else 1.0
	var destination := Rect2(Vector2(-size.x*pivot,-size.y*0.97),Vector2(size.x*visible_width,size.y))
	var source := Rect2(Vector2(column,row)*cell+Vector2(2,2),Vector2((cell.x-4)*visible_width,cell.y-4))
	if kind == "hero" and dash_time > 0 and not reduce_motion:
		for i in [3,2,1]:
			var trail := destination
			trail.position.x -= 22*i
			draw_texture_rect_region(tex,trail,source,Color(0.65,0.9,0.8,0.11))
	# Inset source cells to prevent neighbouring poses bleeding through the atlas.
	draw_texture_rect_region(tex,destination,source,tint)
	draw_set_transform(Vector2.ZERO)

func _school_actor_height(hero: bool) -> float:
	if portrait: return 350.0 if hero else 376.0
	return 211.0 if hero else 231.0

func _draw_school_actor(pos: Vector2, hero: bool) -> void:
	if hero:
		_draw_school_hero(pos)
		return
	var is_action := state in ["playing","paused"]
	var height := _school_actor_height(false)
	var facing_visual := master_facing
	var squash := Vector2.ONE
	var turning := is_action and master_turn>0
	var turn_progress := 1.0-minf(master_turn,1.2)/1.2
	var speaking := state in ["school_result","dialogue","school_ending"]
	var frame := SchoolArt.master_frame(speaking,school.outcome=="success" or not school_resolution.is_empty(),false,turning,turn_progress,awareness>=65,int(master_stride/11.5))
	if turning:
		facing_visual = -school.turn_face if turn_progress < 0.5 else school.turn_face
		if not reduce_motion: squash.x = 1.0-0.10*sin(clampf(turn_progress,0.0,1.0)*PI)
	if speaking: facing_visual = -1
	height *= float(SchoolArt.MASTER_HEIGHTS[frame])
	if is_action and not reduce_motion and not turning:
		squash.y *= 1.0+0.012*cos(master_stride*0.14)
	var source := SchoolArt.MASTER_FRAMES[frame]
	var size := source.size*(height/source.size.y)
	var dst := Rect2(Vector2(-size.x*float(SchoolArt.MASTER_ANCHORS[frame]),-size.y),size)
	var shade := Vector2(height*0.22,9.0 if portrait else 6.0)
	_oval(pos+Vector2(0,2),shade,Color(0.15,0.08,0.05,0.34))
	draw_set_transform(pos,0.0,Vector2(squash.x*facing_visual,squash.y))
	draw_texture_rect_region(SchoolArt.MASTER,dst,source)
	draw_set_transform(Vector2.ZERO)

func _draw_school_hero(pos: Vector2) -> void:
	var active := state in ["playing","paused"]
	var step := SchoolMotion.step_index(school_step_phase)
	var transition := SchoolMotion.transition_index(school_duck_blend,reduce_motion) if active and dash_time <= 0.0 else -1
	var base_height := _school_actor_height(true)
	var texture := SchoolArt.HERO
	var source := SchoolArt.HERO_FRAMES[0]
	var anchor := 0.53
	var reference_height := source.size.y
	var head := Vector3.ZERO
	var lift := 0.0
	if active and attack_pose > 0.0:
		source = SchoolArt.HERO_FRAMES[7]
		anchor = 0.38
		reference_height = source.size.y/0.64
	elif active and school.note_time > 0.0:
		texture = SchoolArt.REACTIONS
		var reach := 1 if school.note_time > 0.27 else 2
		source = SchoolArt.TRANSITION_FRAMES[reach]
		anchor = SchoolArt.TRANSITION_ANCHORS[reach]
		reference_height = 431.0
	elif active and school.stumble > 0.0:
		texture = SchoolArt.RUN
		source = SchoolArt.RUN_FRAMES[2]
		anchor = SchoolArt.RUN_ANCHORS[2]
		reference_height = 420.0
		if not reduce_motion: lift = sin(school.stumble/0.62*PI)*19.0
	elif transition >= 0:
		texture = SchoolArt.REACTIONS
		source = SchoolArt.TRANSITION_FRAMES[transition]
		anchor = SchoolArt.TRANSITION_ANCHORS[transition]
		reference_height = 431.0
	elif active and school_ducking:
		if school_moving:
			texture = SchoolArt.CROUCH
			source = SchoolArt.CROUCH_FRAMES[step]
			anchor = SchoolArt.CROUCH_ANCHORS[step]
			reference_height = 555.0
			head = SchoolArt.CROUCH_HEADS[step]
		else:
			source = SchoolArt.HERO_FRAMES[4]
			anchor = 0.51
			reference_height = source.size.y/0.64
			head = Vector3(55.0,117.0,124.0)
	elif active and (school_moving or dash_time > 0.0):
		texture = SchoolArt.RUN
		step = 3 if dash_time > 0.0 else step
		source = SchoolArt.RUN_FRAMES[step]
		anchor = SchoolArt.RUN_ANCHORS[step]
		reference_height = 420.0
		if not reduce_motion and step%4 == 3:
			lift = base_height*0.035
	var ratio := base_height/reference_height
	var size := source.size*ratio
	var dest := Vector2(-size.x*anchor,-size.y-lift)
	_oval(pos+Vector2(0,2),Vector2(base_height*0.19,9.0 if portrait else 6.0),Color(0.15,0.08,0.05,0.34))
	var tilt := sin(school.stumble/0.62*PI)*-0.30*school.stumble_face if active and school.stumble > 0.0 and not reduce_motion else 0.0
	draw_set_transform(pos,tilt,Vector2(facing,1.0))
	if head == Vector3.ZERO:
		draw_texture_rect_region(texture,Rect2(dest,size),source)
	else:
		_draw_school_crouch_face(texture,source,dest,ratio,head)
	draw_set_transform(Vector2.ZERO)

func _draw_school_crouch_face(texture: Texture2D, source: Rect2, dest: Vector2, ratio: float, head: Vector3) -> void:
	# Keep the backpack beside the head and the shoulders below the neck.
	# The new head overlaps the collar in each registered pose.
	var body := Rect2(source.position+Vector2(0,head.y),Vector2(source.size.x,source.size.y-head.y))
	var bag := Rect2(source.position,Vector2(head.x,head.y))
	draw_texture_rect_region(texture,Rect2(dest+Vector2(0,head.y*ratio),body.size*ratio),body)
	draw_texture_rect_region(texture,Rect2(dest,bag.size*ratio),bag)
	var face := SchoolArt.HEAD_FRAMES[school_mood]
	var face_size := face.size*(head.z*ratio/face.size.x)
	draw_texture_rect_region(SchoolArt.REACTIONS,Rect2(dest+Vector2(head.x*ratio,0),face_size),face)

func _draw_activity() -> void:
	var base := _activity_position()
	var sign_center := base + Vector2(0,-152 if stage == 0 else -98)
	var sign := Rect2(sign_center-Vector2(73,40),Vector2(146,80))
	draw_style_box(_style(Color("273d3a"),GOLD if not activity_claimed else TEAL,14),sign)
	var mark := sign_center+Vector2(0,-10)
	if activity_claimed:
		draw_polyline(PackedVector2Array([mark+Vector2(-14,0),mark+Vector2(-4,10),mark+Vector2(15,-12)]),GOLD,4,true)
	else:
		match stage:
			0:
				draw_style_box(_style(PAPER,INK,2),Rect2(mark-Vector2(22,15),Vector2(44,31)))
				_text("A+",mark+Vector2(0,9),23,INK,true)
			1:
				draw_line(mark-Vector2(24,0),mark+Vector2(24,0),PAPER,5,true)
				for x in [-19,19]:
					draw_rect(Rect2(mark+Vector2(x-5,-12),Vector2(10,24)),GOLD)
			3:
				for y in [-7,7]:
					draw_arc(mark+Vector2(-10,y),6,0,TAU,16,GOLD,3,true)
					draw_line(mark+Vector2(-6,y),mark+Vector2(17,-y),PAPER,3,true)
	_text(ACTIVITIES[stage].name,sign_center+Vector2(0,27),15,PAPER,true)

func _draw_stealth_scene() -> void:
	var eye := boss_position()+Vector2(0,-_school_actor_height(false)*0.78)
	var view := 250.0
	var color := Color(0.99,0.86,0.48,0.16) if awareness < 60 else Color(0.95,0.24,0.24,0.29)
	var sight_edge := Vector2(eye.x+master_facing*view,floor_y()+1.0)
	if master_turn <= 1.2:
		draw_colored_polygon(PackedVector2Array([eye,eye+Vector2(master_facing*view,-58),sight_edge]),color)
		draw_line(eye,sight_edge,Color(0.96,0.79,0.40,0.55),2.5,true)
	var gate := Vector2(_stage_width()-60,floor_y())
	draw_style_box(_style(Color("224c42"),GOLD,14),Rect2(gate+Vector2(-38,-175),Vector2(76,170)))
	_text("CLASS",gate+Vector2(0,-133),19,PAPER,true)
	var arrow := gate + Vector2(0,-99)
	draw_line(arrow+Vector2(-17,0), arrow+Vector2(17,0), GOLD, 4, true)
	draw_polyline(PackedVector2Array([arrow+Vector2(4,-12), arrow+Vector2(17,0), arrow+Vector2(4,12)]), GOLD, 4, true)
	if hidden_in_cover: _text("HIDDEN",player+Vector2(0,-185),20,GOLD,true)

func _draw_classroom() -> void:
	var w := _stage_width()
	var g := floor_y()
	var background_height := w*SchoolScenes.CLASSROOM.get_height()/SchoolScenes.CLASSROOM.get_width()
	var board := Vector2(w*0.70,g-background_height*0.28)
	_text("x + 2 = 7",board, int(background_height*0.043),Color("dfdfc0"),true)
	_text("x = 5",board+Vector2(w*0.105,background_height*0.048),int(background_height*0.038),Color("dfdfc0"),true)
	var gaze := school.gaze(elapsed)
	var teacher := Vector2(w*School.TEACHER_X,g-(55.0 if portrait else 34.0))
	var frame := SchoolScenes.teacher_frame(gaze)
	_draw_scene_sprite(SchoolScenes.CAST,SchoolScenes.CAST_FRAMES[frame],teacher,_school_actor_height(false)*0.92)
	if gaze == School.Gaze.WRITING and not reduce_motion:
		var chalk := teacher-Vector2(-21,_school_actor_height(false)*0.73)
		for i in range(4):
			var t := fposmod(elapsed*2.4+i*0.24,1.0)
			draw_circle(chalk+Vector2(t*18.0,t*36.0),2.0,Color(1,0.98,0.81,(1.0-t)*0.67))
	var first := _sharmila_desk()
	_draw_scene_sprite(SchoolScenes.CAST,SchoolScenes.CAST_FRAMES[3],first,_school_actor_height(true)*0.69)
	if state == "playing":
		var badge := teacher-Vector2(0,_school_actor_height(false)*0.92+30)
		var cue: String = ["WRITING","TURNING","WATCHING","TURNING"][gaze]
		var trim := GOLD if gaze == School.Gaze.WRITING else ROSE
		draw_style_box(_style(INK,trim,10),Rect2(badge-Vector2(82,18),Vector2(164,36)))
		_text(cue,badge+Vector2(0,6),18,PAPER,true)
		if _can_offer_note(): _envelope(first-Vector2(0,_school_actor_height(true)*0.76),GOLD,0.75)

func _sharmila_desk() -> Vector2:
	return Vector2(_note_position()+(94.0 if portrait else 75.0),floor_y()-15.0)

func _draw_walk_home() -> void:
	var w := _stage_width()
	var g := floor_y()
	var hero_height := _school_actor_height(true)
	var stall := Vector2(w*School.STALL,g-hero_height*0.32)
	_draw_scene_sprite(SchoolScenes.STREET,SchoolScenes.STREET_FRAMES[2],stall,hero_height*0.89)
	if not reduce_motion:
		for i in range(3):
			var t := fposmod(elapsed*0.78+i*0.32,1.0)
			var steam := stall+Vector2(-hero_height*0.22+sin(t*5.0)*11.0,-hero_height*0.53-t*hero_height*0.30)
			draw_circle(steam,4.0+t*12.0,Color(0.97,0.87,0.70,(1.0-t)*0.28))

	for i in School.CROSSINGS.size():
		var crossing := Vector2(w*School.CROSSINGS[i],g)
		var progress := School.bike_progress(i,elapsed)
		var active := progress < 1.0
		var signal_color := GOLD if active else Color("a7d1b2")
		for stripe in range(4):
			var x := -49.0+stripe*24.0
			draw_line(crossing+Vector2(x+11,-31),crossing+Vector2(x-6,16),Color(PAPER,0.52),5,true)
		var marker := crossing-Vector2(0,hero_height*0.81)
		draw_style_box(_style(INK,signal_color,8),Rect2(marker-Vector2(60,17),Vector2(120,32)))
		_text("WAIT" if active else "CROSS",marker+Vector2(0,5),17,signal_color,true)
		if active:
			var bike := crossing+Vector2(lerpf(-205.0,205.0,progress),-13.0)
			var pose := 0 if reduce_motion else int(progress*12.0)%2
			_draw_scene_sprite(SchoolScenes.STREET,SchoolScenes.STREET_FRAMES[pose],bike,hero_height*0.68)

	var stop := Vector2(w*School.BUS_STOP,g-18.0)
	_draw_scene_sprite(SchoolScenes.CAST,SchoolScenes.CAST_FRAMES[4],stop,hero_height*0.91)
	var stop_sign := stop-Vector2(0,hero_height+30)
	draw_style_box(_style(INK,TEAL,9),Rect2(stop_sign-Vector2(70,18),Vector2(140,36)))
	_text("BUS STOP",stop_sign+Vector2(0,5),19,PAPER,true)
	if elapsed < 2.8 and state == "playing":
		var wave := Vector2(w*0.225,g-hero_height*0.23)
		_draw_scene_sprite(SchoolScenes.CAST,SchoolScenes.CAST_FRAMES[4],wave,hero_height*0.65,Color(1,1,1,1.0-smoothstep(1.9,2.8,elapsed)))
		_text("See you at the stop!",wave-Vector2(0,hero_height*0.81),19,PAPER,true)

func _draw_scene_sprite(texture: Texture2D, region: Rect2, feet: Vector2, height: float, tint: Color = Color.WHITE) -> void:
	var size := region.size*(height/region.size.y)
	_oval(feet,Vector2(size.x*0.33,6.0),Color(0.12,0.08,0.04,0.31*tint.a))
	draw_texture_rect_region(texture,Rect2(feet-Vector2(size.x*0.5,size.y),size),region,tint)

func _draw_school_prop(base: Vector2, index: int, width: float, tint: Color) -> void:
	var region: Rect2 = SchoolArt.PROPS_FRAMES[index]
	var size := Vector2(width,width * region.size.y/region.size.x)
	_oval(base+Vector2(0,3),Vector2(width*0.48,11),Color(0.18,0.10,0.06,0.33))
	draw_texture_rect_region(SchoolArt.PROPS,Rect2(base-Vector2(size.x*0.5,size.y),size),region,tint)

func _draw_cover_props() -> void:
	var cover := _cover_positions()
	for i in cover.size():
		var base := Vector2(cover[i],floor_y())
		var width: float = SchoolArt.PROP_WIDTHS[2 if school.level == School.Level.CLASSROOM else i]*(1.10 if portrait else 0.88)
		var hiding := hidden_in_cover and absf(player.x-cover[i]) <= _school_cover_radius(i)
		var tint := Color(1,1,1,0.28 if hiding else 1.0)
		var prop_index := 2 if school.level == School.Level.CLASSROOM else i
		_draw_school_prop(base,prop_index,width,tint)
		if hiding:
			var tag := base+Vector2(0,20)
			draw_line(tag-Vector2(17,0),tag+Vector2(17,0),Color("f7d991"),3.0,true)

func _background_legacy() -> void:
	var w := viewport_size.x
	var g := floor_y()
	var wall := Color("e5d5b5")
	var tint := Color(Story.ACTS[stage].tint)
	if state == "title": tint = TEAL
	draw_rect(Rect2(0,0,w,viewport_size.y),Color("c4af86"))
	draw_rect(Rect2(0,0,w,g),wall)
	draw_rect(Rect2(0,g-145,w,145),tint)
	for x in range(0,int(w),160):
		draw_rect(Rect2(x,g-145,4,145),Color(0.13,0.25,0.21,0.15))
	draw_line(Vector2(0,g-144),Vector2(w,g-144),PAPER,7)
	if stage == 0 or state == "title":
		for x in range(40,int(w),330):
			_arch_window(Vector2(x,g-380),Vector2(185,230),Color("42655e"))
		_board(Vector2(w*0.47,g-330),Vector2(280,140),"NOTICE BOARD","EXAMS · MONDAY")
	elif stage == 1:
		for x in range(30,int(w),280):
			_arch_window(Vector2(x,g-400),Vector2(180,170),Color("508378"))
		_awning(g-405)
		_board(Vector2(w*0.42,g-345),Vector2(295,150),"ANNACHI'S","FILTER COFFEE  /  10")
		draw_rect(Rect2(w*0.37,g-110,360,90),Color("8c6046"))
		draw_rect(Rect2(w*0.35,g-125,400,20),Color("e3bc6b"))
		for i in range(4): _coffee(Vector2(w*0.39+i*80,g-137),0.65)
	elif stage == 2:
		for x in range(20,int(w),190):
			draw_rect(Rect2(x,g-450,170,260),Color("7c9ca0"))
			for k in range(4): draw_rect(Rect2(x+10+k*42,g-300,18,110),Color("b9c0ac"))
			draw_line(Vector2(x+85,g-450),Vector2(x+85,g-190),PAPER,5)
		_board(Vector2(w*0.35,g-360),Vector2(330,125),"OMR TECH PARK","FRIDAY  /  RELEASE DAY")
		for x in range(60,int(w),360):
			draw_rect(Rect2(x,g-80,210,14),Color("5d695e"))
			draw_rect(Rect2(x+25,g-144,100,64),INK)
			draw_rect(Rect2(x+31,g-138,88,48),Color("729e92"))
			draw_line(Vector2(x+65,g-80),Vector2(x+65,g-10),INK,8)
	elif stage == 3:
		_arch_window(Vector2(75,g-410),Vector2(220,245),Color("548677"))
		draw_rect(Rect2(w*0.35,g-180,340,145),Color("9a594b"))
		draw_style_box(_style(Color("b7795d"),Color("74503b"),20),Rect2(w*0.33,g-140,380,110))
		for x in [w*0.37,w*0.51]: draw_style_box(_style(Color("d2b57c"),PAPER,8),Rect2(x,g-170,90,70))
		_board(Vector2(w*0.49,g-380),Vector2(130,140),"HOME","SWEET HOME")
		_coffee(Vector2(w*0.47,g-10),1.2)
	else:
		# Floral wedding arch, banana leaves, strings of marigolds.
		draw_style_box(_style(Color("cf8973"),GOLD,70),Rect2(w-400,g-430,350,405))
		for i in range(19):
			var a := PI + PI*float(i)/18
			var p := Vector2(w-225,g-250)+Vector2(cos(a)*185,sin(a)*190)
			draw_circle(p,17,GOLD)
			draw_circle(p+Vector2(0,5),8,PAPER)
		for x in range(40,int(w),200):
			draw_line(Vector2(x,0),Vector2(x,g-300),Color("9c8c4b"),3)
			for y in range(30,int(g-300),35): draw_circle(Vector2(x,y),9,GOLD)
		for x in [70,w-45]:
			draw_line(Vector2(x,g),Vector2(x,g-370),Color("6c824b"),12)
			for i in range(5): _oval(Vector2(x-36+i*13,g-355+i*24),Vector2(55,14),Color("6b8a50"))
		_board(Vector2(w*0.36,g-365),Vector2(300,130),"M & S","A NEW BEGINNING")
	# Stage floor and perspective tile grid.
	draw_rect(Rect2(0,g,w,viewport_size.y-g),Color("ba9c74"))
	draw_rect(Rect2(0,g,w,9),INK)
	for x in range(-400,int(w)+400,120):
		draw_line(Vector2(w/2+(x-w/2)*0.7,g+10),Vector2(x,viewport_size.y),Color(0.35,0.31,0.22,0.24),2)
	for y in range(int(g+25),int(viewport_size.y),55): draw_line(Vector2(0,y),Vector2(w,y),Color(0.35,0.31,0.22,0.22),2)
	if state != "title":
		_text(Story.ACTS[stage].tag,Vector2(w/2,g-207),20,INK,true)

func _arch_window(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_style_box(_style(Color("c9b18c"),Color("a78c63"),int(size.x/2)),Rect2(pos-Vector2(9,9),size+Vector2(18,18)))
	draw_style_box(_style(color,PAPER,int(size.x/2)),Rect2(pos,size))
	draw_line(pos+Vector2(size.x/2,0),pos+Vector2(size.x/2,size.y),PAPER,6)
	draw_line(pos+Vector2(0,size.y*.55),pos+Vector2(size.x,size.y*.55),PAPER,6)
	for i in range(4):
		var xx := pos.x+15+i*size.x/4
		draw_rect(Rect2(xx,pos.y+size.y*0.7,size.x/5,size.y*0.3),Color("779782"))

func _board(pos: Vector2, size: Vector2, title: String, sub: String) -> void:
	draw_style_box(_style(INK,GOLD,5),Rect2(pos,size))
	_text(title,pos+Vector2(size.x/2,45),25,PAPER,true)
	draw_line(pos+Vector2(20,65),pos+Vector2(size.x-20,65),GOLD,2)
	_text(sub,pos+Vector2(size.x/2,95),14,GOLD,true)

func _awning(y: float) -> void:
	for x in range(0,int(viewport_size.x),80):
		draw_rect(Rect2(x,y,80,68),PAPER if x%160 == 0 else ROSE)
		draw_circle(Vector2(x+40,y+68),40,PAPER if x%160 == 0 else ROSE)

func _coffee(pos: Vector2, scale_factor: float) -> void:
	draw_set_transform(pos,0,Vector2.ONE*scale_factor)
	_oval(Vector2(0,0),Vector2(29,7),GOLD)
	draw_rect(Rect2(-15,-28,30,26),Color("c39347"))
	_oval(Vector2(0,-28),Vector2(15,5),PAPER)
	draw_arc(Vector2(0,-46),10,PI,TAU,10,Color(1,1,0.9,0.5),2)
	draw_set_transform(Vector2.ZERO)

func _character_legacy(pos: Vector2, kind: String, scale_factor: float, walking: bool) -> void:
	var step := sin(age*15)*12 if walking and not reduce_motion else 0.0
	var bob := sin(age*(15 if walking else 3))*2 if not reduce_motion else 0.0
	_oval(Vector2(pos.x,floor_y()+4),Vector2(31*scale_factor,8),Color(0.1,0.15,0.12,0.18))
	draw_set_transform(pos+Vector2(0,bob),0,Vector2.ONE*scale_factor)
	var skin := Color("c38d62")
	var shirt := Color("dfb563")
	var pants := Color("374951")
	var feminine := kind in ["sharmila","aunty"]
	match kind:
		"hero":
			shirt = [Color("e2d5ad"),Color("d6a75b"),Color("6c9e9c"),Color("e4dfca"),Color("f0e3bd")][stage]
			pants = Color("425f65") if stage < 2 else Color("344747")
		"teacher": shirt = Color("d2b77d"); pants = Color("665744")
		"senior": shirt = Color("aa6654"); pants = Color("4c5550")
		"manager": shirt = Color("c5d5ca"); pants = Color("46515c")
		"father": shirt = PAPER; pants = Color("d0bc8c")
		"sharmila": shirt = Color("5d9187") if stage < 4 else Color("ba535d")
		"aunty": shirt = Color("9a6075")
	# Hose limbs, exaggerated shoes, mitten hands and an outlined silhouette.
	var leg1 := Vector2(-13+step, -4)
	var leg2 := Vector2(14-step, -4)
	draw_line(Vector2(-13,-42),leg1,INK,12,true)
	draw_line(Vector2(13,-42),leg2,INK,12,true)
	draw_line(Vector2(-13,-42),leg1,pants,8,true)
	draw_line(Vector2(13,-42),leg2,pants,8,true)
	_oval(leg1+Vector2(-5,1),Vector2(17,7),INK)
	_oval(leg2+Vector2(7,1),Vector2(17,7),INK)
	if feminine:
		_polygon([Vector2(-19,-85),Vector2(19,-85),Vector2(30,-20),Vector2(-30,-20)],shirt)
		draw_line(Vector2(-16,-81),Vector2(23,-23),GOLD,7,true)
		draw_line(Vector2(-28,-23),Vector2(27,-23),GOLD,4,true)
	else:
		draw_style_box(_style(shirt,INK,8),Rect2(-24,-88,48,49))
		draw_line(Vector2(0,-85),Vector2(0,-43),shirt.darkened(0.25),2)
		for yy in [-77,-65,-53]: draw_circle(Vector2(1,yy),1.6,INK)
		var sleeve_end := Vector2(40,-60) if kind == "hero" else Vector2(33,-46)
		draw_line(Vector2(18,-77),sleeve_end,INK,12,true)
		draw_line(Vector2(18,-77),sleeve_end,skin,8,true)
		draw_circle(sleeve_end,8,PAPER)
		draw_arc(sleeve_end,8,0,TAU,14,INK,2,true)
		if kind == "hero": _envelope(sleeve_end+Vector2(4,-4),PAPER,0.6)
	draw_line(Vector2(-18,-76),Vector2(-34,-48-step*.2),INK,11,true)
	draw_line(Vector2(-18,-76),Vector2(-34,-48-step*.2),skin,7,true)
	draw_circle(Vector2(-34,-48-step*.2),7,PAPER)
	draw_circle(Vector2(0,-111),26,INK)
	draw_circle(Vector2(0,-111),23,skin)
	draw_arc(Vector2(0,-116),23,PI,TAU,20,INK,13,true)
	# Forelock and rounded ears.
	draw_circle(Vector2(-10,-134),10,INK)
	draw_circle(Vector2(-24,-108),6,skin)
	draw_circle(Vector2(24,-108),6,skin)
	for x in [-8,10]:
		_oval(Vector2(x,-113),Vector2(6,9),PAPER)
		draw_circle(Vector2(x+2,-112),3,INK)
	draw_arc(Vector2(2,-102),9,0.1,PI-0.1,12,INK,2,true)
	if feminine:
		draw_line(Vector2(-23,-117),Vector2(-26,-65),INK,10,true)
		draw_circle(Vector2(-27,-76),8,PAPER)
		draw_circle(Vector2(1,-122),2.3,ROSE)
		draw_circle(Vector2(24,-103),3,GOLD)
		if kind == "sharmila":
			for i in range(4): draw_circle(Vector2(-26,-91+i*7),4,PAPER)
	if kind == "teacher" or kind == "father":
		draw_line(Vector2(-8,-101),Vector2(10,-101),INK,4,true)
	if kind in ["manager","father"]:
		for x in [-8,10]: draw_rect(Rect2(x-8,-120,15,13),INK,false,2)
	if kind == "manager":
		draw_line(Vector2(-26,-125),Vector2(-32,-96),INK,5,true)
		draw_line(Vector2(-32,-96),Vector2(-8,-94),INK,3,true)
		_polygon([Vector2(-5,-84),Vector2(5,-84),Vector2(7,-53),Vector2(0,-44),Vector2(-7,-53)],ROSE)
	if kind == "teacher":
		draw_line(Vector2(-10,-84),Vector2(0,-58),PAPER,2)
		draw_rect(Rect2(-5,-61,14,7),GOLD)
	if kind == "hero" and stage == 4:
		draw_line(Vector2(-15,-84),Vector2(-15,-25),GOLD,7)
		draw_line(Vector2(15,-84),Vector2(15,-25),ROSE,5)
	if boss_flash > 0 and kind != "hero":
		draw_arc(Vector2(0,-65),43,0,TAU,20,Color(1,0.92,0.76,0.8),4)
	draw_set_transform(Vector2.ZERO)

func _draw_hazard(hazard: Dictionary) -> void:
	var p: Vector2 = hazard.p
	if hazard.kind == "beam":
		var active: bool = hazard.life < 0.65
		var c := ROSE if active else Color(0.78,0.29,0.25,0.4)
		draw_line(Vector2(22,p.y),Vector2(viewport_size.x-100,p.y),c,28 if active else 3,true)
		if not active: _text("QUICK SYNC!  /  DASH OR JUMP",Vector2(viewport_size.x/2,p.y-22),18,ROSE,true)
		return
	if hazard.pink:
		_heart(p,15,Color("ea829a"))
		draw_arc(p,24,0,TAU,18,Color(1,0.7,0.76,0.45),2,true)
		return
	match hazard.kind:
		"chalk":
			draw_style_box(_style(PAPER,INK,3),Rect2(p-Vector2(18,6),Vector2(36,12)))
		"samosa":
			_polygon([p+Vector2(0,-18),p+Vector2(20,15),p+Vector2(-20,15)],GOLD)
		"coin":
			draw_circle(p,16,GOLD)
			draw_arc(p,11,0,TAU,16,INK,2,true)
		"scroll":
			draw_style_box(_style(PAPER,GOLD,5),Rect2(p-Vector2(24,13),Vector2(48,26)))
			draw_line(p-Vector2(15,0),p+Vector2(15,0),ROSE,3)
		"gossip":
			for i in range(3): draw_circle(p+Vector2(i*12-12, -7 if i==1 else 0),14,Color("736a79"))
			_text("?!",p+Vector2(-9,6),20,PAPER)
		_:
			_envelope(p,PAPER,1.2)
			if hazard.kind == "ticket": _text("BUG",p+Vector2(-12,5),11,ROSE)

func _draw_controls() -> void:
	var labels := {"left":"MOVE", "right":"MOVE", "dash":"DASH", "parry":"PARRY", "jump":"JUMP", "fire":"LETTER", "sneak":"DUCK", "hide":"HIDE"}
	for action in control_rects:
		var rect: Rect2 = control_rects[action]
		var bg := Color("213e37")
		var border := Color("b7a16b")
		if _held(action): bg = Color("94704e")
		if stage==0 and action=="sneak":
			bg = Color("94704e") if school_duck_latched else Color("286457")
		if action=="fire":bg = Color("a64350") if not _held(action) else Color("c6676e")
		if action=="parry":border=Color("df8d9e")
		if action=="dash" and dash_cooldown>0:bg=Color("485a50")
		draw_style_box(_style(bg,border,18),rect)
		draw_line(rect.position+Vector2(18,5),rect.position+Vector2(rect.size.x-18,5),Color(1,0.88,0.64,0.18),2)
		var center := rect.get_center()+Vector2(0,-10*ui_scale)
		var icon_size := 16*ui_scale
		if action=="left" or action=="right":
			var direction := -1.0 if action=="left" else 1.0
			draw_polyline(PackedVector2Array([center+Vector2(-direction*icon_size,-icon_size),center+Vector2(direction*icon_size,0),center+Vector2(-direction*icon_size,icon_size)]),PAPER,4*ui_scale,true)
		elif action=="dash":
			for dx in [-9,10]:
				var point := center+Vector2(dx*ui_scale,0)
				draw_polyline(PackedVector2Array([point+Vector2(-8,-12)*ui_scale,point+Vector2(4,0)*ui_scale,point+Vector2(-8,12)*ui_scale]),GOLD,3*ui_scale,true)
		elif action=="jump":
			draw_line(center+Vector2(0,14)*ui_scale,center+Vector2(0,-13)*ui_scale,PAPER,4*ui_scale,true)
			draw_polyline(PackedVector2Array([center+Vector2(-12,-2)*ui_scale,center+Vector2(0,-14)*ui_scale,center+Vector2(12,-2)*ui_scale]),PAPER,4*ui_scale,true)
		elif action=="hide":
			draw_arc(center,icon_size,0,PI,16,GOLD,3*ui_scale,true)
			draw_line(center-Vector2(icon_size,0),center+Vector2(icon_size,0),GOLD,3*ui_scale,true)
		elif action=="sneak":
			draw_circle(center+Vector2(7,-10)*ui_scale,5.5*ui_scale,PAPER,true)
			draw_polyline(PackedVector2Array([center+Vector2(4,-4)*ui_scale,center+Vector2(-9,3)*ui_scale,center+Vector2(1,10)*ui_scale,center+Vector2(13,10)*ui_scale]),PAPER,4.0*ui_scale,true)
		elif action=="parry":_heart(center,17*ui_scale,Color("ed9cab"))
		else:_envelope(center,PAPER,1.35*ui_scale)
		var label: String = labels[action]
		if stage==0 and action in ["left","right"]: label = action.to_upper()
		if stage==0 and action=="sneak" and school_duck_latched: label = "DUCKED"
		if action=="dash" and dash_cooldown>0:label="%.1fs"%dash_cooldown
		_text(label,rect.get_center()+Vector2(0,28*ui_scale),int(13*ui_scale),PAPER,true)

func _text(text: String, pos: Vector2, size: int, color: Color, centered: bool=false) -> void:
	var point := pos
	if centered: point.x -= font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2
	draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _oval(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(33):
		var a := TAU*i/32.0
		points.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
	draw_colored_polygon(points,color)

func _polygon(points: Array[Vector2], color: Color) -> void:
	var packed := PackedVector2Array(points)
	draw_colored_polygon(packed,color)
	packed.append(packed[0])
	draw_polyline(packed,INK,2,true)

func _envelope(pos: Vector2, color: Color, size: float) -> void:
	draw_style_box(_style(color,INK,3),Rect2(pos-Vector2(15,10)*size,Vector2(30,20)*size))
	draw_line(pos+Vector2(-14,-8)*size,pos+Vector2(0,3)*size,INK,1.5,true)
	draw_line(pos+Vector2(14,-8)*size,pos+Vector2(0,3)*size,INK,1.5,true)
	if color == ROSE: _heart(pos+Vector2(0,2),4,PAPER)

func _heart(pos: Vector2, size: float, color: Color) -> void:
	draw_circle(pos+Vector2(-size*.45,-size*.28),size*.58,color)
	draw_circle(pos+Vector2(size*.45,-size*.28),size*.58,color)
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-size,0),pos+Vector2(size,0),pos+Vector2(0,size)]),color)
