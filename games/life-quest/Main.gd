extends Node2D

const Story = preload("res://Stages.gd")
const INK := Color("203936")
const PAPER := Color("f6e9cf")
const GOLD := Color("dca74e")
const ROSE := Color("bf505e")
const TEAL := Color("347c75")
const SAVE := "user://life-quest.cfg"
const THRESHOLDS := [70.0, 40.0, 12.0]

var state := "title"
var previous_state := "title"
var stage := 0
var phase := 0
var unlocked := 0
var completed := false
var gentle := true
var sound_on := true
var reduce_motion := false
var auto_fire := true
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
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var viewport_size := Vector2(1100, 700)
var portrait := false
var ui_scale := 1.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	font = ThemeDB.fallback_font
	font.fallbacks = [preload("res://fonts/NotoSansTamil-Regular.ttf")]
	rng.randomize()
	_load_progress()
	_setup_audio()
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
		"hit": sfx.stream = preload("res://audio/hit.wav")
		"parry": sfx.stream = preload("res://audio/parry.wav")
		"win": sfx.stream = preload("res://audio/win.wav")
		_: sfx.stream = preload("res://audio/letter.wav")
	sfx.play()

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		unlocked = clampi(int(cfg.get_value("progress", "unlocked", 0)), 0, 4)
		completed = bool(cfg.get_value("progress", "completed", false))
		gentle = bool(cfg.get_value("settings", "gentle", true))
		sound_on = bool(cfg.get_value("settings", "sound", true))
		reduce_motion = bool(cfg.get_value("settings", "reduce_motion", false))
		auto_fire = bool(cfg.get_value("settings", "auto_fire", true))

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "completed", completed)
	cfg.set_value("settings", "gentle", gentle)
	cfg.set_value("settings", "sound", sound_on)
	cfg.set_value("settings", "reduce_motion", reduce_motion)
	cfg.set_value("settings", "auto_fire", auto_fire)
	var error := cfg.save(SAVE)
	if error != OK:
		push_warning("Progress could not be saved on this device (%s)." % error)

func floor_y() -> float:
	return viewport_size.y - (230.0 if portrait else 172.0)

func boss_position() -> Vector2:
	return Vector2(viewport_size.x - 150, floor_y())

func _resize() -> void:
	var old_floor := floor_y()
	viewport_size = get_viewport_rect().size
	portrait = viewport_size.y > viewport_size.x
	ui_scale = 2.0 if portrait else 1.0
	player.x = clampf(player.x, 50, viewport_size.x - 290)
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
			"dialogue": _show_dialogue()
			"feedback": _show_feedback()
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
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	return box

func _clear_screen() -> void:
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
	panel.add_theme_stylebox_override("panel", _style(INK, Color("7d8a68"), 20))
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
		button.add_theme_stylebox_override("normal", _style(ROSE, Color("e38f85"), 14))
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
	panel.position = Vector2(54, 70 if not portrait else 130)
	panel.size = Vector2(viewport_size.x - 108 if portrait else minf(600, viewport_size.x - 108), 0)
	panel.add_theme_stylebox_override("panel", _style(Color(0.09,0.21,0.20,0.94), Color("bc9b60"), 20))
	screen.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(12 * ui_scale))
	margin.add_child(col)
	_label(col, "A TAMIL CINEMA ADVENTURE", 18, GOLD)
	_label(col, "KALYANA\nKATHAL", 62, PAPER)
	_label(col, "T H E   L I F E   Q U E S T", 19, Color("a9c8b8"))
	_label(col, "Dodge the drama. Find the words.\nFrom a folded note to forever.", 23)
	var play := _button(col, "Choose your act  >" if unlocked > 0 else "Let the story begin  >", _show_map, true)
	var row := _row(col)
	_button(row, "How to play", _show_help)
	_button(row, "Settings", _open_settings)
	_label(col, "5 ACTS  /  TOUCH + KEYBOARD  /  SAVED ON DEVICE", 13, Color("b6c6b5"))
	play.grab_focus()

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
		button.disabled = not unlocked_act
		button.add_theme_font_size_override("font_size", int(22 * ui_scale))
	_label(col, "Replay any unlocked act. New acts unlock when you clear the last.", 18, Color("b9c9b8"))
	_button(col, "<  Title screen", _show_title)

func _select_act(index: int) -> void:
	stage = index
	_show_intro()

func _show_intro() -> void:
	state = "intro"
	var col := _modal()
	var act: Dictionary = Story.ACTS[stage]
	_label(col, "ACT %02d  /  %s" % [stage + 1, act.year], 18, GOLD)
	_label(col, act.name, 46)
	_label(col, act.place + "  ·  " + act.boss, 20, Color("b9d0ba"))
	_label(col, act.intro, 25)
	_label(col, "Lower the resistance shield to open three conversations.\nEarn 72 trust to clear this act. Kind words change the fight.", 20)
	_label(col, "DIRECTOR'S NOTE: " + act.hint, 18, GOLD)
	_button(col, "Action!  >", _start_stage, true).grab_focus()
	_button(col, "<  All acts", _show_map)

