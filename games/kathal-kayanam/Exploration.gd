extends RefCounted

const SIZE := Vector2(1000, 420)
const BOUNDS := Rect2(36, 106, 928, 272)
const START := Vector2(118, 323)
const INTERACT_RANGE := 76.0
const CELL := 20
const SCENES := [
	["School approach", "Return the page", "Murugan catches a page from Sharmila’s notebook. Sundaram’s whistle cuts through the hall.", Vector2(852, 173), Rect2(411, 206, 178, 64), Rect2(679, 292, 115, 67)],
	["College canteen", "Read the fest board", "Sharmila is helping with the cultural fest. Annachi’s canteen is already buzzing.", Vector2(846, 154), Rect2(402, 207, 168, 70), Rect2(626, 294, 128, 60)],
	["OMR Tech Park", "Review the handover", "Murugan checks the release and prepares a handover before asking Karthik to leave early.", Vector2(824, 192), Rect2(351, 167, 168, 79), Rect2(601, 293, 148, 62)],
	["Sharmila’s home", "Go to the front door", "Sharmila’s parents have invited Murugan in. The smell of filter coffee drifts through the doorway.", Vector2(864, 152), Rect2(437, 208, 154, 74), Rect2(681, 293, 130, 57)],
	["Wedding mandapam", "Check on the garlands", "The guests have arrived, and the garlands are missing. Murugan goes to see what happened.", Vector2(839, 173), Rect2(379, 185, 182, 81), Rect2(636, 298, 142, 58)],
]

var act := 0
var position := START
var facing := 1.0
var stride := 0.0
var moving := false
var sneaking := false
var path := PackedVector2Array()
var destination := Vector2.INF
var grid := AStarGrid2D.new()

func begin(index: int) -> void:
	act = index
	position = START
	facing = 1.0
	stride = 0.0
	clear_input()
	grid.region = Rect2i(0, 0, int(SIZE.x) / CELL, int(SIZE.y) / CELL)
	grid.cell_size = Vector2.ONE * CELL
	grid.offset = Vector2.ONE * CELL / 2
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(grid.region.size.y):
		for x in range(grid.region.size.x):
			var cell := Vector2i(x, y)
			grid.set_point_solid(cell, not walkable(grid.get_point_position(cell), 13.0))

func descriptor() -> Array:
	return SCENES[act]

func target() -> Vector2:
	return SCENES[act][3]

func near_target() -> bool:
	return position.distance_to(target()) <= INTERACT_RANGE

func walkable(point: Vector2, radius: float = 10.0) -> bool:
	return BOUNDS.has_point(point) and not (SCENES[act][4] as Rect2).grow(radius).has_point(point) and not (SCENES[act][5] as Rect2).grow(radius).has_point(point)

func clear_input() -> void:
	path.clear()
	destination = Vector2.INF
	moving = false
	sneaking = false

func walk_to(point: Vector2) -> void:
	path.clear()
	destination = Vector2.INF
	if not walkable(point): return
	var from := _nearest_cell(position)
	var to := _nearest_cell(point)
	if not grid.region.has_point(from) or not grid.region.has_point(to): return
	path = grid.get_point_path(from, to)
	if not path.is_empty(): destination = point

func _nearest_cell(point: Vector2) -> Vector2i:
	var candidate := Vector2i((point / CELL).floor())
	var nearest := Vector2i(-1, -1)
	var distance := INF
	for y in range(candidate.y - 1, candidate.y + 2):
		for x in range(candidate.x - 1, candidate.x + 2):
			var cell := Vector2i(x, y)
			if not grid.region.has_point(cell) or grid.is_point_solid(cell): continue
			var next_distance := point.distance_squared_to(grid.get_point_position(cell))
			if next_distance < distance:
				distance = next_distance
				nearest = cell
	return nearest

func step(axis: Vector2, run: bool, sneak: bool, dt: float) -> void:
	sneaking = sneak
	var speed := 83.0 if sneak else 249.0 if run else 151.0
	var before := position
	if axis.length_squared() > 0.0001:
		path.clear()
		destination = Vector2.INF
		_move(axis.limit_length() * speed * dt)
	elif destination != Vector2.INF:
		while not path.is_empty() and position.distance_squared_to(path[0]) < 4.0:
			path.remove_at(0)
		var next := destination if path.is_empty() else path[0]
		_move(position.direction_to(next) * minf(speed * dt, position.distance_to(next)))
		if position.distance_squared_to(destination) < 4.0 or position.is_equal_approx(before):
			path.clear()
			destination = Vector2.INF
	moving = not before.is_equal_approx(position)
	if moving:
		stride += before.distance_to(position)
		if absf(position.x - before.x) > 0.05: facing = signf(position.x - before.x)

func _move(offset: Vector2) -> void:
	var x := position + Vector2(offset.x, 0)
	if walkable(x): position.x = x.x
	var y := position + Vector2(0, offset.y)
	if walkable(y): position.y = y.y
