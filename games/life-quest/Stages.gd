extends RefCounted

# Authored, deterministic dialogue. No remote AI or player-data collection.
const ACTS: Array[Dictionary] = [
	{
		"name": "The first sight", "place": "SCHOOL CORRIDOR", "year": "1999", "boss": "Whistle Sundaram",
		"tag": "Discipline first. Daydreams later.", "intro": "A note for Sharmila. A corridor full of chalk.\nWin the PT master's trust before the bell rings.",
		"hint": "Respect his rules. Be honest about the note.", "tint": "54756d", "weapon": "Folded notes",
		"ending": "The master puts away his whistle. Sharmila accepts your note with a smile.\n\"Friends first, okay?\" she says. You agree.",
		"talks": [
			{"q": "Young man! Why are you wandering outside class?", "choices": ["Sir, I finished my work. May I give my friend a note?", "Just stretching my legs, sir.", "Your rules do not apply to me!"], "scores": [30,12,-12], "reply": ["Honesty! A good start. But class comes first.", "Then stretch them on the running track!", "Extra laps! Think before you speak."], "clues": ["honest", "class", "friend", "respect", "sir", "padippu", "உண்மை", "படிப்பு"]},
			{"q": "And what about your district exams?", "choices": ["Padippu first, sir. I will keep up with my studies.", "I will try, sir. Can I go now?", "Exams are boring. Romance is everything."], "scores": [30,12,-12], "reply": ["Good. Actions must match those words.", "Trying needs a timetable, young man.", "No shortcuts to a good future!"], "clues": ["study", "studies", "exam", "padippu", "promise", "படிப்பு", "தேர்வு"]},
			{"q": "Sharmila may not want a note. Then what?", "choices": ["Her choice, sir. I will respect it and head to class.", "I can ask her once, politely.", "I will keep asking until she says yes."], "scores": [30,20,-18], "reply": ["That is maturity. Go on, then. And no running!", "Once, politely. And accept her answer.", "No means no. You must learn that."], "clues": ["respect", "choice", "no pressure", "accept", "viruppam", "விருப்பம்", "மரியாதை"]}
		]
	},
	{
		"name": "Canteen butterflies", "place": "ANNACHI'S CANTEEN", "year": "2005", "boss": "Mass Kumar",
		"tag": "One cultural fest. Too much drama.", "intro": "Engineering college. Filter coffee. An old friend.\nClear the canteen chaos, then talk to Sharmila.",
		"hint": "Be sincere. Listen. An invitation is a choice.", "tint": "bd704f", "weapon": "Jasmine letters",
		"ending": "\"One coffee. And you are helping with the fest!\"\nSharmila laughs. It feels like the start of something real.",
		"talks": [
			{"q": "Sharmila: Aiyo! After all these years? This is sudden!", "choices": ["No pressure. I just wanted to make you smile.", "Coffee at Annachi's? My treat.", "Everyone is watching. Please say yes."], "scores": [30,18,-18], "reply": ["That is sweet. Thank you for giving me space.", "Coffee sounds nice. But let us talk first.", "Please do not put me on the spot."], "clues": ["space", "no pressure", "smile", "respect", "choice", "சிரிப்பு", "விருப்பம்"]},
			{"q": "Sharmila: Do you remember what I actually care about?", "choices": ["Your theatre idea for the fest. Let us build it together.", "Your coffee order? Extra strong, I think.", "You should care about my mass hero entrance!"], "scores": [30,15,-12], "reply": ["You remembered! I have been working on the script.", "Almost! But theatre is my real obsession.", "I prefer someone who listens to me."], "clues": ["theatre", "fest", "listen", "script", "together", "நாடகம்", "விழா"]},
			{"q": "Sharmila: What if I only want to be friends?", "choices": ["Then friends it is. Your happiness matters to me.", "I would be disappointed, but I understand.", "I helped you. You owe me a date."], "scores": [30,24,-25], "reply": ["That means a lot. Actually... let us try that coffee.", "Thank you for being honest and understanding.", "Kindness is not a transaction, Murugan."], "clues": ["friend", "happy", "understand", "respect", "choice", "நண்ப", "சந்தோஷம்"]}
		]
	},
	{
		"name": "The deadline trap", "place": "OMR TECH PARK", "year": "2011", "boss": "Manager Karthik",
		"tag": "A quick sync is never quick.", "intro": "The family meeting is tonight. The release is today.\nDodge urgent tickets and negotiate a proper handover.",
		"hint": "Show a plan: tested build, handover, clear boundaries.", "tint": "537f88", "weapon": "Coffee mail",
		"ending": "\"Tests green? Handover done? Leave approved!\"\nKarthik finally closes the laptop. The evening is yours.",
		"talks": [
			{"q": "Leaving early? What about today's production release?", "choices": ["Tests are green. Here is the release checklist.", "I will check from the cab if anything breaks.", "Just ship it. Nobody checks anyway."], "scores": [30,12,-18], "reply": ["Evidence! That is what I needed to see.", "That sounds risky. Give me a real plan.", "That attitude will create more work for everyone."], "clues": ["test", "checklist", "green", "verified", "build", "சோதனை"]},
			{"q": "Who will handle the deployment while you are away?", "choices": ["Priya agreed to cover. The rollback notes are ready.", "I left some notes in the team chat.", "Not my problem after six o'clock."], "scores": [30,16,-14], "reply": ["A confirmed handover and rollback plan. Excellent.", "Please confirm someone has read those notes.", "Boundaries matter. So does a responsible handover."], "clues": ["handover", "cover", "rollback", "priya", "notes", "team", "குழு"]},
			{"q": "Can you stay available all weekend, just in case?", "choices": ["The on-call rota has cover. I need this family time.", "One agreed check-in, then I am offline.", "Yes, I will cancel everything. Again."], "scores": [30,24,6], "reply": ["Fair. We planned for this. Enjoy your family meeting.", "Agreed. One check-in, no surprise meetings.", "That is not sustainable. Let us plan proper cover."], "clues": ["family", "rota", "cover", "plan", "boundary", "time", "குடும்பம்", "நேரம்"]}
		]
	},
	{
		"name": "The living room trial", "place": "SHARMILA'S HOME", "year": "2012", "boss": "Amma & Appa",
		"tag": "Two coffees. A thousand questions.", "intro": "The toughest interview has no job description.\nStay calm, dodge the questions, and speak from the heart.",
		"hint": "Respect both families. Share a practical plan.", "tint": "967b56", "weapon": "Coffee invitations",
		"ending": "Amma pours a second coffee. Appa smiles behind his newspaper.\n\"Bring your parents on Sunday. We should all talk.\"",
		"talks": [
			{"q": "Appa: Affection is nice. What about a stable future?", "choices": ["We have savings and a budget. We will plan together.", "I work hard and hope things turn out well.", "My salary proves I am better than everyone."], "scores": [30,15,-16], "reply": ["A shared plan matters more than showing off a number.", "Hard work helps. Tell us about your plan as well.", "We are discussing a family, not a competition."], "clues": ["plan", "save", "saving", "budget", "together", "future", "திட்டம்", "சேமிப்பு"]},
			{"q": "Amma: Will Sharmila have to give up her theatre work?", "choices": ["Never. Her dreams matter as much as mine.", "We should work out our schedules together.", "Of course. My career comes first."], "scores": [30,25,-25], "reply": ["Good. She has worked hard for those dreams.", "Sharing the work at home will help both of you.", "Then you do not understand our daughter."], "clues": ["dream", "equal", "support", "theatre", "share", "கனவு", "சமம்"]},
			{"q": "Appa: Our families do things differently. Will that work?", "choices": ["We can respect both traditions and make fair choices.", "Let us have both families talk, without pressure.", "Your family must follow all of our rules."], "scores": [30,26,-20], "reply": ["Respect and fairness. We can begin there.", "Yes. A conversation, not a contest.", "A marriage needs room for both families."], "clues": ["respect", "both", "fair", "listen", "family", "மரியாதை", "இரு", "குடும்பம்"]}
		]
	},
	{
		"name": "The garland finale", "place": "KALYANA MANDAPAM", "year": "2013", "boss": "Mandapam Mamis",
		"tag": "Love. Laughter. Last-minute chaos.", "intro": "Missing garlands! Loud relatives! A nervous bride!\nClear the gossip, then make a promise worth keeping.",
		"hint": "Remember your journey. Reassure, listen, and share.", "tint": "ac675f", "weapon": "Mallipoo wishes",
		"ending": "Garlands exchanged. Families cheering. The music begins.\nYour biggest adventure is not the wedding. It is the life you build together.",
		"talks": [
			{"q": "Sharmila: Everything is so loud. What if this is too much?", "choices": ["Let us take a quiet minute. I am here. We go at your pace.", "A deep breath, and we can ask for some space.", "Smile for the camera. Everyone is waiting."], "scores": [30,25,-18], "reply": ["Thank you. A quiet minute with you is exactly what I need.", "Yes. Let us breathe together.", "I need you to hear me, not the crowd."], "clues": ["quiet", "here", "pace", "listen", "breathe", "அமைதி", "கேள்"]},
			{"q": "Sharmila: Remember our first coffee after the college fest?", "choices": ["You told me about your theatre script. I still want front-row seats.", "Extra-strong coffee, and we could not stop laughing.", "Not really. There have been so many dates."], "scores": [30,24,-18], "reply": ["You kept listening, all these years. That is why I chose you.", "And you spilled yours laughing! I remember.", "It mattered to me. Let us pay attention to each other."], "clues": ["coffee", "theatre", "script", "fest", "remember", "காபி", "நாடகம்"]},
			{"q": "Sharmila: One real promise. No cinema dialogue. What is it?", "choices": ["I will listen, share the work, and keep choosing us every day.", "When life gets hard, we will ask for help together.", "I promise we will never disagree, ever."], "scores": [30,28,5], "reply": ["Then let us begin. Together.", "Together. That is the promise I wanted.", "Real life has disagreements. Promise we will listen through them."], "clues": ["listen", "share", "together", "every day", "help", "கேட்ப", "சேர்ந்து", "பகிர்"]}
		]
	}
]

static func evaluate(text: String, stage: int, phase: int) -> Dictionary:
	var clean := text.strip_edges().to_lower()
	if clean.length() < 5:
		return {"score": 0, "reply": "Say a little more, or pick one of the replies above."}
	# Negative intent takes precedence over a coincidental positive keyword.
	for bad in ["owe me", "force", "shut up", "stupid", "must say yes", "don't care", "do not care", "cancel your dream"]:
		if bad in clean:
			return {"score": -15, "reply": "Pressure will not help. Listen to what the other person needs."}
	var hits := 0
	for clue in ACTS[stage].talks[phase].clues:
		if clue in clean:
			hits += 1
	if hits > 0:
		return {"score": mini(32, 20 + hits * 6), "reply": ACTS[stage].talks[phase].reply[0]}
	return {"score": 10, "reply": "I hear you. Can you address my concern a little more directly?"}
