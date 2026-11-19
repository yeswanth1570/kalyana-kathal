extends RefCounted

# Rectangles trim the empty space in the original art while retaining natural proportions.
const HERO: Texture2D = preload("res://art/characters/school-hero-v7.png")
const HERO_FRAMES: Array[Rect2] = [
	Rect2(137, 15, 178, 428),
	Rect2(496, 29, 317, 414),
	Rect2(1008, 34, 186, 409),
	Rect2(1354, 34, 361, 409),
	Rect2(121, 554, 208, 319),
	Rect2(538, 558, 240, 314),
	Rect2(987, 560, 224, 312),
	Rect2(1421, 559, 295, 313),
]
const MASTER: Texture2D = preload("res://art/characters/school-master-v7.png")
const MASTER_FRAMES: Array[Rect2] = [
	Rect2(97, 17, 269, 419),
	Rect2(539, 56, 241, 379),
	Rect2(963, 23, 284, 413),
	Rect2(1415, 12, 254, 422),
	Rect2(106, 454, 248, 431),
	Rect2(539, 460, 253, 423),
	Rect2(971, 461, 253, 422),
	Rect2(1403, 460, 332, 423),
]
const PROPS: Texture2D = preload("res://art/props/school-props-v7.png")
const PROPS_FRAMES: Array[Rect2] = [
	Rect2(28, 166, 567, 389),
	Rect2(666, 175, 557, 366),
	Rect2(11, 770, 606, 392),
	Rect2(665, 644, 559, 557),
]
const RUN: Texture2D = preload("res://art/characters/school-run-v8.png")
const RUN_FRAMES: Array[Rect2] = [
	Rect2(83, 13, 250, 427), Rect2(512, 25, 245, 409),
	Rect2(995, 21, 199, 416), Rect2(1382, 16, 286, 398),
	Rect2(81, 457, 254, 423), Rect2(513, 471, 246, 405),
	Rect2(982, 465, 217, 413), Rect2(1383, 459, 283, 392),
]
const CROUCH: Texture2D = preload("res://art/characters/school-crouch-v8.png")
const CROUCH_FRAMES: Array[Rect2] = [
	Rect2(79, 36, 302, 383), Rect2(525, 36, 259, 380),
	Rect2(971, 36, 257, 380), Rect2(1388, 36, 331, 379),
	Rect2(70, 480, 271, 378), Rect2(525, 481, 259, 378),
	Rect2(970, 480, 258, 378), Rect2(1364, 481, 352, 376),
]
const REACTIONS: Texture2D = preload("res://art/characters/school-reactions-v8.png")
const TRANSITION_FRAMES: Array[Rect2] = [
	Rect2(546, 23, 206, 417), Rect2(986, 78, 222, 362), Rect2(1422, 143, 245, 297),
]
const HEAD_FRAMES: Array[Rect2] = [
	Rect2(83, 508, 294, 326), Rect2(528, 507, 295, 327),
	Rect2(970, 504, 293, 329), Rect2(1412, 507, 292, 327),
]
const STUDENTS: Texture2D = preload("res://art/characters/school-students-v8.png")
const STUDENTS_FRAMES: Array[Rect2] = [
	Rect2(74, 15, 199, 337), Rect2(478, 15, 116, 336), Rect2(839, 15, 123, 336),
	Rect2(68, 378, 214, 333), Rect2(478, 378, 133, 334), Rect2(840, 378, 136, 334),
	Rect2(80, 738, 208, 339), Rect2(478, 741, 123, 337), Rect2(847, 739, 135, 338),
	Rect2(73, 1103, 225, 336), Rect2(478, 1104, 127, 335), Rect2(846, 1103, 137, 336),
]
const RUN_ANCHORS := [0.55, 0.56, 0.41, 0.57, 0.55, 0.55, 0.44, 0.58]
const CROUCH_ANCHORS := [0.42, 0.48, 0.46, 0.38, 0.50, 0.49, 0.49, 0.40]
const TRANSITION_ANCHORS := [0.48, 0.48, 0.48]
const STUDENT_ANCHORS := [0.49, 0.57, 0.57, 0.50, 0.50, 0.51, 0.47, 0.56, 0.50, 0.48, 0.54, 0.50]
# Horizontal inset, neckline split, and width of the matching reaction head.
const CROUCH_HEADS: Array[Vector3] = [
	Vector3(105, 137, 154), Vector3(105, 137, 154),
	Vector3(100, 137, 154), Vector3(129, 137, 154),
	Vector3(114, 137, 154), Vector3(104, 137, 154),
	Vector3(97, 137, 154), Vector3(150, 137, 154),
]
const MASTER_ANCHORS := [0.48, 0.48, 0.48, 0.45, 0.50, 0.45, 0.45, 0.36]
const MASTER_HEIGHTS := [1.0, 0.94, 1.0, 1.01, 1.0, 1.0, 1.0, 1.0]
const PROP_WIDTHS := [224.0, 217.0, 218.0, 159.0]
const COVER_RADII := [65.0, 68.0, 65.0, 46.0]

static func master_frame(speaking: bool, receptive: bool, listening: bool, turning: bool, turn: float, alerted: bool, stride: int) -> int:
	if speaking: return 7 if receptive else 5
	if listening: return 6
	if turning:
		if turn < 0.22: return 5
		if turn < 0.78: return 4
		return 0
	if alerted: return 5
	return stride%4
