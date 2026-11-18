# Kalyana Kathal The Life Quest

A separate five-act Godot 4.7.2 game based on the supplied Kalyana Kathal design brief. The original college prototype and its assets remain at the repository root.

Play at **https://yeswanth1570.github.io/kalyana-kathal/life-quest/**. Tap Play, choose an unlocked act, then tap Action. Landscape is recommended on phones; portrait layouts also work. The first load includes the Godot WebAssembly runtime, so allow the loading bar to finish.

## What is playable

Five complete encounters: School, College, Office, Family and Wedding. Each has a setting, character art, different projectiles, three conversations, consequences for replies, a recoverable trust loop, a stage ending and an unlockable next act. Murugan changes outfits as the story advances. Jump, dash with a cooldown, parry pink petals, throw letters, use one healing tiffin, and pause at any time. Original drawn vector art, character animation, confetti and music are included.

Auto fire and Gentle mode are enabled by default. Change them in Settings. Reduce Motion disables shake and film texture animation. Progress and settings save locally; clearing browser site data resets them. Replay unlocked acts from the selection menu.

## Controls

Touch: hold left/right, tap Jump/Dash/Parry, hold Letter when auto fire is disabled. Multiple fingers work independently. The Tiffin button heals two HP once per act. Speak opens an early conversation when the gold meter is full.

Keyboard: A/D or Left/Right to move; Space jump; Shift dash; J/X fire; W/S or Up/Down to aim; K parry; H heal; R speak; Escape/P pause. In conversations choose 1/2/3 or type a reply. Text input consumes number keys normally.

## Dialogue and scope

This is a complete small browser game, not the 20-week production described in the brief. Dialogue uses authored branches and a small deterministic keyword evaluator for English, Tanglish and Tamil; it is clearly labeled in game. It does not call an LLM, record voice, use speech synthesis, collect training data, or upload analytics. There are no API keys in the client. Live AI voice would require a separately deployed authenticated backend, STT/LLM/TTS providers and a deliberate consent design.

The affection projectiles reduce a comic resistance shield. Trust comes from listening and respecting choices. Sharmila's autonomy remains part of the story. Weapons have stage-specific visual themes; the four-weapon inventory, equipable charm system and data-training architecture in the brief are future production work.

## Local development

Open this directory's `project.godot` with Godot 4.7.2 and press F5. No external packages are needed. Audio files are checked in; `python make_audio.py` regenerates the original synthesized WAVs. The Noto Sans Tamil font is distributed under its included SIL Open Font License.

Run meaningful logic and completion tests:

```sh
godot --headless --editor --path games/life-quest --quit
godot --headless --path games/life-quest --script res://tests/gameplay.gd
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
python -m http.server 8000 --directory build/web
```

Open `http://localhost:8000`; double-clicking HTML is not supported. Compatibility rendering and single-threaded export avoid the need for cross-origin isolation headers. The custom web shell has a user-initiated start, progress reporting, optional full screen and friendly error messages. It requests no microphone permissions and has no network service beyond serving the game assets.

The repository's GitHub Actions workflow validates both projects, runs the five-act suite, exports both web games, keeps the existing root prototype URL, and puts this game at `/life-quest/`. Pushes to `main` deploy using the already-configured GitHub Pages environment. A failed validation, test or export prevents deployment.
