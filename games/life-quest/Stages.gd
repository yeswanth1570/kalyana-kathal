extends RefCounted

# Authored scene openings only. All player replies go to the Qwen character API.
const ACTS: Array[Dictionary] = [
	{
		"name": "The first sight",
		"place": "SCHOOL CORRIDOR",
		"year": "1999",
		"boss": "Whistle Sundaram",
		"tag": "Discipline first. Daydreams later.",
		"intro": "A note for Sharmila. A corridor under watch.\nSlip past the PT master and reach the gate unseen.",
		"hint": "Watch the gold vision cone. Hold HIDE at book carts. Move when he looks away.",
		"tint": "54756d",
		"weapon": "Folded notes",
		"ending": "You slip past the master. Sharmila accepts your note with a smile.\n\"Friends first, okay?\" she says. You agree.",
		"talks": [
			{
				"q": "Young man! Why are you wandering outside class?"
			},
			{
				"q": "And what about your district exams?"
			},
			{
				"q": "Sharmila may not want a note. Then what?"
			}
		]
	},
	{
		"name": "Canteen butterflies",
		"place": "ANNACHI'S CANTEEN",
		"year": "2005",
		"boss": "Mass Kumar",
		"tag": "One cultural fest. Too much drama.",
		"intro": "Engineering college. Filter coffee. An old friend.\nClear the canteen chaos, then talk to Sharmila.",
		"hint": "Be sincere. Listen. An invitation is a choice.",
		"tint": "bd704f",
		"weapon": "Jasmine letters",
		"ending": "\"One coffee. And you are helping with the fest!\"\nSharmila laughs. It feels like the start of something real.",
		"talks": [
			{
				"q": "Sharmila: Aiyo! After all these years? This is sudden!"
			},
			{
				"q": "Sharmila: Do you remember what I actually care about?"
			},
			{
				"q": "Sharmila: What if I only want to be friends?"
			}
		]
	},
	{
		"name": "The deadline trap",
		"place": "OMR TECH PARK",
		"year": "2011",
		"boss": "Manager Karthik",
		"tag": "A quick sync is never quick.",
		"intro": "The family meeting is tonight. The release is today.\nDodge urgent tickets and negotiate a proper handover.",
		"hint": "Show a plan: tested build, handover, clear boundaries.",
		"tint": "537f88",
		"weapon": "Coffee mail",
		"ending": "\"Tests green? Handover done? Leave approved!\"\nKarthik finally closes the laptop. The evening is yours.",
		"talks": [
			{
				"q": "Leaving early? What about today's production release?"
			},
			{
				"q": "Who will handle the deployment while you are away?"
			},
			{
				"q": "Can you stay available all weekend, just in case?"
			}
		]
	},
	{
		"name": "The living room trial",
		"place": "SHARMILA'S HOME",
		"year": "2012",
		"boss": "Amma & Appa",
		"tag": "Two coffees. A thousand questions.",
		"intro": "The toughest interview has no job description.\nStay calm, dodge the questions, and speak from the heart.",
		"hint": "Respect both families. Share a practical plan.",
		"tint": "967b56",
		"weapon": "Coffee invitations",
		"ending": "Amma pours a second coffee. Appa smiles behind his newspaper.\n\"Bring your parents on Sunday. We should all talk.\"",
		"talks": [
			{
				"q": "Appa: Affection is nice. What about a stable future?"
			},
			{
				"q": "Amma: Will Sharmila have to give up her theatre work?"
			},
			{
				"q": "Appa: Our families do things differently. Will that work?"
			}
		]
	},
	{
		"name": "The garland finale",
		"place": "KALYANA MANDAPAM",
		"year": "2013",
		"boss": "Mandapam Mamis",
		"tag": "Love. Laughter. Last-minute chaos.",
		"intro": "Missing garlands! Loud relatives! A nervous bride!\nClear the gossip, then make a promise worth keeping.",
		"hint": "Remember your journey. Reassure, listen, and share.",
		"tint": "ac675f",
		"weapon": "Mallipoo wishes",
		"ending": "Garlands exchanged. Families cheering. The music begins.\nYour biggest adventure is not the wedding. It is the life you build together.",
		"talks": [
			{
				"q": "Sharmila: Everything is so loud. What if this is too much?"
			},
			{
				"q": "Sharmila: Remember our first coffee after the college fest?"
			},
			{
				"q": "Sharmila: One real promise. No cinema dialogue. What is it?"
			}
		]
	}
]
