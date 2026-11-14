extends Node2D

const W = 1024.0
const H = 600.0
const GROUND = 475.0
var player := Vector2(175, GROUND)
var hp := 3
var boss_hp := 100.0
var approval := 50.0
var shots: Array[Vector2] = []
var hazards: Array[Vector2] = []
var hazard_clock := 0.0
var shot_clock := 0.0
var dialogue := false
var result := ""
var age := 0.0
var invulnerable := 0.0
var dash_time := 0.0
var jump_v := 0.0
var jump_offset := 0.0
var font: Font
var touch_actions: Dictionary = {}

const CONTROL_LEFT := Rect2(35, 468, 92, 112)
const CONTROL_RIGHT := Rect2(132, 468, 92, 112)
const CONTROL_DASH := Rect2(665, 468, 86, 112)
const CONTROL_JUMP := Rect2(756, 458, 100, 122)
const CONTROL_THROW := Rect2(862, 468, 120, 112)
const CONTROL_TALK := Rect2(438, 433, 148, 70)
const CONTROL_CHOICE_1 := Rect2(140, 239, 744, 42)
const CONTROL_CHOICE_2 := Rect2(140, 281, 744, 42)
const CONTROL_CHOICE_3 := Rect2(140, 323, 744, 42)
const CONTROL_RETRY := Rect2(330, 282, 364, 46)

func _ready() -> void:
    font = ThemeDB.fallback_font
    get_window().title = "Kalyana Kathal — College Corridor"
    get_viewport().size_changed.connect(_on_viewport_size_changed)
    queue_redraw()

func _on_viewport_size_changed() -> void:
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    invulnerable = maxf(0.0, invulnerable - delta)
    dash_time = maxf(0.0, dash_time - delta)
    if not dialogue and result == "":
        var axis := 0.0
        if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or _touch_held("left"): axis = -1.0
        if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or _touch_held("right"): axis = 1.0
        player.x = clampf(player.x + axis * (230.0 if dash_time <= 0 else 480.0) * delta, 45, 950)
        if jump_offset < 0:
            jump_v += 1000 * delta
            jump_offset += jump_v * delta
            if jump_offset > 0: jump_offset = 0; jump_v = 0
        if Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_X) or _touch_held("throw"):
            shot_clock -= delta
            if shot_clock <= 0:
                shots.append(Vector2(player.x + 35, player.y - 45 + jump_offset))
                shot_clock = 0.24
        hazard_clock -= delta
        if hazard_clock <= 0:
            hazards.append(Vector2(840, GROUND - 28))
            hazard_clock = randf_range(0.95, 1.55)
        for s in shots: s.x += 510 * delta
        for h in hazards: h.x -= 270 * delta
        for i in range(shots.size()-1, -1, -1):
            if shots[i].x > 780:
                boss_hp = maxf(0, boss_hp - 4)
                shots.remove_at(i)
        for i in range(hazards.size()-1, -1, -1):
            var h = hazards[i]
            if absf(h.x - player.x) < 28 and absf((player.y + jump_offset) - GROUND) < 45 and invulnerable <= 0:
                hp -= 1; invulnerable = 1.0; hazards.remove_at(i)
                if hp <= 0: result = "The corridor got the better of you. Try again?"
            elif h.x < 20: hazards.remove_at(i)
        if boss_hp <= 70 and approval == 50: _open_dialogue()
    queue_redraw()

func _open_dialogue() -> void:
    dialogue = true

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if dialogue:
            if event.keycode == KEY_1: _choose(1)
            elif event.keycode == KEY_2: _choose(2)
            elif event.keycode == KEY_3: _choose(3)
        elif result != "":
            if event.keycode == KEY_ENTER:
                _reset_run()
        elif event.keycode == KEY_SPACE or event.keycode == KEY_W:
            if jump_offset == 0: jump_v = -410.0
        elif event.keycode == KEY_SHIFT:
            dash_time = 0.23; invulnerable = 0.28
        elif event.keycode == KEY_R:
            _open_dialogue()

