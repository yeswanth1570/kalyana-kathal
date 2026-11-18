extends SceneTree
var failed := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok:print("PASS ",message)
	else:
		failed+=1
		push_error(message)
func _initialize() -> void:
	for name in ["cover","school","college","office","family","wedding"]:
		var image := (load("res://art/"+name+"-v2.png") as Texture2D).get_image()
		check(image!=null and image.get_width()>=1600 and image.get_height()>=900,name+" production background exists")
	for item in [["hero_sheet-v2",4,4],["cast_sheet-v2",3,2],["hero-run-alpha-v3",4,4],["master-walk-v3",2,2],["reaction-faces-v5",2,2]]:
		var image := (load("res://art/"+item[0]+".png") as Texture2D).get_image()
		check(image.detect_alpha()!=Image.ALPHA_NONE,item[0]+" has genuine alpha")
		check(image.get_pixel(0,0).a<0.05,item[0]+" has a transparent outer corner")
		var cell := Vector2i(image.get_width()/item[1],image.get_height()/item[2])
		for y in range(item[2]):
			for x in range(item[1]):
				var frame := image.get_region(Rect2i(Vector2i(x,y)*cell,cell))
				var bounds := frame.get_used_rect()
				check(bounds.size.x>cell.x*.2 and bounds.size.y>cell.y*.5,"%s frame %d,%d is not empty"%[item[0],x,y])
	print("ART RESULT: %d checks, %d failures"%[checks,failed])
	quit(1 if failed else 0)
