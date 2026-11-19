extends RefCounted

enum Level { CORRIDOR, CLASSROOM, WALK_HOME }
enum Gaze { WRITING, TURNING_TO_CLASS, WATCHING, TURNING_TO_BOARD }

const TITLES := ["Before the Bell", "The Last Bench", "The Walk Home"]
const TIMES := [28.0, 52.0, 0.0]
const BENCHES := [0.15, 0.35, 0.55, 0.75]
const TEACHER_X := 0.89
const BUS_STOP := 0.89
const CROSSINGS := [0.31, 0.66]
const STALL := 0.48
const BIKE_PERIOD := 4.8
const BIKE_TRAVEL := 1.25
const PROMPTS := [
	"Tap Duck and slip between carts when Sundaram turns. Reach the classroom door.",
	"Move while Ms. Revathi writes. Duck behind a desk when she turns. Offer the note at the front bench.",
	"Watch for bicycles at the two crossings. Meet Sharmila at the bus stop."
]
const INTRO := [
	"Across the corridor, Sharmila laughs as a page slips from her notebook. Murugan catches it. Before he can say a word, Sundaram’s whistle cuts through the hall.",
	"Ms. Revathi starts the lesson. Murugan folds a note under the last bench. Sharmila is three rows ahead, and Revathi can turn from the board at any moment.",
	"School is out. Sharmila waves from the corner. “See you at the bus stop!” Murugan takes the familiar street past the tea stall."
]
const HOME_LINES := {
	"talk":"“I read your note. We have a minute before the bus. Tell me how you wrote it during maths.”",
	"later":"“Let me read it properly when I get home,” Sharmila says. “I’ll see you tomorrow.”",
	"friends":"“Friends first, okay?” Sharmila says. Murugan smiles. “Okay.”"
}

var level := 0
var checkpoint := 0
var unlocked := 0
var honor_pass := false
var supervised := false
var meeting_pending := false
var meeting_resolution := ""
var turn_face := 1.0
var concern_peak := 0.0
var note_time := 0.0
var stumble := 0.0
var stumble_face := 1.0
var ending := "friends"
var outcome := ""
var reason := ""
var concerns_met: Array[String] = []
var turns := 0

func reset_attempt() -> void:
	concern_peak = 0.0
	note_time = 0.0
	stumble = 0.0
	ending = "friends"
	outcome = ""
	reason = ""
	concerns_met.clear()
	turns = 0

func teacher() -> String:
	return "Ms. Revathi" if level == Level.CLASSROOM else "Sundaram"

func actor() -> String:
	if meeting_pending: return "%s & Amma" % teacher()
	return "Sharmila" if level == Level.WALK_HOME else teacher()

func opening() -> String:
	if meeting_pending:
		return "Amma pulls up a chair. %s asks what happened and what you’ll do differently on another try." % teacher()
	match level:
		Level.CORRIDOR: return "You made it to class. What brought you out into the corridor?"
		Level.CLASSROOM: return "I saw the note after the lesson. What did you want to tell Sharmila?"
		_: return "You made it! I have your note. What did you want to say before my bus comes?"

func written_reply() -> String:
	if meeting_pending:
		return "I stepped out while you were watching. I’ll wait for a safe moment and follow your instructions."
	if level == Level.CORRIDOR:
		return "I came to return a page to Sharmila. I’ll wait until there’s time to talk."
	return "I wanted to say hello. Sharmila can read it whenever she likes."

func required_concerns() -> Array[String]:
	if meeting_pending: return ["ownership", "repair"]
	return [] if level == Level.WALK_HOME else ["purpose"]

func turn_limit() -> int:
	if meeting_pending: return 4
	return 1 if level == Level.WALK_HOME else 2

func accept_reply(addressed: Array) -> String:
	turns += 1
	for key in addressed:
		if key is String and key in required_concerns() and key not in concerns_met:
			concerns_met.append(key)
	for key in required_concerns():
		if key not in concerns_met:
			return "retry" if turns >= turn_limit() else ""
	return "conditional" if meeting_pending else "pass"

func context() -> Dictionary:
	return {"protocol":3, "level":level, "outcome":outcome, "reason":reason, "honor_pass":honor_pass}

func gaze(time: float) -> int:
	var write := 6.0 if supervised else 4.0
	var beat := fposmod(time,write+3.4)
	if beat < write: return Gaze.WRITING
	if beat < write+0.65: return Gaze.TURNING_TO_CLASS
	if beat < write+2.75: return Gaze.WATCHING
	return Gaze.TURNING_TO_BOARD

static func bike_progress(index: int, time: float) -> float:
	var beat := fposmod(time+float(index)*1.8,BIKE_PERIOD)
	return beat/BIKE_TRAVEL
