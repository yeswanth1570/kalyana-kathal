extends RefCounted

const School = preload("res://SchoolChapter.gd")
const CLASSROOM: Texture2D = preload("res://art/stages/classroom-v9.png")
const HOME: Texture2D = preload("res://art/stages/walk-home-v9.png")
const CAST: Texture2D = preload("res://art/characters/school-cast-v9.png")
const STREET: Texture2D = preload("res://art/props/street-props-v9.png")

const CAST_FRAMES: Array[Rect2] = [
	Rect2(179,9,184,495), Rect2(674,10,166,494), Rect2(1168,9,224,496),
	Rect2(146,636,253,381), Rect2(642,520,207,497), Rect2(1173,514,149,503),
]
const STREET_FRAMES: Array[Rect2] = [
	Rect2(29,42,666,650), Rect2(753,41,666,651), Rect2(1480,40,660,664),
]

static func background(level: int) -> Texture2D:
	return CLASSROOM if level == School.Level.CLASSROOM else HOME

static func teacher_frame(gaze: int) -> int:
	match gaze:
		School.Gaze.WRITING: return 0
		School.Gaze.WATCHING: return 2
		_: return 1
