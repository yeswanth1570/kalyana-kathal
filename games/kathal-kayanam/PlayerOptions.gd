extends RefCounted

const DEFAULT_KEYS := {
	"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S,
	"interact": KEY_E, "run": KEY_SHIFT, "jump": KEY_SPACE,
	"fire": KEY_X, "parry": KEY_K, "heal": KEY_H,
	"pause": KEY_ESCAPE, "journal": KEY_J, "relationships": KEY_R, "inventory": KEY_I,
}
const LABELS := {
	"left": "Move left", "right": "Move right", "up": "Move up / aim up", "down": "Move down / aim down",
	"interact": "Interact / Speak", "run": "Run / Dash", "jump": "Sneak / Jump",
	"fire": "Throw letter", "parry": "Parry", "heal": "Use Tiffin", "pause": "Pause",
	"journal": "Journal", "relationships": "Relationships", "inventory": "Inventory",
}
const ARROWS := {KEY_LEFT: "left", KEY_RIGHT: "right", KEY_UP: "up", KEY_DOWN: "down"}
const PAD := {JOY_BUTTON_A: "jump", JOY_BUTTON_B: "interact", JOY_BUTTON_X: "fire",
	JOY_BUTTON_Y: "heal", JOY_BUTTON_LEFT_SHOULDER: "parry", JOY_BUTTON_RIGHT_SHOULDER: "run",
	JOY_BUTTON_START: "pause", JOY_BUTTON_BACK: "journal",
	JOY_BUTTON_DPAD_LEFT: "left", JOY_BUTTON_DPAD_RIGHT: "right",
	JOY_BUTTON_DPAD_UP: "up", JOY_BUTTON_DPAD_DOWN: "down"}

var keys := DEFAULT_KEYS.duplicate()
var master := 1.0
var music := 1.0
var effects := 1.0
var language := "both"
var subtitle_size := 1.0
var subtitle_background := 0.75
var auto_hide := true
var live_dialogue := false

func read(cfg: ConfigFile) -> void:
	master = clampf(float(cfg.get_value("options", "master", 1.0)), 0.0, 1.0)
	music = clampf(float(cfg.get_value("options", "music", 1.0)), 0.0, 1.0)
	effects = clampf(float(cfg.get_value("options", "effects", 1.0)), 0.0, 1.0)
	language = str(cfg.get_value("options", "language", "both"))
	if language not in ["both", "ta", "en"]: language = "both"
	subtitle_size = clampf(float(cfg.get_value("options", "subtitle_size", 1.0)), 0.85, 1.4)
	subtitle_background = clampf(float(cfg.get_value("options", "subtitle_background", 0.75)), 0.0, 1.0)
	auto_hide = bool(cfg.get_value("options", "auto_hide", true))
	live_dialogue = bool(cfg.get_value("options", "live_dialogue", false))
	var saved = cfg.get_value("options", "keys", {})
	keys = DEFAULT_KEYS.duplicate()
	if saved is Dictionary:
		var candidate := DEFAULT_KEYS.duplicate()
		for action in candidate:
			var key: int = int(saved.get(action, candidate[action]))
			if key > 0 and ARROWS.get(key, action) == action and (key != KEY_ESCAPE or action == "pause"):
				candidate[action] = key
		if candidate.values().size() == _distinct_count(candidate.values()): keys = candidate

func _distinct_count(values: Array) -> int:
	var distinct := {}
	for value in values: distinct[value] = true
	return distinct.size()

func write(cfg: ConfigFile) -> void:
	for option in ["master", "music", "effects", "language", "subtitle_size", "subtitle_background", "auto_hide", "live_dialogue", "keys"]:
		cfg.set_value("options", option, get(option))

func bind(action: String, key: int) -> String:
	if key == KEY_ESCAPE and action != "pause": return "Escape is reserved for pause and back."
	var arrow: String = ARROWS.get(key, action)
	if arrow != action: return "%s is reserved for %s." % [key_name(key), LABELS[arrow].to_lower()]
	for other in keys:
		if other != action and keys[other] == key: return "%s already uses %s." % [LABELS[other], key_name(key)]
	keys[action] = key
	return ""

func keyboard_action(key: int) -> String:
	if key == KEY_ESCAPE: return "pause"
	if ARROWS.has(key): return ARROWS[key]
	var result = keys.find_key(key)
	return "" if result == null else str(result)

func key_name(key: int) -> String:
	if OS.has_feature("web") or DisplayServer.get_name() == "headless": return OS.get_keycode_string(key)
	var mapped := DisplayServer.keyboard_get_keycode_from_physical(key)
	return OS.get_keycode_string(mapped if mapped != 0 else key)

func text(english: String, tamil: String) -> String:
	if tamil.is_empty() or tamil == english or language == "en": return english
	return tamil if language == "ta" else "%s\n%s" % [tamil, english]