func _start_stage() -> void:
	state = "playing"
	phase = 0
	max_hp = 6 if gentle else 4
	hp = max_hp
	resistance = 100
	approval = 20
	charm = 0
	player = Vector2(160, floor_y())
	velocity = Vector2.ZERO
	facing = 1
	shot_clock = 0
	hazard_clock = 1.8
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
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 16)
	top.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)
	var line := _row(col)
	hp_label = _label(line, "", 23, PAPER)
	var pause_button := _button(line, "II  Pause", _pause)
	pause_button.custom_minimum_size = Vector2(155 * ui_scale, 0)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	progress_label = _label(col, "", 17, GOLD)
	boss_label = _label(col, Story.ACTS[stage].boss.to_upper() + "  /  RESISTANCE", 17, Color("d7c9b3"))
	resistance_bar = ProgressBar.new()
	resistance_bar.custom_minimum_size.y = 14 * ui_scale
	resistance_bar.show_percentage = false
	col.add_child(resistance_bar)
	charm_bar = ProgressBar.new()
	charm_bar.custom_minimum_size.y = 8 * ui_scale
	charm_bar.show_percentage = false
	charm_bar.add_theme_stylebox_override("fill", _style(GOLD, GOLD, 4))
	col.add_child(charm_bar)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 14)
	col.add_child(tools)
	heal_button = _button(tools, "Tiffin +2 HP [H]", _heal)
	talk_button = _button(tools, "Speak · fill gold meter [R]", _manual_talk)
	talk_button.disabled = true
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
	_update_hud()

func _update_hud() -> void:
	if not is_instance_valid(hud): return
	hp_label.text = "MURUGAN   ·   HP %d / %d" % [hp, max_hp]
	progress_label.text = "ACT %02d / 05   %s   ·   TRUST %d/72   ·   TALK %d/3" % [stage+1, Story.ACTS[stage].place, approval, mini(phase+1,3)]
	resistance_bar.value = resistance
	charm_bar.value = charm
	talk_button.disabled = charm < 100
	talk_button.text = "Speak now [R]" if charm >= 100 else "Speak · parry for gold [R]"
	heal_button.disabled = used_tiffin or hp >= max_hp
	heal_button.text = "Tiffin used" if used_tiffin else "Tiffin +2 HP [H]"
	status_label.text = "Pink petals can be parried · %s" % ("Auto letters ON" if auto_fire else "Hold LETTER / J to fire")

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
	var axis := 0.0
	if _held("left") or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): axis -= 1
	if _held("right") or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): axis += 1
	if axis != 0 and dash_time <= 0: facing = axis
	if dash_time > 0:
		player.x += facing * 800 * dt
		if int(age * 50) % 3 == 0: _burst(player + Vector2(0,-35), TEAL, 1)
	else:
		player.x += axis * 270 * dt
	player.x = clampf(player.x, 48, viewport_size.x - 295)
	if player.y < floor_y() or velocity.y < 0:
		velocity.y += 1250 * dt
		player.y += velocity.y * dt
		if player.y >= floor_y():
			player.y = floor_y()
			velocity.y = 0
	if (auto_fire or _held("fire") or Input.is_physical_key_pressed(KEY_J) or Input.is_physical_key_pressed(KEY_X)) and shot_clock <= 0:
		_fire()
	hazard_clock -= dt
	if hazard_clock <= 0:
		_spawn_pattern()
		hazard_clock = maxf(0.65, (1.5 if gentle else 1.12) - phase * 0.16 - stage * 0.05) / attack_speed
	for i in range(shots.size()-1,-1,-1):
		var bullet: Dictionary = shots[i]
		bullet.p += bullet.v * dt
		var target := boss_position() + Vector2(0,-62)
		if absf(bullet.p.x-target.x) < 48 and absf(bullet.p.y-target.y) < 88:
			resistance = maxf(0, resistance - 3.5)
			boss_flash = 0.10
			charm = minf(100, charm + 2)
			_burst(bullet.p, ROSE, 5)
			shots.remove_at(i)
		elif bullet.p.x > viewport_size.x + 30 or bullet.p.y < -40 or bullet.p.y > viewport_size.y:
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

func _fire() -> void:
	shot_clock = 0.23
	var origin := player + Vector2(30,-55)
	var aim := Vector2(1,0)
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
	if state == "playing" and player.y >= floor_y()-1:
		velocity.y = -555
		_burst(player, Color("d5c8a8"), 6)

