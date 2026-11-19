extends RefCounted

enum Watch { PATROL, SUSPICIOUS, CAUGHT }

const PATH := [0.056,0.208,0.354,0.50,0.645,0.788,0.915,0.97]
const TYPES := [2,0,1,2,0,1,2,-1] # Door, planter, bench, or gate.
const DEPTH := [-52.0,8.0,-8.0,-52.0,12.0,-6.0,-52.0,-8.0]
const PATCHES := [0.425,0.718]
const SIGHT := 325.0
const CLOSE := 100.0
const HEARING := 348.0
const GRACE := 1.2
const RIPPLE := 0.56
const RECOVERY := 0.68
const TURN_DURATION := 0.72
const END := 7

var target := -1
var checkpoint := 0
var resting := 0
var sprint := false
var watch := Watch.PATROL
var grace := 0.0
var recovery := 0.0
var ripple := 0.0
var noise := Vector2.ZERO
var rustle := Vector2.ZERO
var rustle_time := 0.0
var patrol_window := false
var origin := Vector2.ZERO
var vault_lift := 0.0
var settle := 0.0
var bell_time := 0.0
var bell_cooldown := 0.0
var bell_goal := 0.0
var patch_used := -1
var splash := false
var turn_left := 0.0
var turn_from := 1.0
var turn_to := 1.0

static func x_at(node: int, width: float) -> float:
	return width*float(PATH[node])

static func is_hard(node: int) -> bool:
	return node >= 0 and node < END and TYPES[node] == 2

static func reachable(node: int, origin_x: float, width: float) -> bool:
	return node >= 0 and node <= END and absf(x_at(node,width)-origin_x)<=maxf(430.0,width*0.235)

static func concealment(node: int, crouched: bool, guard_distance: float) -> bool:
	return crouched and node >= 0 and node < END and (is_hard(node) or guard_distance > CLOSE)

static func turn_pose(remaining: float, reduced: bool) -> int:
	var t := clampf(1.0-remaining/TURN_DURATION,0.0,1.0)
	if reduced:
		if t < 0.28: return 0
		return 3 if t < 0.72 else 7
	return mini(int(t*8.0),7)
