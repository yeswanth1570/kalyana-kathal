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
	game._start_stage()
	await capture("stealth-portrait")
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
	game.held["hide"]=true
	game._tick(.016)
	game._update_hud()
	await capture("hidden-portrait")
	game._use_activity()
	await capture("grades-portrait")
	root.size=Vector2i(1100,700)
	await process_frame
	game._resize()
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
