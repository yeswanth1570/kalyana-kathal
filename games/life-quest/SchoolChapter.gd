extends RefCounted

const TITLES := ["Before the Bell", "The Report Card", "The Side Gate"]
const TIMES := [28.0, 44.0, 42.0]
const EXTRA_WIDTH := [0.0, 260.0, 560.0]
const NOTEBOOKS := ["RED", "BLUE", "GOLD"]
const WIN_LINES := [
	"You made it to class before the bell. Why were you in the corridor?",
	"Three notebooks, three desks. How will you keep up with your own assignments?",
	"You got to the gate without disturbing class. What if Sharmila doesn’t want the note?"
]
const FAIL_LINES := [
	"Stop there, Murugan. Where should you be, and how will you put this right?",
	"We haven’t finished the notebook round. What went wrong, and how will you fix it?",
	"I need to know why you’re out here. What will you do differently, and what if she says no?"
]
const GOOD_REPLIES := [
	"I wanted to say hello to Sharmila. I’ll check in and wait until class is over.",
	"I’ll return each book to its matching desk, then make time for my own work.",
	"I’ll ask if she wants the note. If she says no, I’ll leave her be."
]
const REPAIR_REPLIES := [
	"I left class without checking in. I’ll report at the office first.",
	"I rushed the round. I’ll check the cover and return the missing book.",
	"I tried to slip out. I’ll take the supervised route and respect her answer."
]
const PROMPTS := [
	"Get to the classroom door on the right. Hold DUCK while moving and use carts for cover.",
	"Return Red, Blue, then Gold notebooks to matching desks. Use PLACE or E near a desk.",
	"Carry the note to the side gate. Use the pencil to turn Sundaram’s gaze before crossing."
]
const REPAIRS := [
	"Check in at the office desk.",
	"Return the replacement notebook to the blue desk.",
	"Check in with the gate attendant and wait until class ends."
]

var level := 0
var checkpoint := 0
var unlocked := 0
var honor_pass := false
var grade_available := false
var repair_pending := false
var placed := 0
var pencil := false
var pencil_picked := false
var pencil_origin := 0.0
var pencil_x := 0.0
var pencil_unseen := false
var pencil_time := 0.0
var listen_time := 0.0
var turn_face := 1.0
var outcome := ""
var reason := ""
var concerns_met: Array[String] = []
var turns := 0

func reset_attempt() -> void:
	placed = 0
	grade_available = false
	pencil = false
	pencil_picked = false
	pencil_time = 0.0
	listen_time = 0.0
	outcome = ""
	reason = ""
	concerns_met.clear()
	turns = 0

func opening() -> String:
	return WIN_LINES[level] if outcome == "success" else FAIL_LINES[level]

func required_concerns() -> Array[String]:
	var keys: Array[String] = []
	if outcome == "success":
		keys.append("purpose" if level != 2 else "choice")
	else:
		keys.assign(["ownership", "repair"])
		if level == 2: keys.append("choice")
	return keys

func turn_limit() -> int:
	return 2 if outcome == "success" else 4

func accept_reply(addressed: Array) -> String:
	turns += 1
	for key in addressed:
		if key is String and key in required_concerns() and key not in concerns_met:
			concerns_met.append(key)
	for key in required_concerns():
		if key not in concerns_met:
			return "retry" if turns >= turn_limit() else ""
	return "pass" if outcome == "success" else "conditional"

func context() -> Dictionary:
	return {"level":level, "outcome":outcome, "reason":reason, "notebooks":placed, "honor_pass":honor_pass}
