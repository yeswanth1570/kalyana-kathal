extends SceneTree
const SchoolArt = preload("res://SchoolArt.gd")
const SchoolScenes = preload("res://SchoolScenes.gd")
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
	for item in [["hero_sheet-v2",4,4],["cast_sheet-v2",3,2],["hero-run-alpha-v3",4,4],["master-walk-v3",2,2],["reaction-faces-v5",2,2],["school-poses-v6",4,2],["school-master-v7",4,2],["school-hero-v7",4,2],["school-props-v7",2,2],["school-students-v7",4,2]]:
		var image := (load("res://art/"+item[0]+".png") as Texture2D).get_image()
		check(image.detect_alpha()!=Image.ALPHA_NONE,item[0]+" has genuine alpha")
		check(image.get_pixel(0,0).a<0.05,item[0]+" has a transparent outer corner")
		var cell := Vector2i(image.get_width()/item[1],image.get_height()/item[2])
		for y in range(item[2]):
			for x in range(item[1]):
				var frame := image.get_region(Rect2i(Vector2i(x,y)*cell,cell))
				var bounds := frame.get_used_rect()
				check(bounds.size.x>cell.x*.2 and bounds.size.y>cell.y*.5,"%s frame %d,%d is not empty"%[item[0],x,y])
	_check_school_atlas("School run",SchoolArt.RUN,SchoolArt.RUN_FRAMES,8)
	_check_school_atlas("School crouch-walk",SchoolArt.CROUCH,SchoolArt.CROUCH_FRAMES,8)
	_check_school_atlas("School crouch transitions",SchoolArt.REACTIONS,SchoolArt.TRANSITION_FRAMES,3)
	_check_school_atlas("School expressions",SchoolArt.REACTIONS,SchoolArt.HEAD_FRAMES,4)
	_check_school_atlas("School background students",SchoolArt.STUDENTS,SchoolArt.STUDENTS_FRAMES,12)
	_check_school_atlas("Classroom cast",SchoolScenes.CAST,SchoolScenes.CAST_FRAMES,6)
	_check_school_atlas("Street sprites",SchoolScenes.STREET,SchoolScenes.STREET_FRAMES,3)
	for texture in [SchoolScenes.CLASSROOM,SchoolScenes.HOME]:
		check(texture.get_width()>=1600 and texture.get_height()>=900,"New school backdrop has full resolution")
	print("ART RESULT: %d checks, %d failures"%[checks,failed])
	quit(1 if failed else 0)

func _check_school_atlas(label: String, texture: Texture2D, regions: Array[Rect2], count: int) -> void:
	var image := texture.get_image()
	check(image.get_pixel(0,0).a < 0.05,label+" leaves the sheet background transparent")
	var hashes := {}
	for region in regions:
		var frame := image.get_region(Rect2i(region))
		if not frame.get_used_rect().has_area():
			continue
		hashes[hash(frame.get_data())] = true
	check(hashes.size() == count,label+" has %d distinct, populated poses"%count)