func _dash() -> void:
	if state == "playing" and dash_cooldown <= 0:
		dash_time = 0.22
		dash_cooldown = 1.0
		invincible = maxf(invincible, 0.26)
		_sound("letter")

func _parry() -> void:
	if state == "playing" and parry_cooldown <= 0:
		parry_time = 0.24
		parry_cooldown = 0.5

func _heal() -> void:
	if state == "playing" and not used_tiffin and hp < max_hp:
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
	_burst(player+Vector2(0,-40), ROSE, 10)
	_sound("hit")
	if hp <= 0:
		_show_defeat()

func _manual_talk() -> void:
	if state == "playing" and charm >= 100:
		charm = 0
		resistance = minf(resistance, THRESHOLDS[phase])
		_open_dialogue()

func _open_dialogue() -> void:
	if state != "playing": return
	state = "dialogue"
	shots.clear()
	hazards.clear()
	_show_dialogue()

func _show_dialogue() -> void:
	state = "dialogue"
	var col := _modal(920)
	var talk: Dictionary = Story.ACTS[stage].talks[phase]
	_label(col, "CINEMA FREEZE-FRAME  ·  CONVERSATION %d / 3" % (phase+1), 16, GOLD)
	_label(col, talk.q, 30)
	_label(col, "TRUST %d / 72   ·   Choose a reply or write your own." % approval, 19, Color("bad2c0"))
	for i in range(3):
		var button := _button(col, "%d   %s" % [i+1,talk.choices[i]], _choose.bind(i))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", int(21 * ui_scale))
	dialogue_input = LineEdit.new()
	dialogue_input.placeholder_text = "Your words · Tamil / Tanglish / English"
	dialogue_input.max_length = 240
	dialogue_input.custom_minimum_size.y = 64 * ui_scale
	dialogue_input.text_submitted.connect(_submit_text)
	col.add_child(dialogue_input)
	_button(col, "Say it  >", _submit_current_text, true)
	_label(col, "Authored dialogue + local keyword rules. Your words stay on this device.", 15, Color("afc4b2"))

func _submit_current_text() -> void:
	if is_instance_valid(dialogue_input): _submit_text(dialogue_input.text)

func _submit_text(text: String) -> void:
	if state != "dialogue": return
	var evaluated := Story.evaluate(text,stage,phase)
	if evaluated.score == 0:
		dialogue_input.placeholder_text = evaluated.reply
		dialogue_input.clear()
		return
	_resolve_reply(evaluated.score,evaluated.reply)

func _choose(index: int) -> void:
	if state != "dialogue" or index < 0 or index > 2: return
	var talk: Dictionary = Story.ACTS[stage].talks[phase]
	_resolve_reply(talk.scores[index],talk.reply[index])

func _resolve_reply(score: int, reply: String) -> void:
	last_score = score
	last_question = Story.ACTS[stage].talks[phase].q
	response = reply
	approval = clampi(approval+score,0,100)
	attack_speed = 0.88 if score >= 20 else (1.13 if score < 0 else 1.0)
	_sound("parry" if score > 0 else "hit")
	_show_feedback()

func _show_feedback() -> void:
	state = "feedback"
	var col := _modal()
	_label(col, "THE WORDS THAT CHANGE THE SCENE", 17, GOLD)
	_label(col, response, 34)
	_label(col, "%s%d TRUST    ·    TOTAL %d / 72" % ["+" if last_score >= 0 else "", last_score, approval], 25, Color("b9d5bb") if last_score > 0 else Color("eeaaa0"))
	var note := "The next attack pattern slows down." if last_score >= 20 else "Listen to their concern. You can still turn this around."
	_label(col, note, 22)
	_button(col, "Continue  >", _continue_after_reply, true).grab_focus()

func _continue_after_reply() -> void:
	if phase == 2 and approval >= 72:
		_clear_stage()
		return
	if phase < 2:
		phase += 1
	else:
		# A missed conversation is recoverable; no softlock at zero resistance.
		resistance = 30
	state = "playing"
	invincible = 1.5
	hazard_clock = 1.5
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
	_label(col, "A little less drama.\nA little more trust.", 38)
	_label(col, Story.ACTS[stage].ending, 24)
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
	_label(col, "Original procedural artwork, animation and music.\nInspired by your Kalyana Kathal game design document.\nNo voice recording. No analytics. No remote AI.", 19, Color("b6cbb6"))
	_button(col, "Watch the reels again  >", _show_map, true)
	_button(col, "Title screen", _show_title)

