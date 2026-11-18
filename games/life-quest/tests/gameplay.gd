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
	var save_path: String = ProjectSettings.globalize_path("user://life-quest.cfg")
	var had_save := FileAccess.file_exists(save_path)
	var saved_bytes := FileAccess.get_file_as_bytes(save_path) if had_save else PackedByteArray()
	game.sound_on = false
	game.gentle = true
	game.auto_fire = false
	check(Story.ACTS.size()==5,"Five complete story acts")
	check(game.state=="title","Starts safely on title, no attacks")
	game.stage=0
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
	check(game.resistance<100,"Projectile hit reduces resistance")
	game.resistance=70
	game._tick(0.016)
	check(game.state=="dialogue" and game.hazards.is_empty(),"70 percent opens and freezes conversation")
	game._choose(0)
	check(game.approval==50 and game.state=="feedback","First good reply awards trust")
	game._continue_after_reply()
	check(game.phase==1 and game.state=="playing","Conversation resumes at phase two")
	game.resistance=40
	game._tick(0.016)
	check(game.state=="dialogue","40 percent opens second conversation")
	game._choose(0)
	game._continue_after_reply()
	game.resistance=12
	game._tick(0.016)
	game._choose(0)
	game._continue_after_reply()
	check(game.state=="clear" and game.unlocked>=1,"Three good conversations clear and unlock next act")
	check(game.approval==100,"Trust clamps to 100")
	# Weak dialogue must provide a recovery loop, not a dead boss softlock.
	game._start_stage()
	game.phase=2
	game.approval=0
	game.state="dialogue"
	game._choose(2)
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
			var words: String=Story.ACTS[act].talks[p].clues[0]
			var evaluation := Story.evaluate("I promise "+words,act,p)
			check(evaluation.score>=20,"Act %d phase %d local custom reply"%[act+1,p+1])
		game._start_stage()
		for p in range(3):
			game.resistance=game.THRESHOLDS[p]
			game._tick(.016)
			game._choose(0)
			game._continue_after_reply()
		check(game.state=="clear","Act %d is completable"%(act+1))
	check(game.completed,"Final act saves completion")
	check(Story.evaluate("you owe me respect",1,0).score<0,"Negative intent overrides positive keywords")
	check(Story.evaluate("hi",0,0).score==0,"Empty or short custom replies are rejected")
	# Advance real projectile movement and collision at 60 FPS through a full act.
	game.stage=0
	game.auto_fire=true
	game._start_stage()
	var simulation_frames := 0
	while game.state != "clear" and simulation_frames < 9000:
		simulation_frames += 1
		if game.state=="playing":
			game.invincible=1 # Isolate projectile and phase timing.
			game._tick(1.0/60.0)
		elif game.state=="dialogue": game._choose(0)
		elif game.state=="feedback": game._continue_after_reply()
		else: break
	check(game.state=="clear","Real 60 FPS projectile simulation clears all three shield phases")
	check(simulation_frames>500 and simulation_frames<2500,"Combat finishes within intended timing")
	if had_save:
		var file := FileAccess.open(save_path,FileAccess.WRITE)
		file.store_buffer(saved_bytes)
	else:
		DirAccess.remove_absolute(save_path)
	print("RESULT: %d checks, %d failures"%[checks,failed])
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
