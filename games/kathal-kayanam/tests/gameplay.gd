extends SceneTree

var checks := 0
var failed := 0
var game: Node
const School = preload("res://SchoolChapter.gd")
const Veranda = preload("res://Veranda.gd")
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
	game.progress_path = "user://gameplay-test-%d.cfg" % OS.get_process_id()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.music.stop()
	var save_path: String = ProjectSettings.globalize_path(game.progress_path)
	game.sound_on = false
	game.gentle = true
	game.auto_fire = false
	game.options.live_dialogue = true
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
	# Offline play uses authored responses and the same trust gate as live dialogue.
	game.stage=1
	game.auto_fire=false
	game.qwen.endpoint=""
	game.qwen.access_code=""
	game._start_stage()
	for p in range(3):
		game.resistance=game.THRESHOLDS[p]
		game._tick(.016)
		check(game.state=="dialogue" and game.written_dialogue,"Missing Qwen opens written conversation %d" % (p+1))
		game._choose_written(0)
		game._continue_after_reply()
	check(game.state=="clear" and game.approval==92,"Offline choices award trust and clear the act")
	game._meet_sharmila()
	check(game.state=="title","Offline direct chat returns safely to title")
	game.qwen.endpoint="http://127.0.0.1:1"
	game.qwen.access_code="test-only"
	game._start_stage()
	game._open_dialogue()
	var old_id: int=game.dialogue_id
	game._agent_failed("Connection lost")
	check(game.state=="dialogue" and game.written_dialogue and game.phase==0,"Connection failures keep the current conversation available")
	game._choose_written(0)
	game._continue_after_reply()
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
	game.school.checkpoint=0
	game.school.meeting_pending=false
	game.school.supervised=false
	game.school.honor_pass=false
	game._start_stage()
	game._parry()
	game._jump()
	game._fire()
	check(game.parry_time==0 and game.velocity.y==0 and game.shots.is_empty(),"School has stealth controls without combat attacks")
	check(game.control_rects.keys()==["dash"],"The veranda shows a single Dash control")
	check(not game._veranda_choose(Veranda.END),"Out-of-reach cover cannot be selected")
	var cover_tap := InputEventScreenTouch.new()
	cover_tap.position=game._veranda_base(1)-Vector2(0,55)
	cover_tap.index=0
	cover_tap.pressed=true
	game._input(cover_tap)
	cover_tap.pressed=false
	game._input(cover_tap)
	check(game.veranda.target==1,"Touch selects the tapped world-space cover")
	for i in range(135): game._tick(1.0/60.0)
	check(game.veranda.resting==1 and game.school_ducking,"Sneaking snaps to cover and auto-crouches")
	check(Veranda.concealment(1,true,220.0) and not Veranda.concealment(1,true,64.0),"Soft cover only protects at a distance")
	check(Veranda.concealment(3,true,0.0),"Hard cover conceals even at point-blank range")
	game.master_x=game.player.x+150
	game._dash()
	check(game.veranda.sprint and game.veranda.ripple>0.0,"Tapping Dash sprints to the next cover and creates a ripple")
	check(game.veranda.watch==Veranda.Watch.SUSPICIOUS and is_equal_approx(game.veranda.grace,1.2),"An audible Dash gives Sundaram a 1.2-second grace window")
	game._tick(.25)
	check(game.hp==3 and game.awareness<100.0,"Suspicion grants time to move before it can catch the player")
	var puddle: float = game._stage_width()*Veranda.PATCHES[0]
	game.player.x=puddle+3.0
	game.master_x=puddle+120.0
	game._veranda_floor_noise(puddle-45.0)
	check(game.veranda.splash and game.awareness>=40.0,"Dashing through water raises awareness with a louder ripple")
	game._start_stage()
	var guard_before_bell: float = game.master_x
	var pull: Vector2 = game._veranda_rope()+Vector2(0,32)
	check(game._veranda_tap(pull) and game.veranda.bell_time>0.0,"The visible brass rope is a world-space distraction")
	game._tick(.15)
	check(game.master_facing==1.0,"The guard keeps his sight direction during turn anticipation")
	for i in range(40): game._tick(.016)
	check(game.master_x<guard_before_bell,"The bell draws Sundaram back to investigate")
	for pose in range(8):
		var remaining := Veranda.TURN_DURATION*(1.0-(pose+0.25)/8.0)
		check(Veranda.turn_pose(remaining,false)==pose,"Guard pivot shows ordered pose %d"%(pose+1))
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

	game._start_stage()
	game.player=game._veranda_base(3)
	game.veranda.resting=3
	game.master_x=game.player.x
	game._tick(.016)
	check(game.veranda.checkpoint==3 and game.hidden_in_cover,"Arriving inside a hard doorway records a checkpoint")
	game.player.x+=125.0
	game.veranda.resting=-1
	game.master_x=game.player.x-60.0
	game.master_facing=1
	game.veranda.watch=Veranda.Watch.SUSPICIOUS
	game.veranda.grace=0.0
	game.awareness=99.0
	game._tick(.04)
	check(game.veranda.watch==Veranda.Watch.CAUGHT and game.hp==2 and game.player==game._veranda_base(3),"Caught at full awareness loses one HP and returns to the last hard cover")
	game._tick(.12)
	check(game.hp==2 and game.state=="playing","Recovery prevents repeat damage")
	game.hp=1
	game.veranda.watch=Veranda.Watch.SUSPICIOUS
	game.veranda.grace=0.0
	game.veranda.resting=-1
	game.player.x=game.master_x+75.0
	game.awareness=99.0
	game._tick(.04)
	game._tick(.70)
	check(game.state=="school_result" and game.school.reason=="caught" and game.school.turn_limit()==4,"The last lost HP opens the parent–teacher meeting")
	game._end_school("success","reached")
	check(game.school.outcome=="failure","Duplicate terminal events cannot replace a captured result")
	check(game.school.meeting_pending and game._agent_name().contains("Amma"),"A catch brings the parent and the responsible teacher into the meeting")
	game.qwen.endpoint=""
	game.qwen.access_code=""
	game._open_school_chat()
	check(game.state=="school_result","Offline meeting returns to written responses")
	game._school_choice(false)
	game._load_progress()
	game._show_intro()
	check(game.state=="school_result" and game.school_resolution=="conditional","Reload restores the resolved meeting")
	game._resolve_school("conditional")
	check(game.state=="intro" and game.school.supervised and game.school.level==0,"Owning the mistake earns a supervised retry of the same level")
	game._load_progress()
	check(game.school.supervised and not game.school.meeting_pending,"Reload preserves the supervised route")
	game._start_stage()
	game.master_x=game._stage_width()*.90-1.0
	game._tick(.016)
	check(game.master_turn>2.5,"Supervision gives Sundaram a longer stop")
	game.player=game._veranda_base(Veranda.END)
	game._tick(.016)
	game._school_choice(true)
	game._resolve_school("pass")
	check(game.school.level==1 and not game.school.supervised and game.state=="intro","Clearing the corridor advances to class")

	game._start_stage()
	check(is_equal_approx(game.player.x,game._cover_positions()[0]),"Class starts at the last bench")
	check(game.school.gaze(3.9)==School.Gaze.WRITING and game.school.gaze(4.2)==School.Gaze.TURNING_TO_CLASS and game.school.gaze(5.0)==School.Gaze.WATCHING and game.school.gaze(7.0)==School.Gaze.TURNING_TO_BOARD,"Revathi writes, turns, watches, then turns back")
	game.school.supervised=true
	check(game.school.gaze(5.9)==School.Gaze.WRITING,"Supervision adds two seconds to the writing window")
	game.school.supervised=false
	game.elapsed=4.9
	game.held["sneak"]=true
	game._tick(.016)
	check(game.hidden_in_cover and game.awareness==0,"A desk shields a crouching player while Revathi watches")
	game.player.x=(game._cover_positions()[0]+game._cover_positions()[1])*0.5
	game._tick(.016)
	check(not game.hidden_in_cover and game.awareness>0,"A crouched player in the aisle can still be seen")
	game.player.x=game._note_position()+100.0
	game.elapsed=1.0
	check(game._can_offer_note(),"Standing beside Sharmila can trigger the note handoff")
	game.elapsed=5.0
	game.player.x=game._note_position()
	game._school_interact()
	check(game.school.note_time==0.0 and not game.school_action_button.visible,"Revathi watching blocks the note action")
	game.awareness=99
	game.held.clear()
	game._tick(.025)
	check(game.school.meeting_pending and game._agent_name().contains("Revathi"),"Classroom catch opens Revathi’s meeting")
	game.state="dialogue"
	game._apply_school_reply({"school_protocol":3,"reply":"What happened?","addressed":["choice"]})
	check(game.school_resolution.is_empty(),"Unrelated concerns cannot change the retry route")
	for i in range(3):
		game._apply_school_reply({"school_protocol":3,"reply":"Try the scene again.","addressed":[]})
	check(game.school_resolution=="retry","Four unresolved replies lead to a normal retry")
	game._resolve_school("retry")
	check(game.school.level==1 and not game.school.supervised and game.state=="playing","Normal retry stays in the classroom")
	game.state="playing"
	game.elapsed=School.TIMES[1]
	game._tick(.016)
	check(game.school.reason=="bell" and not game.school.meeting_pending,"A timeout offers a direct retry")
	game._resolve_school("retry")

	game.held["right"]=true
	var classroom_frames := 0
	while game.state=="playing" and classroom_frames<420:
		classroom_frames+=1
		game._tick(1.0/60)
		if game._can_offer_note(): game._school_interact()
	check(game.school.reason=="note_delivered" and game.school.honor_pass,"A clean timed run reaches the first bench, passes the note, and earns the Honor Pass")
	game._school_choice(true)
	game._resolve_school("pass")
	check(game.school.level==2 and game.school.honor_pass,"Honor Pass carries into the finale")

	game._start_stage()
	check(not game.resistance_bar.visible and not game.control_rects.has("sneak"),"The street has no awareness meter or crouch input")
	game.elapsed=School.BIKE_TRAVEL*0.48
	var crossing: float = game._stage_width()*School.CROSSINGS[0]
	game.player.x=crossing
	game._tick(.016)
	check(game.school.stumble>0.0 and game.player.x<crossing-42.0 and game.state=="playing","A bicycle causes a recoverable stumble")
	game.elapsed=School.BIKE_PERIOD*20+2.0
	game.player.x=game._stage_width()*School.BUS_STOP
	for i in range(41): game._tick(.016)
	check(game.state=="school_result" and game.school.reason=="bus_stop","Walk home can end after a long delay")
	game._open_school_chat()
	check(game.state=="school_result","Offline Sharmila leaves written endings available")
	game.state="dialogue"
	game._apply_school_reply({"school_protocol":3,"reply":"Talk tomorrow?","addressed":[],"ending":"later"})
	check(game.school_resolution=="pass" and game.school.ending=="later","A valid Sharmila ending passes without a score gate")
	game._resolve_school("pass")
	check(game.state=="school_ending" and game.unlocked>=1,"Meeting at the bus stop unlocks college")
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
	game.school.meeting_pending=false
	game.school.supervised=false
	game._start_stage()
	var stealth_frames := 0
	game.held["right"]=true
	game.held["sneak"]=true
	while game.state=="playing" and stealth_frames<1700:
		stealth_frames+=1
		game._tick(1.0/60)
	check(game.state=="school_result" and game.school.outcome=="success","Before the Bell can be cleared with real patrol movement")
	game.school.level=School.Level.WALK_HOME
	game._start_stage()
	game.held["right"]=true
	for frame in range(1800):
		if game.state!="playing": break
		game._tick(1.0/60)
	check(game.state=="school_result" and game.school.reason=="bus_stop","The full street is passable after recovering from bicycle crossings")
	var legacy := ConfigFile.new()
	legacy.set_value("school","unlocked",2)
	legacy.set_value("school","checkpoint",1)
	legacy.set_value("school","repair",true)
	legacy.set_value("school","honor_pass",true)
	legacy.save(save_path)
	game._load_progress()
	check(game.school.level==School.Level.CLASSROOM and game.school.supervised and game.school.honor_pass and not game.school.meeting_pending,"Old repair and Honor Pass carry into the new classroom")
	game.qwen.cancel()
	DirAccess.remove_absolute(save_path)
	print("RESULT: %d checks, %d failures"%[checks,failed])
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