func _show_defeat() -> void:
	state = "defeat"
	var col := _modal()
	_label(col, "CUT!  /  ONE MORE TAKE", 18, GOLD)
	_label(col, "Even heroes need a retake.", 38)
	_label(col, "Jump over low projectiles. Dash through danger.\nParry pink petals to fill the gold Speak meter.\nYour tiffin restores two hearts once per act.", 24)
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
	_label(col,"Progress and settings save locally in this browser.\nNo account, microphone or server is required.",21)
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
	_label(col,"TOUCH  ·  Hold arrows to move. Tap JUMP, DASH or PARRY.\nAuto letters are on by default. Multiple fingers work together.",23)
	_label(col,"KEYBOARD  ·  A/D or Left/Right move · SPACE jump · SHIFT dash\nJ/X fire · W/S or Up/Down aim · K parry · H heal · R speak\nESC/P pause · 1/2/3 choose a reply",21)
	_label(col,"Lower the shield to 70%, 40% and 12% to talk.\nReach 72 trust after three talks to clear the act.\nPink petals can be parried: fill gold for an early conversation.",23)
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

func _held(action: String) -> bool:
	return action in pointer_actions.values() or bool(held.get(action,false))

func _input(event: InputEvent) -> void:
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
		if not event.pressed:
			pointer_actions.erase(-1)
		elif state == "playing":
			var action := _control_at(event.position)
			pointer_actions[-1] = action
			_action(action)
			if action != "": get_viewport().set_input_as_handled()

func _control_at(point: Vector2) -> String:
	for key in control_rects:
		if control_rects[key].has_point(point): return key
	return ""

func _action(action: String) -> void:
	match action:
		"jump": _jump()
		"dash": _dash()
		"parry": _parry()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		if state == "playing": _pause()
		elif state == "paused": _resume()
		elif state == "dialogue": pass
		elif state == "settings" or state == "help": _settings_back()
		else: _show_title()
		get_viewport().set_input_as_handled()
		return
	if state == "playing":
		match event.keycode:
			KEY_SPACE: _jump()
			KEY_SHIFT: _dash()
			KEY_K: _parry()
			KEY_H: _heal()
			KEY_R: _manual_talk()
	elif state == "dialogue":
		# Text fields consume keys first so typing numbers never chooses a reply.
		if event.keycode >= KEY_1 and event.keycode <= KEY_3: _choose(event.keycode - KEY_1)

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

func _draw() -> void:
	if font == null: return
	var wobble := Vector2(sin(age*78)*shake,cos(age*69)*shake) if not reduce_motion else Vector2.ZERO
	draw_set_transform(wobble)
	_background()
	var scene_player := player
	if state == "title": scene_player = Vector2(viewport_size.x-330,floor_y())
	var animate := state == "playing" and absf(velocity.x)>0
	if state == "playing":
		animate = _held("left") or _held("right") or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)
	var actor_scale := 1.5 if portrait else 1.0
	if state == "title": actor_scale *= 1.6
	if invincible <= 0 or state != "playing" or int(age*14)%2==0:
		_character(scene_player,"hero",actor_scale,animate)
	if state == "title":
		_character(Vector2(viewport_size.x-155,floor_y()),"sharmila",actor_scale,false)
	else:
		var kind: String = ["teacher","senior","manager","father","aunty"][stage]
		_character(boss_position(),kind,actor_scale,false)
		if stage == 3: _character(boss_position()+Vector2(87,0),"aunty",actor_scale*0.85,false)
		if stage == 1 or stage == 4:
			_character(boss_position()+Vector2(94,0),"sharmila",actor_scale*0.85,false)
	for shot in shots: _envelope(shot.p,ROSE,1)
	for hazard in hazards: _draw_hazard(hazard)
	if parry_time > 0 and state == "playing":
		draw_arc(player+Vector2(0,-43),77,0,TAU,32,GOLD,5,true)
		_heart(player+Vector2(0,-100),12,ROSE)
	for particle in particles:
		var color: Color = particle.color
		color.a = minf(1,particle.life*2)
		draw_rect(Rect2(particle.p,Vector2(5,5)),color)
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

func _character(pos: Vector2, kind: String, scale_factor: float, walking: bool) -> void:
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
	var labels := {"left":"<", "right":">", "dash":"DASH", "parry":"PARRY", "jump":"JUMP", "fire":"LETTER"}
	for action in control_rects:
		var rect: Rect2 = control_rects[action]
		var bg := Color("284c46")
		var border := Color("97ab8d")
		if _held(action): bg = ROSE
		if action == "fire": bg = ROSE if not _held(action) else Color("d36d75")
		if action == "parry": border = Color("e591a1")
		if action == "dash" and dash_cooldown > 0: bg = Color("657069")
		draw_style_box(_style(bg,border,18),rect)
		var label: String = labels[action]
		if action == "dash" and dash_cooldown > 0: label = "%.1fs" % dash_cooldown
		_text(label,rect.get_center()+Vector2(0,9*ui_scale),int((34 if action in ["left","right"] else 20)*ui_scale),PAPER,true)

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
