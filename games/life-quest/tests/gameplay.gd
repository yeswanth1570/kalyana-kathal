extends SceneTree

var checks := 0
var failed := 0
var game: Node
const Story = preload("res://Stages.gd")

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition: print("PASS ", message)
	else:
		failed += 1
		push_error("FAIL " + message)

func run() -> void:
	game = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music.stop()
	# Keep tests from overwriting the player's real progress or settings.
	var save_path: String = ProjectSettings.globalize_path("user://school-preview.cfg")
	var had_save := FileAccess.file_exists(save_path)
	var saved_bytes := FileAccess.get_file_as_bytes(save_path) if had_save else PackedByteArray()
	game.sound_on = false
	game.gentle = true
	game.auto_fire = false
	game.qwen.endpoint = "http://127.0.0.1:1"
	game.qwen.access_code = "test-only-no-network-replies"
	check(Story.ACTS.size()==5,"Five complete story acts")
	check(game.state=="title","Starts safely on title, no attacks")
	game.stage=1
	game._start_stage()
	check(game.hp==6 and game.resistance==100 and game.phase==0,"Fresh run resets combat state")
	game.invincible=0
	game._jump()
	game._tick(0.016)
	check(game.player.y < game.floor_y(),"Jump moves upward from ground")
	for i in range(85): game._tick(0.016)
	check(is_equal_approx(game.player.y,game.floor_y()),"Jump lands on ground")
	game.hazards.clear()
	game._dash()
	check(game.dash_time>0 and game.invincible>0,"Dash grants short invulnerability")
	var first: float = game.dash_time
	game._dash()
	check(game.dash_time==first and game.dash_cooldown>0,"Dash cannot be spammed")
	game.dash_time=0
	game.invincible=0
	game._take_hit()
	var health: int=game.hp
	game._take_hit()
	check(game.hp==health,"Damage has a grace period")
	game._heal()
	check(game.used_tiffin and game.hp==6,"Tiffin restores health once")
	game.hp=3
	game._heal()
	check(game.hp==3,"Tiffin cannot be reused")
	game._start_stage()
	game.shots.clear()
	game._fire()
	var old_x: float=game.shots[0].p.x
	game._tick(0.016)
	check(game.shots[0].p.x>old_x,"Projectile updates persist in the array")
	# Place a real projectile at the boss hitbox, then advance the simulation.
	game.shots.clear()
	game.shots.append({"p":game.boss_position()+Vector2(-40,-62),"v":Vector2(660,0)})
	game._tick(0.016)
	check(game.impact_text=="POW!" and game.impact_time>0,"Letter contact triggers a visible impact burst")
	check(game.resistance<100,"Projectile hit reduces resistance")
	game.resistance=70
	game._tick(0.016)
	check(game.state=="dialogue" and game.hazards.is_empty(),"70 percent opens and freezes conversation")
	game._apply_agent_reply({"reply":"A contextual Qwen reply.","approval_delta":30,"attack_pattern":"calmer"})
	check(game.approval==50 and game.state=="dialogue","First good reply awards trust")
	game._continue_after_reply()
	check(game.phase==1 and game.state=="playing","Conversation resumes at phase two")
	game.resistance=40
	game._tick(0.016)
	check(game.state=="dialogue","40 percent opens second conversation")
	game._apply_agent_reply({"reply":"A contextual Qwen reply.","approval_delta":30,"attack_pattern":"calmer"})
	game._continue_after_reply()
	game.resistance=12
	game._tick(0.016)
	game._apply_agent_reply({"reply":"A contextual Qwen reply.","approval_delta":30,"attack_pattern":"calmer"})
	game._continue_after_reply()
	check(game.state=="clear" and game.unlocked>=1,"Three good conversations clear and unlock next act")
	check(game.approval==100,"Trust clamps to 100")
	# Weak dialogue must provide a recovery loop, not a dead boss softlock.
	game._start_stage()
	game.phase=2
	game.approval=0
	game.state="dialogue"
	game._apply_agent_reply({"reply":"Please respect my concern.","approval_delta":-15,"attack_pattern":"faster"})
	game._continue_after_reply()
	check(game.state=="playing" and game.resistance==30,"Poor dialogue can be recovered with another round")
	game._start_stage()
	game.charm=0
	game.parry_time=.24
	game.hazards.clear()
	game.hazards.append({"p":game.player+Vector2(5,-43),"v":Vector2.ZERO,"kind":"petal","pink":true,"gravity":0.0,"life":2.0})
	game._tick(.016)
	check(game.charm>=34 and game.hazards.is_empty(),"Parrying pink petal fills charm")
	game.charm=100
	game._manual_talk()
	check(game.state=="dialogue" and game.charm==0,"Full charm allows early conversation")
	game._start_stage()
	var start_time: float=game.elapsed
	game._pause()
	game._process(.1)
	check(game.state=="paused" and game.elapsed==start_time,"Pause freezes gameplay")
	game._resume()
	check(game.state=="playing","Resume returns to gameplay")
	game.pointer_actions[1]="left"
	game.pointer_actions[2]="fire"
	check(game._held("left") and game._held("fire"),"Multiple fingers can hold independent controls")
	game._lost_focus()
	check(game.pointer_actions.is_empty() and game.state=="paused","Focus loss clears held input and pauses")
	game._start_stage()
	game.hp=1
	game.invincible=0
	game._take_hit()
	check(game.state=="defeat","Zero hearts ends the act")
	game._start_stage()
	check(game.hp==6 and game.phase==0 and game.state=="playing","Retry restores a live fresh player")
	for act in range(5):
		check(Story.ACTS[act].talks.size()==3,"Act %d has three conversations"%(act+1))
		game.stage=act
		for p in range(3):
			check(not Story.ACTS[act].talks[p].q.is_empty(),"Act %d phase %d has grounded scene context"%[act+1,p+1])
		game._start_stage()
		if act == 0:
			game.school.level=2
			game._start_stage()
			game.player.x = game._stage_width()-65
			game._tick(.016)
			game._school_choice(true)
			game._resolve_school("pass")
		for p in range(0 if act == 0 else 3):
			game.resistance=game.THRESHOLDS[p]
			game._tick(.016)
			game._apply_agent_reply({"reply":"A contextual Qwen reply.","approval_delta":30,"attack_pattern":"calmer"})
			game._continue_after_reply()
		check(game.state==("school_ending" if act==0 else "clear"),"Act %d is completable"%(act+1))
	check(game.completed,"Final act saves completion")
	# Advance real projectile movement and collision at 60 FPS through a full act.
	game.stage=1
	game.auto_fire=true
	game._start_stage()
	var simulation_frames := 0
	while game.state != "clear" and simulation_frames < 9000:
		simulation_frames += 1
		if game.state=="playing":
			game.invincible=1 # Isolate projectile and phase timing.
			game._tick(1.0/60.0)
		elif game.state=="dialogue":
			game._apply_agent_reply({"reply":"A contextual Qwen reply.","approval_delta":30,"attack_pattern":"calmer"})
			game._continue_after_reply()
		else: break
	check(game.state=="clear","Real 60 FPS projectile simulation clears all three shield phases")
	check(simulation_frames>500 and simulation_frames<3500,"Combat finishes within intended timing")
	game._meet_sharmila()
	check(game.chat_only and game.state=="dialogue" and game.stage==1,"Title screen can open direct typed Sharmila chat")
	game.chat_draft="I remember your theatre idea."
	game._apply_agent_reply({"reply":"You remembered!","approval_delta":999,"attack_pattern":"calmer"})
	game.chat_draft="Let us plan the fest together."
	game._apply_agent_reply({"reply":"That sounds good.","approval_delta":999,"attack_pattern":"calmer"})
	check(game.phase_gain==36,"Repeated model replies have bounded phase trust gains")
	check(game.agent_histories.has("Sharmila"),"Agent remembers recent typed messages in this session")
	game._finish_chat()
	check(game.state=="title","Direct chat returns to title without changing story progression")
	# Offline play preserves real trust and clears the final phase without a reply.
	game.stage=1
	game.auto_fire=false
	game.qwen.endpoint=""
	game.qwen.access_code=""
	game._start_stage()
	for p in range(3):
		game.resistance=game.THRESHOLDS[p]
		game._tick(.016)
	check(game.state=="clear" and game.approval==20 and game.offline_run,"Missing Qwen skips all talks without fabricated trust or a softlock")
	game._meet_sharmila()
	check(game.state=="title","Offline direct chat returns safely to title")
	game.qwen.endpoint="http://127.0.0.1:1"
	game.qwen.access_code="test-only"
	game._start_stage()
	game._open_dialogue()
	var old_id: int=game.dialogue_id
	game._agent_failed("Connection lost")
	check(game.state=="playing" and game.phase==1,"Connection failures resume gameplay")
	game._open_dialogue()
	game._web_chat_event([JSON.stringify({"id":old_id,"kind":"skip"})])
	check(game.state=="dialogue" and game.phase==1,"Stale browser callbacks cannot affect a new conversation")
	game._skip_dialogue()
	# Readable attack timing and explicit animation state.
	game._start_stage()
	for i in range(30):game._tick(.016)
	check(game.shots.is_empty() and game.attack_pose==0,"Idle hero does not throw without input")
	game.hazard_clock=0
	game._tick(.016)
	check(game.windup>0 and game.hazards.is_empty(),"Enemy telegraphs before releasing a hazard")
	for i in range(42):game._tick(.016)
	check(not game.hazards.is_empty(),"Telegraph releases one deliberate attack")
	game._fire()
	check(game.attack_pose>0,"Manual fire enters its own throw animation")
	game._jump()
	for i in range(56):game._tick(.016)
	check(game.landing_pose>0,"Jump ends in a landing pose")
	game.stage=0
	game.school.level=0
	game.school.repair_pending=false
	game.school.honor_pass=false
	game._start_stage()
	game._parry()
	game._jump()
	game._fire()
	check(game.parry_time==0 and game.velocity.y==0 and game.shots.is_empty(),"School has stealth controls without combat attacks")
	check(not game.control_rects.has("pencil"),"Before the Bell hides unavailable pencil controls")
	var duck_tap := InputEventScreenTouch.new()
	duck_tap.position=game.control_rects.sneak.get_center()
	duck_tap.index=0
	duck_tap.pressed=true
	game._input(duck_tap)
	duck_tap.pressed=false
	game._input(duck_tap)
	game._tick(.016)
	check(game.school_duck_latched and game.school_ducking,"Duck remains latched after a tap is released")
	var pad_press := InputEventScreenTouch.new()
	pad_press.index=1
	pad_press.pressed=true
	pad_press.position=game.control_rects.left.get_center()
	game._input(pad_press)
	var drag := InputEventScreenDrag.new()
	drag.index=1
	drag.position=game.control_rects.right.get_center()
	game._input(drag)
	check(not game._held("left") and game._held("right"),"Sliding across the movement pad reverses direction")
	drag.position=game.control_rects.sneak.get_center()
	game._input(drag)
	check(not game._held("right") and game.school_duck_latched,"Dragging off movement stops and never toggles an action")
	pad_press.pressed=false
	game._input(pad_press)
	game._start_stage()
	check(not game.school_duck_latched,"Restart clears the latched stance")
	check(game.SchoolArt.master_frame(false,false,false,true,.5,false,0)==4,"Patrol turns transition through the canonical front pose")
	var motion = game.SchoolMotion
	check(motion.step_index(motion.advance_step(0.0,20.0,false))==1,"Running advances one of eight poses per 20 world pixels")
	check(motion.step_index(motion.advance_step(0.0,13.0,true))==1,"Crouch movement uses a shorter cycle")
	check(motion.advance_step(0.5,0.0,true)==0.5,"Stopping freezes the distance-based phase")
	check(motion.transition_index(.16,false)==0 and motion.transition_index(.50,false)==1 and motion.transition_index(.84,false)==2,"Duck and stand can show three intermediate silhouettes")
	check(motion.transition_index(.16,true)==1 and motion.transition_index(.84,true)==1,"Reduced motion uses one intermediate silhouette")
	for index in range(2):
		var start_feet: Vector2 = motion.student_feet(index,0.0)
		var end_feet: Vector2 = motion.student_feet(index,1.0)
		var travel := end_feet-start_feet
		check(travel.x*travel.y<0.0,"Student %d follows the slope of the corridor"%(index+1))
		check((motion.student_scale(end_feet)-motion.student_scale(start_feet))*travel.x<0.0,"Student %d scales with projected depth"%(index+1))

	game.master_facing=1
	game.player.x=game._cover_positions()[2]
	game.master_x=game.player.x-130.0
	game._tick(.1)
	check(game.awareness>0 and not game.hidden_in_cover,"Standing behind a cart is visible")
	game.held["sneak"]=true
	game._tick(.1)
	check(game.school_ducking and game.hidden_in_cover and game.awareness<6.2,"Ducking behind the cart occludes Sundaram’s view")
	game.player.x=game.master_x+190
	game.awareness=0
	game._tick(.1)
	check(game.school_ducking and not game.hidden_in_cover and game.awareness>0,"Ducking in the open slows but does not remove detection")
	var phase_before: float = game.school_step_phase
	game.awareness=35
	game._update_school_mood(0.0,0.0,false)
	check(game.school_mood==motion.Mood.WORRIED,"Murugan looks worried at 35 percent")
	game.awareness=70
	game._update_school_mood(0.0,35.0,false)
	check(game.school_mood==motion.Mood.ALARMED,"Murugan looks alarmed at 70 percent")
	game.awareness=68
	game._update_school_mood(0.0,70.0,false)
	check(game.school_mood==motion.Mood.ALARMED,"Alarm stays steady just below its entry threshold")
	game.player.x=game._cover_positions()[2]
	game._tick(.016)
	check(game.school_mood==motion.Mood.RELIEVED and is_equal_approx(game.school_relief,.5),"Reaching cover from danger triggers relief for half a second")
	check(game.school_step_phase==phase_before,"Changing expression leaves the crouch phase alone")
	game._update_school_mood(.51,68.0,false)
	check(game.school_mood!=motion.Mood.RELIEVED,"Relief expires after the cover reaction")
	game._start_stage()
	game.master_x=600
	game.master_facing=1
	game.awareness=99
	game.player.x=690
	game._tick(.05)
	check(game.state=="school_result" and game.school.reason=="caught" and game.school.turn_limit()==4,"Capture opens a harder debrief immediately")
	game._end_school("success","reached")
	check(game.school.outcome=="failure","Duplicate terminal events cannot replace a captured result")
	game._school_choice(false)
	game._resolve_school("conditional")
	check(game.state=="intro" and game.school.repair_pending,"Written repair earns a supervised checkpoint")
	game._start_stage()
	game.player.x=game._school_desks()[0]
	game._school_interact()
	check(game.school.level==1 and not game.school.repair_pending and game.state=="intro","Completing the repair unlocks the next scene")
	game._start_stage()
	game.player.x=game._school_desks()[1]
	game._school_interact()
	check(game.school.reason=="wrong_desk","Wrong notebook desk opens the failure debrief")
	game._resolve_school("retry")
	for i in range(3):
		game.player.x=game._school_desks()[i]
		game._school_interact()
		if i==1:
			game.player=game._activity_position()
			game._use_activity()
			check(game.school.honor_pass,"Two notebooks unlock the Honor Pass reward")
	check(game.school.placed==3 and game.school.outcome=="success","Three correctly matched notebooks open a victory debrief")
	game._school_choice(true)
	game._resolve_school("pass")
	check(game.school.level==2 and game.school.honor_pass,"Honor Pass carries into the finale")
	game._start_stage()
	game.player.x=game._stage_width()*.31
	game._tick(.016)
	check(game.school.pencil,"The player picks up a pencil")
	game.master_x=game.player.x-150
	game.master_facing=1
	game._throw_pencil()
	check(not game.school.pencil and game.awareness>=25,"An observed pencil throw is charged and raises suspicion")
	game.player.x=game.master_x-160
	game.facing=1
	game.school.pencil=true
	game._throw_pencil()
	for i in range(22): game._tick(.016)
	check(game.school.listen_time>1.5,"An unseen throw distracts Sundaram when it lands in view")
	game.player.x=game._stage_width()-68
	game.awareness=0
	game._tick(.06)
	check(game.state=="school_result" and game.school.turn_limit()==2 and game.camera_x>0,"A clean scroll-to-gate escape opens the easier debrief")
	game.qwen.endpoint=""
	game.qwen.access_code=""
	game._open_school_chat()
	check(game.state=="school_result" and game.school.outcome=="success","Unavailable Qwen keeps the required debrief playable with written responses")
	game.state="dialogue"
	game._apply_school_reply({"reply":"Why are you here?","addressed":["purpose","ownership"]})
	check(game.school_resolution.is_empty(),"Extra or unrelated concern IDs cannot resolve Side Gate")
	game._apply_school_reply({"reply":"Fair enough.","addressed":["choice"]})
	check(game.school_resolution=="pass","Acknowledging refusal resolves a clean final debrief")
	game._resolve_school("pass")
	check(game.state=="school_ending" and game.unlocked>=1,"After class scene unlocks college")
	game._start_stage()
	game.elapsed=game.school.TIMES[2]
	game._tick(.016)
	check(game.state=="school_result" and game.school.reason=="bell","Timeout opens the failure debrief")
	game._start_stage()
	game.stage=1
	game.auto_fire=false
	game._start_stage()
	var tap := InputEventScreenTouch.new()
	tap.index=2
	tap.position=game.control_rects.fire.get_center()
	tap.pressed=true
	game._input(tap)
	tap.pressed=false
	game._input(tap)
	game._tick(.016)
	check(game.shots.size()==1,"A touch press and release between frames throws one letter")
	game._action("fire")
	check(game.shots.size()==1,"Rapid taps respect throw cooldown")
	game.stage=0
	game.school.level=0
	game.school.repair_pending=false
	game._start_stage()
	var stealth_frames := 0
	game.held["right"]=true
	game.held["sneak"]=true
	while game.state=="playing" and stealth_frames<1700:
		stealth_frames+=1
		game._tick(1.0/60)
	check(game.state=="school_result" and game.school.outcome=="success","Before the Bell can be cleared with real patrol movement")
	game.qwen.cancel()
	if had_save:
		var file := FileAccess.open(save_path,FileAccess.WRITE)
		file.store_buffer(saved_bytes)
	else:
		DirAccess.remove_absolute(save_path)
	print("RESULT: %d checks, %d failures"%[checks,failed])
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
