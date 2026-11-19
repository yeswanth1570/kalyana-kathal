extends SceneTree

const School = preload("res://SchoolChapter.gd")
const Main = preload("res://Main.tscn")

var game: Node
var checks := 0
var failures := 0
var save := "user://campaign-test-%d.cfg" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition: print("PASS ", description)
	else:
		failures += 1
		push_error("FAIL " + description)

func boot() -> void:
	game = Main.instantiate()
	game.progress_path = save
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music.stop()
	game.sound_on = false

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	game._input(event)

func pad_button(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 2
	event.button_index = button
	event.pressed = true
	game._input(event)
	event.pressed = false
	game._input(event)

func buttons() -> Array[String]:
	var names: Array[String] = []
	for button in game.screen.find_children("*", "Button", true, false):
		if button.is_visible_in_tree(): names.append(button.text)
	return names

func run() -> void:
	await boot()
	check(game.state == "title" and "Begin Story" in buttons(), "Fresh project opens on a playable title screen")
	check(not game.options.live_dialogue, "Live dialogue is opt-in")
	game._continue_campaign()
	check(game.state == "exploring" and game.stage == 0, "Begin Story enters the school approach")
	var initial: Vector2 = game.exploration.position
	key(KEY_D, true)
	key(KEY_W, true)
	game._tick_exploration(0.04)
	var walking: Vector2 = game.exploration.position - initial
	check(walking.x > 0 and walking.y < 0 and is_equal_approx(walking.length(), 151.0 * 0.04), "Diagonal keyboard walking is normalized")
	key(KEY_SHIFT, true)
	var before: Vector2 = game.exploration.position
	game._tick_exploration(0.04)
	check(before.distance_to(game.exploration.position) > walking.length(), "Run increases speed")
	key(KEY_SPACE, true)
	before = game.exploration.position
	game._tick_exploration(0.04)
	check(before.distance_to(game.exploration.position) < walking.length(), "Sneak takes precedence over Run")
	game._pause()
	check(game.state == "paused" and game.keys_down.is_empty(), "Opening pause clears held keys")
	key(KEY_D, true)
	game._resume()
	before = game.exploration.position
	game._tick_exploration(0.04)
	check(before == game.exploration.position, "A key pressed over the menu does not move the hero when resumed")
	game._restart_campaign()
	var touch := InputEventScreenTouch.new()
	touch.index = 1
	touch.position = game.joystick_center + Vector2(40, -15)
	touch.pressed = true
	game._input(touch)
	game._update_exploration_hud()
	await process_frame
	var other_touch := InputEventScreenTouch.new()
	other_touch.index = 2
	other_touch.position = game.screen.get_node("TouchPace").get_child(0).get_global_rect().get_center()
	other_touch.pressed = true
	game._input(other_touch)
	game._tick_exploration(0.04)
	check(game.joystick_id == 1 and game.touch_pace == "run" and game.exploration.position != initial,"A second finger can switch pace while the first finger moves")
	touch.canceled = true
	touch.pressed = false
	game._input(touch)
	check(game.joystick_id == -2 and game.joystick_vector == Vector2.ZERO, "Touch cancellation releases the joystick")
	var pad := InputEventJoypadMotion.new()
	pad.device = 2
	pad.axis = JOY_AXIS_LEFT_X
	pad.axis_value = 0.11
	game._input(pad)
	check(game._movement_vector(true) == Vector2.ZERO, "Controller stick has a deadzone")
	pad.axis_value = 0.65
	game._input(pad)
	check(game._movement_vector(true).x > 0.5, "Controller stick supplies analog movement")
	game._joy_connection_changed(2, false)
	check(game._movement_vector(true) == Vector2.ZERO, "Disconnect clears controller movement")
	pad_button(JOY_BUTTON_START)
	check(game.state == "paused", "Controller Start pauses exploration")
	pad_button(JOY_BUTTON_DPAD_DOWN)
	pad_button(JOY_BUTTON_A)
	check(game.state == "player_panel" and game.player_panel == "Journal", "Controller D-pad and A open the focused pause panel")
	pad_button(JOY_BUTTON_B)
	pad_button(JOY_BUTTON_B)
	check(game.state == "exploring", "Controller B backs out of panels and resumes")
	game._pause()
	game._open_settings()
	game._settings_page("Controls")
	game._capture_key("interact")
	key(KEY_D, true)
	check(game.options.keys.interact == KEY_E and "already uses" in game.settings_notice, "Remapping reports conflicts")
	game._capture_key("interact")
	key(KEY_F, true)
	check(game.options.keys.interact == KEY_F, "Remapping updates an action")
	game._settings_back()
	game._resume()
	for act in range(5):
		game.exploration.begin(act)
		var obstacle: Rect2 = game.exploration.descriptor()[4]
		game.exploration.walk_to(obstacle.get_center())
		check(game.exploration.path.is_empty(), "Act %d rejects click targets inside props" % (act+1))
		game.exploration.walk_to(game.exploration.target())
		var first_path: bool = not game.exploration.path.is_empty()
		var clear := true
		for frame in range(400):
			game._tick_exploration(0.02)
			clear = clear and game.exploration.walkable(game.exploration.position)
		check(first_path and clear and game.exploration.near_target(), "Act %d click-to-walk routes around solid props" % (act+1))
	game.exploration.begin(0)
	game.exploration.position = game.exploration.target()
	key(KEY_E, true)
	check(game.state == "exploring", "Previous interact key no longer activates the marker")
	key(KEY_F, true)
	check(game.state == "intro" and game.journal.size() == 1, "Remapped interaction records the approach and enters the scene")
	game._start_stage()
	game._end_school("failure", "caught")
	game._school_choice(false)
	game.free()
	await boot()
	game._continue_campaign()
	check(game.state == "school_result" and game.school.meeting_pending and game.school_resolution == "conditional", "Reopening restores a committed parent–teacher meeting")
	game._show_map()
	game._select_act(0)
	check(game.state == "school_result" and game.school.meeting_pending, "Browsing chapters preserves the pending school meeting")
	check(game.options.keys.interact == KEY_F, "Keyboard bindings survive reopening")
	game._resolve_school("conditional")
	check(game.school.supervised, "Written meeting choice earns the supervised retry")
	game._start_stage()
	game.held["right"] = true
	game.held["sneak"] = true
	for frame in range(1700):
		if game.state != "playing": break
		game._tick(1.0/60)
	check(game.state == "school_result" and game.school.reason == "reached", "Before the Bell is passable with the original patrol")
	game._school_choice(true)
	game._resolve_school("pass")
	game._start_stage()
	game.player.x = game._note_position()
	game._school_interact()
	for frame in range(32):
		game._tick(1.0/60)
	check(game.school.reason == "note_delivered", "Classroom note handoff is playable")
	game._school_choice(true)
	game._resolve_school("pass")
	game._start_stage()
	game.held["right"] = true
	for frame in range(1800):
		if game.state != "playing": break
		game._tick(1.0/60)
	check(game.school.reason == "bus_stop", "Walk Home reaches Sharmila’s scripted ending")
	game._finish_home("friends")
	game._next_stage()
	check(game.unlocked == 1 and game.state == "exploring", "School ending unlocks the college approach")
	for act in range(1,5):
		game.exploration.position = game.exploration.target()
		game._exploration_interact()
		game._start_stage()
		for phase in range(3):
			game.resistance = game.THRESHOLDS[phase]
			game._tick(0.016)
			check(game.state == "dialogue" and game.written_dialogue, "Act %d opens offline exchange %d" % [act+1, phase+1])
			game._choose_written(1 if act == 1 and phase == 2 else 0)
			game._continue_after_reply()
		if act == 1:
			check(game.state == "playing" and game.approval == 62, "A poor response needs a follow-up conversation")
			game.resistance = game.THRESHOLDS[2]
			game._tick(0.016)
			game._choose_written(0)
			game._continue_after_reply()
		check(game.state == "clear", "Act %d resolves through written choices" % (act+1))
		game._next_stage()
	check(game.completed and game.state == "credits", "Offline campaign reaches the wedding ending")
	var before_replay: Array = game.journal.duplicate(true)
	game._show_map()
	game._select_act(1)
	game.exploration.position = game.exploration.target()
	game._exploration_interact()
	game._start_stage()
	game._clear_stage()
	game._set_option(0.45, "master")
	game._show_title()
	check(game.completed and game.unlocked == 4 and game.journal == before_replay, "Previous-chapter replay preserves the canonical save")
	check(is_equal_approx(game.options.master, 0.45), "Settings changes still persist during a replay")
	game._confirm_restart()
	game._show_title()
	check(game.completed and game.journal == before_replay, "Cancelling restart preserves the campaign")
	game._restart_campaign()
	check(game.journal.is_empty() and not game.completed and game.unlocked == 0 and game.options.keys.interact == KEY_F, "Confirmed restart resets story progress and keeps options")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))
	print("CAMPAIGN RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
