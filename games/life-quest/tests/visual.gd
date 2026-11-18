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
	game._open_dialogue()
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
	game._open_dialogue()
	await capture("dialogue-portrait")
	game.queue_free()
	await process_frame
	quit()
