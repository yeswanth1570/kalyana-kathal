# Kathal Kayanam

Murugan and Sharmila’s story spans School, College, Office, Family, and Wedding. Each chapter opens with four-direction exploration and continues into the original Life Quest stealth or action encounter. Written Tamil and English responses work offline throughout the campaign.

## Play

Open [Kathal Kayanam on GitHub Pages](https://yeswanth1570.github.io/kalyana-kathal/kathal-kayanam/) and tap **Play**.

Open `project.godot` in Godot 4.7.2 and press **F5**. For the browser build, run this command from the project folder and open `http://127.0.0.1:8774/`:

```powershell
python -m http.server 8774 --bind 127.0.0.1 --directory build/web
```

**Continue** resumes at the latest campaign checkpoint. Encounters restart from their checkpoint when the game is closed mid-attempt. Chapter Select can replay previous chapters without overwriting campaign progress. Escape opens the pause menu, including Journal, Relationships, and Inventory.

| Action | Keyboard | Controller | Touch |
| --- | --- | --- | --- |
| Explore | WASD, arrows, or click | Left stick or D-pad | Joystick or tap the ground |
| Run / sneak | Shift / Space | RB / LB | Run / Sneak |
| Interact | E | A in exploration, B in encounters | Interact button |
| Jump / dash | Space / Shift | A / RB | Jump / Dash |
| Throw / parry / heal | X / K / H | X / LB / Y | Letter / Parry / Tiffin |
| Pause | Escape | Start | Pause |
| Journal / relationships / inventory | J / R / I | Back opens Journal | Pause menu |

Keyboard controls can be remapped under Settings → Controls. In the school veranda, tap nearby cover or press Up to select it. Tap the brass rope to distract Sundaram. In the classroom, move while Revathi is writing and use the note prompt beside Sharmila.

Live Qwen dialogue can be enabled in Settings. It uses the existing Life Quest PC API, with the player’s relay address and private access code entered for the session. Written responses are available if the connection fails.

## Rebuild the web export

With matching Godot web export templates installed, run Godot from the project folder:

```powershell
New-Item -ItemType Directory -Force build/web
godot --headless --path . --export-release Web build/web/index.html
Copy-Item web/chat.js, web/chat.css, art/ui/cover-v2.png, fonts/CinzelDecorative-Bold.ttf build/web
```

Gameplay checks are in `tests/gameplay.gd`, campaign and controls checks are in `tests/campaign.gd`, and sprite checks are in `tests/art.gd`. Run any of them with `godot --headless --path . --script res://tests/<file>.gd`. Run the browser chat checks with `node --test tests/chat.test.cjs`.

Run `node tests/browser.mjs` after the web export to exercise the desktop and phone-sized flows in Chromium. Set `KATHAL_CHROME` if Chrome is installed outside its standard Windows folder.