func _input(event: InputEvent) -> void:
    var pointer_index := -1
    var pointer_position := Vector2.ZERO
    var pressed := false
    var released := false

    if event is InputEventScreenTouch:
        pointer_index = event.index
        pointer_position = event.position
        pressed = event.pressed
        released = not event.pressed
    elif event is InputEventScreenDrag:
        pointer_index = event.index
        pointer_position = event.position
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        pointer_position = event.position
        pressed = event.pressed
        released = not event.pressed
    elif event is InputEventMouseMotion and touch_actions.has(-1):
        pointer_position = event.position
        pointer_index = -1
    else:
        return

    if released:
        touch_actions.erase(pointer_index)
        return

    var action := _touch_action_at(pointer_position)
    if pointer_index >= 0 or pressed:
        touch_actions[pointer_index] = action
    if not pressed:
        return

    if action.begins_with("choice:"):
        _choose(int(action.trim_prefix("choice:")))
    elif action == "retry":
        _reset_run()
    elif action == "jump" and not dialogue and result == "" and jump_offset == 0:
        jump_v = -410.0
    elif action == "dash" and not dialogue and result == "":
        dash_time = 0.23
        invulnerable = 0.28
    elif action == "talk" and not dialogue and result == "":
        _open_dialogue()

func _touch_action_at(position: Vector2) -> String:
    if dialogue:
        if CONTROL_CHOICE_1.has_point(position): return "choice:1"
        if CONTROL_CHOICE_2.has_point(position): return "choice:2"
        if CONTROL_CHOICE_3.has_point(position): return "choice:3"
        return ""
    if result != "":
        return "retry" if CONTROL_RETRY.has_point(position) else ""
    if CONTROL_LEFT.has_point(position): return "left"
    if CONTROL_RIGHT.has_point(position): return "right"
    if CONTROL_DASH.has_point(position): return "dash"
    if CONTROL_JUMP.has_point(position): return "jump"
    if CONTROL_THROW.has_point(position): return "throw"
    if CONTROL_TALK.has_point(position): return "talk"
    return ""

func _touch_held(action: String) -> bool:
    return action in touch_actions.values()

func _reset_run() -> void:
    hp = 3
    boss_hp = 100
    approval = 50
    shots.clear()
    hazards.clear()
    player.x = 175
    result = ""
func _choose(n: int) -> void:
    dialogue = false
    if n == 1: approval += 26
    elif n == 2: approval += 17
    else: approval -= 8
    if approval >= 75: result = "Sharmila smiles. Corridor cleared! ♥"
    elif approval < 45: result = "Aiyo! That made things awkward. Press Enter to retry."
    else: boss_hp = minf(100, boss_hp + 18)

