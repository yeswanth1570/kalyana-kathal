# Kalyana Kathal The Life Quest

A separate five-act Godot 4.7.2 game based on the supplied Kalyana Kathal design brief. The original college prototype and its assets remain at the repository root.

Play at **https://yeswanth1570.github.io/kalyana-kathal/life-quest/**. Tap Play, choose an unlocked act, then tap Action. Landscape is recommended on phones; portrait layouts also work. The first load includes the Godot WebAssembly runtime, so allow the loading bar to finish.

## What is playable

Five complete encounters: School, College, Office, Family and Wedding. Each has a setting, character art, different projectiles, three conversations, consequences for replies, a recoverable trust loop, a stage ending and an unlockable next act. Murugan changes outfits as the story advances. Jump, dash with a cooldown, parry pink petals, throw letters, use one healing tiffin, and pause at any time. Original drawn vector art, character animation, confetti and music are included.

Auto fire and Gentle mode are enabled by default. Change them in Settings. Reduce Motion disables shake and film texture animation. Progress and settings save locally; clearing browser site data resets them. Replay unlocked acts from the selection menu.

## Controls

Touch: hold left/right, tap Jump/Dash/Parry, hold Letter when auto fire is disabled. Multiple fingers work independently. The Tiffin button heals two HP once per act. Speak opens an early conversation when the gold meter is full.

Keyboard: A/D or Left/Right to move; Space jump; Shift dash; J/X fire; W/S or Up/Down to aim; K parry; H heal; R speak; Escape/P pause. In conversations choose 1/2/3 or type a reply. Text input consumes number keys normally.

## Live Qwen character conversations

Conversations use **Qwen3 1.7B on your PC through Ollama**. Type freely in English, Tanglish or Tamil. Sharmila and the other characters generate contextual replies using the current scene and recent messages. Qwen returns a validated reply, emotion, trust change and next attack pattern. There are no preset player-reply buttons and no keyword-based simulated agent. The title screen also has **Chat with Sharmila** for an immediate conversation outside combat.

The browser has a responsive chat overlay with a native textarea, scrolling message history, Send, a thinking indicator, clear offline/timeout messages, and a return button. The textarea stays mounted when the phone keyboard opens. A failed request keeps the unsent draft. Each game conversation can continue for several turns before returning to combat; trust gains are bounded per phase.

The game API is separate from QwenLab and exposes only character chat and model readiness. Ollama remains on loopback. A private bearer code protects the relay; browser origins, input length, conversation roles and model updates are checked. Requests have a time limit and one inference runs at a time. Neither the game API nor browser uploads training data or writes conversation logs. Messages pass through the HTTPS relay to the PC for inference. No voice input is used.

### Connect your phone

1. Keep Ollama running with `qwen3:1.7b` installed.
2. Install the official Cloudflare `cloudflared` tool, or use an existing installation.
3. From this game's `backend/` folder, run:

```powershell
.\Start-Phone-Chat.ps1 -CloudflaredPath 'C:\path\to\cloudflared.exe'
```

4. Open `backend/.private/phone-link.html` on the PC. Copy its private game link to your phone. The link pairs that browser automatically; the code is removed from the address bar and retained only for that tab's session.
5. Tap Play, then **Chat with Sharmila · Qwen**, and type a message. The PC, Ollama and relay must stay on. If the PC is asleep or the relay has stopped, chat reports an error and offers retry.

The normal public game URL also works; use **Settings > Connect Qwen on my PC** to enter the HTTPS relay origin and private code manually. Never commit the `.private/` directory or put the code in public documentation. Anyone with your pairing link can use this game connection.

A Cloudflare Quick Tunnel is temporary and is intended for personal testing. Restarting it changes the address; rerun the start script and copy the new phone link. For a permanent address, configure a named Cloudflare Tunnel and domain or host this small authenticated API on a server that can reach the model. GitHub Pages runs the static game; it cannot run Qwen itself. Stop this game's API and relay with `backend/Stop-Phone-Chat.ps1`; Ollama is left running.

This remains a small game rather than the full 20-week production in the brief. The four-weapon inventory, equipable charms, speech pipeline and training-data architecture are future work. The complete five-act story, combat and typed Qwen conversation loop are playable.

## Local development

Open this directory's `project.godot` with Godot 4.7.2 and press F5. No external Python or npm packages are needed. Live character chat requires the separately running PC API described above. Audio files are checked in; `python make_audio.py` regenerates the original synthesized WAVs. The Noto Sans Tamil font is distributed under its included SIL Open Font License.

Run meaningful logic and completion tests:

```sh
godot --headless --editor --path games/life-quest --quit
godot --headless --path games/life-quest --script res://tests/gameplay.gd
python -m unittest discover -s games/life-quest/backend/tests -v
node --check games/life-quest/web/chat.js
```

Run visual captures with a rendering-capable machine:

```sh
mkdir -p games/life-quest/reports
godot --path games/life-quest --script res://tests/visual.gd
```

The tests preserve any existing local save file. Captures cover all stage backgrounds, menus and conversation screens at landscape and portrait sizes. Automated checks are not a replacement for testing a physical iPhone or Android phone.

## Web export and publishing

Install the matching Godot 4.7.2 export templates. From this project's folder:

```sh
mkdir -p build/web
godot --headless --export-release Web build/web/index.html
# Also copy web/chat.js and web/chat.css into build/web/
python -m http.server 8000 --directory build/web
```

Open `http://localhost:8000`; double-clicking HTML is not supported. Compatibility rendering and single-threaded export avoid the need for cross-origin isolation headers. The custom web shell has a user-initiated start, progress reporting, optional full screen and friendly error messages. It requests no microphone permissions. Character messages are sent only to the PC endpoint paired by the player.

The repository's GitHub Actions workflow validates both projects, runs the five-act suite, exports both web games, keeps the existing root prototype URL, and puts this game at `/life-quest/`. Pushes to `main` deploy using the already-configured GitHub Pages environment. A failed validation, test or export prevents deployment.
