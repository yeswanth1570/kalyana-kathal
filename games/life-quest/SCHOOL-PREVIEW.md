# The Folded Note preview

In Before the Bell, tap a cover ring to sneak there and crouch. Use Dash to slide, vault a bench, or get to the next cover faster. Sprinting across water or chalk draws extra attention. Tap the brass bell rope to pull Sundaram away. On desktop, A/D moves, W targets the next cover, S crouches, and Shift dashes. A full awareness meter costs one HP and returns Murugan to his last open doorway.

In The Last Bench, time your movement while Ms. Revathi writes, then use Offer Note or E at Sharmila’s bench. Tap Duck on touch or hold S on keyboard. In The Walk Home, time the bicycle crossings and meet Sharmila at the bus stop.

Getting caught opens a parent–teacher meeting. Explaining the mistake and how to put it right earns a longer opening on a supervised retry. The mobile preview is published at /life-quest-preview/. The stable /life-quest/ path serves v5.

For live school conversations, run Start-Phone-Chat.ps1 -Preview on the PC with Ollama and Qwen ready. It updates the game API when needed and keeps a working relay. Open the resulting private preview pairing link or pair through Settings. Written replies work with the PC offline.

## Adult pilot

The game API never writes transcripts. The pilot uses a distinct loopback-only server, outside the public web export. Run it locally during an adult playtest with a dedicated private database. Keep the database outside web artifacts and Git, with operator-only file access and an encrypted disk. Never tunnel the pilot port or expose its database to phones or public players.

1. Before issuing an invitation, verify the participant is an adult under the program’s approved enrollment procedure. Keep any identity records out of the game and pilot database.
2. From the project directory, run python backend/pilot/pilot.py --database PRIVATE_PATH.sqlite invite --adult-verified. Share that one invitation directly with the eligible tester.
3. Run python backend/pilot/pilot.py --database PRIVATE_PATH.sqlite serve PATH_TO_SCHOOL_WEB_EXPORT. Open the loopback URL returned by the script on the pilot PC, then connect Qwen and enroll with the invitation in the pilot panel.
4. Complete a typed school exchange. The optional review panel lets the tester read and edit it, set the language, accept the current training terms, submit, or discard. Enrollment alone stores no conversation. Keep the receipt and invitation for withdrawal.
5. Run review, then approve RECEIPT or reject RECEIPT with the same database argument. Exclude any personal, identifying, off-topic, or unlicensed content. Rejected text is erased from the review payload.
6. Test candidate exports with the authored fixtures in the data card. Export real reviewed rows only after reviewing language and cohort coverage, obtaining rights clearance for model and human text, and signing an approved buyer agreement. The exporter requires --agreement REFERENCE --rights-verified. It does not transmit files.
7. For a post-export withdrawal, review shows notify_buyer and the agreement reference. The program operator must follow the buyer contract. If a write is interrupted, privately reconcile any export_reserved batch before sharing any part of that file.

The adult pilot’s process and controls need review before recruiting real testers or commercializing any records. Do not use ID documents inside the game, do not include recorded audio, and do not use public chat for the dataset.