func _text(s: String, x: float, y: float, size: int, color := Color("fff1d2"), align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
    draw_string(font, Vector2(x, y), s, align, -1, size, color)

func _draw() -> void:
    # Warm, printed-paper palette and corridor perspective
    draw_rect(Rect2(0,0,W,H), Color("d7c4a0"))
    draw_rect(Rect2(0,0,W,390), Color("d9cfba"))
    draw_rect(Rect2(0,390,W,210), Color("8b7962"))
    draw_rect(Rect2(0,392,W,8), Color("4d4034"))
    for x in range(0, 1024, 128):
        draw_line(Vector2(x,0), Vector2(512 + (x-512)*0.48,390), Color("9a8a73"), 3)
    for y in [72,145,218,291,360]: draw_line(Vector2(0,y), Vector2(W,y), Color(0.47,0.4,0.32,0.2), 2)
    # classroom doors, posters, notice board
    for x in [45, 275, 705, 920]:
        draw_rect(Rect2(x,145,118,245), Color("846b52")); draw_rect(Rect2(x+7,152,104,231), Color("b69d78")); draw_rect(Rect2(x+15,160,88,213), Color("9e8564"))
        draw_circle(Vector2(x+96,280), 4, Color("e4c87e"))
    draw_rect(Rect2(365,105,285,155), Color("604b37")); draw_rect(Rect2(373,113,269,139), Color("eadab7"))
    _text("NOTICE BOARD", 414, 139, 23, Color("57432e"))
    _text("CULTURAL FEST • TODAY", 402, 173, 16, Color("8e4d39"))
    _text("ATTENDANCE: 87%", 405, 204, 16, Color("58634d"))
    # sketched paper scraps
    for i in range(7):
        var x = 35 + i*151
        draw_colored_polygon(PackedVector2Array([Vector2(x,430),Vector2(x+36,424),Vector2(x+48,438),Vector2(x+9,444)]), Color("e6dcc4"))
    # boss Sharmila in a school/campus uniform
    draw_oval(Vector2(790,GROUND-70), Vector2(33,46), Color("8d4b38"))
    draw_circle(Vector2(790,GROUND-137), 28, Color("c9855b"))
    draw_arc(Vector2(790,GROUND-140), 30, PI, TAU, 24, Color("30271f"), 12)
    draw_line(Vector2(778,GROUND-139),Vector2(785,GROUND-137),Color("30221b"),3); draw_line(Vector2(795,GROUND-137),Vector2(803,GROUND-139),Color("30221b"),3)
    draw_line(Vector2(780,GROUND-91),Vector2(757,GROUND-49),Color("60463a"),8); draw_line(Vector2(800,GROUND-91),Vector2(821,GROUND-52),Color("60463a"),8)
    draw_line(Vector2(777,GROUND-106),Vector2(746,GROUND-89),Color("c9855b"),9); draw_line(Vector2(804,GROUND-106),Vector2(830,GROUND-99),Color("c9855b"),9)
    # protagonist
    var py = player.y + jump_offset
    draw_oval(Vector2(player.x,GROUND+4), Vector2(25,7), Color(0,0,0,0.24))
    var blink := invulnerable > 0 and int(age*14)%2 == 0
    if not blink:
        draw_colored_polygon(PackedVector2Array([Vector2(player.x-20,py-78),Vector2(player.x+18,py-78),Vector2(player.x+25,py-32),Vector2(player.x-22,py-32)]), Color("34465a"))
        draw_circle(Vector2(player.x,py-91), 20, Color("b9774e")); draw_arc(Vector2(player.x,py-97),22,PI,TAU,20,Color("27221e"),9)
        draw_line(Vector2(player.x-12,py-32),Vector2(player.x-18,py-3),Color("382c27"),9); draw_line(Vector2(player.x+12,py-32),Vector2(player.x+19,py-3),Color("382c27"),9)
        draw_line(Vector2(player.x+16,py-67),Vector2(player.x+35,py-61),Color("b9774e"),8)
    # projectiles and floating paper hazards
    for s in shots:
        draw_colored_polygon(PackedVector2Array([s+Vector2(0,-8),s+Vector2(10,0),s+Vector2(0,8),s+Vector2(-10,0)]), Color("cf5260")); draw_circle(s,3,Color("fff0d8"))
    for h in hazards:
        draw_rect(Rect2(h.x-13,h.y-10,26,20),Color("ead9b7"),true); draw_line(h+Vector2(-9,-4),h+Vector2(9,4),Color("9d563f"),2)
    # top poster HUD
    draw_rect(Rect2(22,18,380,82),Color("3f3026")); draw_rect(Rect2(27,23,370,72),Color("e6d5b2"));
    _text("MURUGAN  •  COLLEGE KATHAL", 42, 51, 20, Color("3b2a20"))
    for i in range(3): draw_circle(Vector2(48+i*30,75),10,Color("bd4a48") if i<hp else Color("b4a795"))
    _text("LOVE LETTERS", 160, 81, 14, Color("725b45"))
    draw_rect(Rect2(710,20,292,75),Color("3f3026")); draw_rect(Rect2(715,25,282,65),Color("ead9b7"));
    _text("SHARMILA  •  INTEREST", 735, 52, 18, Color("3b2a20"))
    draw_rect(Rect2(738,64,238,14),Color("b6a78b")); draw_rect(Rect2(738,64,238*boss_hp/100.0,14),Color("bd514a"))
    _text("CAMPUS CORRIDOR", 424, 314, 20, Color("fff0d2"), HORIZONTAL_ALIGNMENT_CENTER)
    # bottom controls plaque
    draw_rect(Rect2(18,520,988,62),Color("3e3027")); draw_rect(Rect2(23,525,978,52),Color("d8c7a7"))
    _text("A / D MOVE     SPACE JUMP     SHIFT DASH     J THROW LOVE LETTER     R TALK", 512, 557, 17, Color("403126"), HORIZONTAL_ALIGNMENT_CENTER)
    if dialogue:
        draw_rect(Rect2(116,102,792,300),Color("392a24")); draw_rect(Rect2(123,109,778,286),Color("eee0c1"))
        _text("DIALOGUE ENGINE  •  SHARMILA", 512, 146, 24, Color("513a2a"), HORIZONTAL_ALIGNMENT_CENTER)
        _text("“Aiyo! Are you serious? This is very sudden!”", 512, 187, 20, Color("6b4b38"), HORIZONTAL_ALIGNMENT_CENTER)
        _text("Choose your reply", 512, 225, 17, Color("8a5e3c"), HORIZONTAL_ALIGNMENT_CENTER)
        _text("[1] “No pressure. I just wanted to make you smile.”", 174, 267, 18, Color("49372a"))
        _text("[2] “Your fest idea was brilliant. Want to team up?”", 174, 309, 18, Color("49372a"))
        _text("[3] “Come on, say yes. Everyone is watching!”", 174, 351, 18, Color("9a4541"))
    if result != "":
        draw_rect(Rect2(188,207,648,136),Color("392a24")); draw_rect(Rect2(195,214,634,122),Color("eee0c1"))
        _text(result,512,267,22,Color("513a2a"),HORIZONTAL_ALIGNMENT_CENTER)
        if OS.has_feature("web"):
            _draw_touch_button(CONTROL_RETRY, "TOUCH TO RETRY")
        else:
            _text("Press Enter to play again",512,307,16,Color("8a5e3c"),HORIZONTAL_ALIGNMENT_CENTER)
    elif dialogue and OS.has_feature("web"):
        _draw_touch_button(CONTROL_CHOICE_1, "1  NO PRESSURE")
        _draw_touch_button(CONTROL_CHOICE_2, "2  TEAM UP FOR THE FEST")
        _draw_touch_button(CONTROL_CHOICE_3, "3  SAY YES! (RISKY)")
    elif OS.has_feature("web"):
        _draw_touch_button(CONTROL_LEFT, "LEFT")
        _draw_touch_button(CONTROL_RIGHT, "RIGHT")
        _draw_touch_button(CONTROL_DASH, "DASH")
        _draw_touch_button(CONTROL_JUMP, "JUMP")
        _draw_touch_button(CONTROL_THROW, "LETTER")
        _draw_touch_button(CONTROL_TALK, "TALK")

func _draw_touch_button(rect: Rect2, label: String) -> void:
    draw_rect(rect, Color(0.19, 0.13, 0.10, 0.72), true)
    draw_rect(rect, Color(0.91, 0.83, 0.68, 0.92), false, 3.0)
    _text(label, rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y / 2.0 + 7.0, 18, Color("fff1d2"), HORIZONTAL_ALIGNMENT_CENTER)

func draw_oval(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(25):
        var a := TAU * i / 24.0
        points.append(center + Vector2(cos(a)*radius.x, sin(a)*radius.y))
    draw_colored_polygon(points, color)




