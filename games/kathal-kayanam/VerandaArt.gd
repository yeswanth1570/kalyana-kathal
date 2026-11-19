extends RefCounted

const WALL: Texture2D = preload("res://art/stages/veranda-depth-v12.png")
const COVER: Texture2D = preload("res://art/props/veranda-cover-v12.png")
const FOREGROUND: Texture2D = preload("res://art/props/veranda-foreground-v12.png")
const GUARD: Texture2D = preload("res://art/characters/veranda-sundaram-v12.png")
const LIFE: Texture2D = preload("res://art/characters/veranda-life-v12.png")
const TURN: Texture2D = preload("res://art/characters/veranda-turn-v12.png")

const COVER_FRAMES: Array[Rect2] = [
	Rect2(58,29,563,677), Rect2(727,194,716,500), Rect2(1571,6,475,709),
]

# Apertures in the painted wall. The interior samples track the slow layer.
const WINDOWS: Array[Rect2] = [
	Rect2(223,282,446,367), Rect2(996,283,457,365),
]
const FOREGROUND_FRAMES: Array[Rect2] = [
	Rect2(250,0,222,724), Rect2(724,232,721,307), Rect2(1635,54,537,663),
]
const GUARD_FRAMES: Array[Rect2] = [
	Rect2(12,94,545,614), Rect2(582,61,434,650), Rect2(1130,26,445,684), Rect2(1656,46,513,664),
]
const LIFE_FRAMES: Array[Rect2] = [
	Rect2(36,35,464,660), Rect2(543,38,555,649), Rect2(1131,79,488,597), Rect2(1653,79,507,597),
]
const TURN_REFERENCE_HEIGHT := 439.0
const TURN_FRAMES: Array[Rect2] = [
	Rect2(99,8,249,435), Rect2(532,7,265,436), Rect2(962,7,272,436), Rect2(1395,8,314,435),
	Rect2(66,449,341,438), Rect2(509,446,327,441), Rect2(989,446,242,441), Rect2(1443,446,169,441),
]

static func foreground_frame(index: int) -> Rect2:
	return FOREGROUND_FRAMES[index]

static func life_frame(index: int) -> Rect2:
	return LIFE_FRAMES[index]
