extends RefCounted

enum Mood { FOCUSED, WORRIED, ALARMED, RELIEVED }

# Distances in world pixels. A full cycle takes two steps.
const RUN_STRIDE := 160.0
const CROUCH_STRIDE := 104.0
const STEPS := 8
const RELIEF_SECONDS := 0.5

# Thresholds in the coordinates of school-v2.png, from the painted door jambs
# and the opening onto the courtyard. Feet leave the wall before crossing.
const NEAR_DOOR := Vector2(0.251, 0.735)
const MIDDLE_DOOR := Vector2(0.454, 0.700)
const FAR_DOOR := Vector2(0.596, 0.675)
const COURTYARD_ARCH := Vector2(0.754, 0.656)

static func advance_step(phase: float, distance: float, crouching: bool) -> float:
	return fposmod(phase + distance / (CROUCH_STRIDE if crouching else RUN_STRIDE), 1.0)

static func step_index(phase: float) -> int:
	return int(fposmod(phase, 1.0) * STEPS)

static func transition_index(blend: float, reduced: bool) -> int:
	if blend <= 0.0 or blend >= 1.0:
		return -1
	if reduced:
		return 1
	return mini(int(blend * 3.0), 2)

static func mood_after(awareness: float, previous: int, relief_left: float) -> int:
	if relief_left > 0.0:
		return Mood.RELIEVED
	if awareness >= 70.0 or (previous == Mood.ALARMED and awareness >= 60.0):
		return Mood.ALARMED
	if awareness >= 35.0 or (previous == Mood.WORRIED and awareness >= 25.0):
		return Mood.WORRIED
	return Mood.FOCUSED

static func student_progress(index: int, elapsed: float) -> float:
	var duration := 10.6 if index == 0 else 12.8
	var offset := 2.4 if index == 0 else 8.1
	return fposmod(elapsed + offset, duration + 2.3) / duration

static func student_feet(index: int, progress: float) -> Vector2:
	var start := NEAR_DOOR if index == 0 else COURTYARD_ARCH
	var finish := FAR_DOOR if index == 0 else MIDDLE_DOOR
	# Perspective compresses movement away from the camera and opens it up
	# in the reverse direction. Screen coordinates come from the painting.
	var depth := 1.0 - progress if index == 0 else progress
	var projected := 1.0 - (0.78 * depth + 0.22 * depth * depth) if index == 0 else 0.78 * depth + 0.22 * depth * depth
	var feet := start.lerp(finish, projected)
	feet.y += (0.033 if index == 0 else 0.026) * smoothstep(0.0, 0.17, progress) * (1.0 - smoothstep(0.81, 1.0, progress))
	return feet

static func student_scale(feet: Vector2) -> float:
	return lerpf(0.45, 0.60, clampf(inverse_lerp(COURTYARD_ARCH.x, NEAR_DOOR.x, feet.x), 0.0, 1.0))
