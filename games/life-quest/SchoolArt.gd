extends RefCounted

# Rectangles trim the empty space in the original art while retaining natural proportions.
const HERO: Texture2D = preload("res://art/school-hero-v7.png")
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
const MASTER: Texture2D = preload("res://art/school-master-v7.png")
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
const PROPS: Texture2D = preload("res://art/school-props-v7.png")
const PROPS_FRAMES: Array[Rect2] = [
	Rect2(28, 166, 567, 389),
	Rect2(666, 175, 557, 366),
	Rect2(11, 770, 606, 392),
	Rect2(665, 644, 559, 557),
]
const STUDENTS: Texture2D = preload("res://art/school-students-v7.png")
const STUDENTS_FRAMES: Array[Rect2] = [
	Rect2(129, 17, 237, 414),
	Rect2(595, 22, 132, 409),
	Rect2(982, 24, 245, 405),
	Rect2(1459, 16, 154, 414),
	Rect2(130, 467, 237, 403),
	Rect2(594, 472, 151, 398),
	Rect2(984, 469, 250, 400),
	Rect2(1462, 464, 164, 406),
]
const HERO_ANCHORS := [0.53, 0.48, 0.44, 0.48, 0.51, 0.50, 0.49, 0.38]
const MASTER_ANCHORS := [0.48, 0.48, 0.48, 0.45, 0.50, 0.45, 0.45, 0.36]
const MASTER_HEIGHTS := [1.0, 0.94, 1.0, 1.01, 1.0, 1.0, 1.0, 1.0]
const PROP_WIDTHS := [224.0, 217.0, 218.0, 159.0]
const COVER_RADII := [65.0, 68.0, 65.0, 46.0]
const RUN := [1,2,3,2]
const CROUCH := [5,4,6,4]

static func hero_frame(moving: bool, ducked: bool, throwing: bool, step: int) -> int:
	if throwing: return 7
	if ducked: return CROUCH[step%4] if moving else 4
	return RUN[step%4] if moving else 0

static func master_frame(speaking: bool, receptive: bool, listening: bool, turning: bool, turn: float, alerted: bool, stride: int) -> int:
	if speaking: return 7 if receptive else 5
	if listening: return 6
	if turning:
		if turn < 0.22: return 5
		if turn < 0.78: return 4
		return 0
	if alerted: return 5
	return stride%4
