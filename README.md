# Kalyana Kathal: The Life Quest

**New five-act mobile game:** [Play the Life Quest](https://yeswanth1570.github.io/kalyana-kathal/life-quest/) · [Source and controls](games/life-quest/README.md)

The new game lives in `games/life-quest/` and includes School, College, Office, Family and Wedding encounters, touch controls, settings, local progress and original art/audio. The original college prototype below remains available at the site root URL.

A Godot 4.7.2 prototype for a 2D college-corridor action and dialogue game.

## Play in Godot

1. Open `project.godot` in Godot 4.7.2.
2. Press **F6** to run the corridor scene, or **F5** to run the project.

## Controls

| Action | Keyboard |
| --- | --- |
| Move | A / D or arrow keys |
| Jump | Space / W |
| Dash | Shift |
| Throw love letter | J / X |
| Open dialogue | R |
| Choose a reply | 1, 2, or 3 |
| Retry after an outcome | Enter |

## Build pipeline

GitHub Actions validates the Godot project and exports a browser build plus a Windows desktop build whenever changes are pushed to `main` or a pull request targets `main`. The resulting `KalyanaKathal-Web` and `KalyanaKathal-Windows` artifacts are available from the workflow run for 30 days.

The browser build is a static Godot web export; run it through a web server. The pipeline does not collect or upload player voice.

## Design scope

The first slice covers the college corridor encounter. The five-act story outline and visual goals are in [DESIGN.md](DESIGN.md). Voice input and AI-generated dialogue are not part of this prototype.
