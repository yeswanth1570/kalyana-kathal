extends SceneTree

var game: Node

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/"+name+".png")
	print("CAPTURE ",name)

func run() -> void:
	root.content_scale_size=Vector2i(1100,700)
	root.size=Vector2i(1100,700)
	game=load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound_on=false
	await capture("title-landscape")
	game._show_map()
	await capture("map-landscape")
	game.stage=1
	game._start_stage()
	await capture("college-landscape")
	game.chat_messages.assign([{"role":"assistant","content":"Tell me about your idea for the college festival."}])
	game._show_dialogue()
	await capture("dialogue-landscape")
	for i in [0,2,3,4]:
		game.stage=i
		game._start_stage()
		await capture("act-%d-landscape"%(i+1))
	root.size=Vector2i(440,900)
	await process_frame
	game._resize()
	game._show_title()
	await capture("title-portrait")
	game._show_settings()
	await capture("settings-portrait")
	game._show_map()
	await capture("map-portrait")
	game.stage=1
	game._start_stage()
	await capture("college-portrait")
	game.chat_messages.assign([{"role":"assistant","content":"Tell me about your idea for the college festival."}])
	game._show_dialogue()
	await capture("dialogue-portrait")
	game.stage=0
	game.school.level=0
	game._show_intro()
	await create_timer(0.45).timeout
	await capture("school-opening-portrait")
	game.school.level=2
	game._start_stage()
	await capture("stealth-portrait")
	game.elapsed=0.4
	game._tick(.016)
	await capture("school-crowd-portrait")
	game.master_turn=0.60
	game.school.turn_face=-1
	await capture("school-pivot-portrait")
	game.master_turn=0.0

	game.held["sneak"]=true
	game.held["right"]=true
	for i in range(10):
		game._tick(.016)
	await capture("sneak-stride-portrait")
	for mood in range(4):
		game.school_mood=mood
		await capture("school-face-%d-portrait"%mood)
	for i in range(8):
		game.school_step_phase=float(i)/8.0
		await capture("school-crouch-%02d-portrait"%i)
	game.held.clear()
	game.player.x=game._stage_width()-110
	game.master_x=game.player.x-120
	game.awareness=43.0
	game.face_frame=0
	game.face_time=0.5
	game._follow_camera(1.0)
	game._update_hud()
	await capture("scroll-reaction-portrait")
	game._start_stage()
	game.player.x=game._cover_positions()[1]
	game.master_x=game.player.x+260.0
	game.awareness=44.0
	game.held["hide"]=true
	for i in range(10):
		game._tick(.016)
	game._update_hud()
	await capture("hidden-portrait")
	game._end_school("failure","caught")
	await capture("school-caught-portrait")
	game._school_choice(false)
	await capture("school-repair-result-portrait")
	game.school.level=1
	game._start_stage()
	game.player.x=game._school_desks()[0]
	game._update_hud()
	await capture("school-notebooks-portrait")
	root.size=Vector2i(360,740)
	await process_frame
	game._resize()
	game.school.level=0
	game._start_stage()
	game.elapsed=0.5
	await capture("school-crowd-compact")
	game.player.x=game._stage_width()-110.0
	game._follow_camera(1.0)
	game.elapsed=1.8
	await capture("school-crowd-scroll-compact")
	root.size=Vector2i(1100,700)
	await process_frame
	game._resize()
	game._start_stage()
	game.elapsed=0.7
	await capture("school-crowd-landscape")
	game.stage=1
	game._start_stage()
	game.invincible=0
	game.held["right"]=true
	for i in range(8):
		game._tick(.05)
		await capture("motion-run-%02d"%i)
	game._jump()
	game._tick(.12)
	await capture("motion-jump")
	game._dash()
	await capture("motion-dash")
	game._fire()
	await capture("motion-throw")
	game.windup=.5
	await capture("attack-warning")
	game._impact(game.boss_position()+Vector2(-35,-67),"POW!")
	game.boss_flash=0.1
	await capture("impact-landscape")
	game.queue_free()
	await process_frame
	quit()
