# The Folded Note preview

The school chapter has three scenes. Hold S or Down on a keyboard. On touch, tap Duck to toggle and slide between Left and Right to change direction. A cart blocks Sundaram’s view only while you crouch behind it. Use Q or Pencil for a collected distraction and E or Place for a matching notebook. The caught and timeout paths use the same Sundaram debrief as success, with a repair contract instead of an automatic life loss.

The mobile preview is published at /life-quest-preview/. The stable /life-quest/ path stays pinned to v5 until the v8 preview passes physical Android and iOS checks. Later chapters retain their existing encounters. Push-to-talk remains a later update.

For live Sundaram replies, run the updated backend/server.py with the existing Qwen configuration and restart the game API if it was already running. The old endpoint remains compatible with the stable game. Use Start-Phone-Chat.ps1 -Preview to create a private preview pairing link, or pair the existing relay endpoint and private code on the preview’s settings screen. An unavailable or old backend leaves every scene playable through the written reply.

## Adult pilot

The game API never writes transcripts. The pilot uses a distinct loopback-only server, outside the public web export. Run it locally during an adult playtest with a dedicated private database. Keep the database outside web artifacts and Git, with operator-only file access and an encrypted disk. Never tunnel the pilot port or expose its database to phones or public players.

1. Before issuing an invitation, verify the participant is an adult under the program’s approved enrollment procedure. Keep any identity records out of the game and pilot database.
2. From the project directory, run python backend/pilot/pilot.py --database PRIVATE_PATH.sqlite invite --adult-verified. Share that one invitation directly with the eligible tester.
3. Run python backend/pilot/pilot.py --database PRIVATE_PATH.sqlite serve PATH_TO_V7_WEB_EXPORT. Open the loopback URL returned by the script on the pilot PC, then connect Qwen and enroll with the invitation in the pilot panel.
4. Complete a typed Sundaram exchange. The optional review panel lets the tester read and edit it, set the language, accept the current training terms, submit, or discard. Enrollment alone stores no conversation. Keep the receipt and invitation for withdrawal.
5. Run review, then approve RECEIPT or reject RECEIPT with the same database argument. Exclude any personal, identifying, off-topic, or unlicensed content. Rejected text is erased from the review payload.
6. Test candidate exports with the authored fixtures in the data card. Export real reviewed rows only after reviewing language and cohort coverage, obtaining rights clearance for model and human text, and signing an approved buyer agreement. The exporter requires --agreement REFERENCE --rights-verified. It does not transmit files.
7. For a post-export withdrawal, review shows notify_buyer and the agreement reference. The program operator must follow the buyer contract. If a write is interrupted, privately reconcile any export_reserved batch before sharing any part of that file.

The adult pilot’s process and controls need review before recruiting real testers or commercializing any records. Do not use ID documents inside the game, do not include recorded audio, and do not use public chat for the dataset.
