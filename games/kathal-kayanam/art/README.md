# Artwork direction and generation prompts

Keep new artwork and its Godot import sidecar together in the folder that matches its use. Store generation prompts and their references separately.

| Folder | Contents |
| --- | --- |
| `art/stages/` | Background paintings for each playable scene |
| `art/characters/` | Cast portraits, sprites, animation sheets, and expressions |
| `art/props/` | Desks, carts, bikes, and other scene objects |
| `art/story/` | Illustrated story scenes |
| `art/ui/` | Title cover and app icon |
| `art/prompts/` | Original instructions for generated assets |
| `audio/music/` and `audio/sfx/` | Score and sound effects |
| `fonts/` | Typefaces and licenses |

The v2 visual pass uses original bitmap artwork created with the built-in ImageGen tool. The complete prompt set is retained verbatim in [prompts.json](prompts/prompts.json). The cover was the visual reference for the environment and character assets.

The direction combines gouache texture, hand-inked animation silhouettes, warm Tamil cinema poster colors, golden stage lighting, teal shadows, coral, jasmine and lived-in Chennai settings. Backgrounds are composed as unobstructed side-view arenas. Character sheets use transparent alpha and are consumed as atlas regions directly by Godot. The original files are retained; the backgrounds use Godot's lossy texture import at 0.85 quality for a smaller web package. Sprite imports preserve alpha and use mipmaps for smoother downscaling on phones.

- `cover-v2.png`: cinema-style title painting, also used by the HTML loading screen and Sharmila chat portrait.
- `school-v2.png`: school corridor with sunlight, arches, notice board and bell.
- `college-v2.png`: engineering-college canteen with brass coffee vessels and bougainvillea.
- `office-v2.png`: blue-hour OMR office with warm task lighting.
- `family-v2.png`: carved teak living room with brassware and evening light.
- `wedding-v2.png`: jasmine and marigold mandapam with warm festive lights.
- `hero_sheet-v2.png`: four outfits, four frames each: idle, two running strides and throw. Stage-to-row mapping is school, college, office/family and wedding.
- `cast_sheet-v2.png`: Sundaram, Kumar, Karthik, Appa, Amma and Sharmila in a 3 by 2 grid.

Production code is in `Main.gd`. The generated atlas grid is interpreted at runtime without modifying the source PNGs. The live Qwen conversation and gameplay state logic are separate from artwork. Original procedural drawing remains as `_background_legacy` and `_character_legacy`; no original project assets were deleted.


## v3 character motion

Generated with the built-in image generation tool, using the existing original sprites as identity and costume references. The art direction takes broad 1930s cartoon movement cues from Cuphead while retaining the original Tamil cast. No franchise sprites were used.

- `hero-run-alpha-v3.png`: transparent 4 by 4 atlas, four consecutive run poses for each of the four original outfits. The first generated sheet had a partial white matte; a second image edit removed it. The unused first variant is outside the repository.
- `master-walk-v3.png`: transparent 2 by 2 patrol walk cycle for Sundaram, matching his original cast portrait.
- Exact generation and alpha-removal prompts: [motion-prompts-v3.json](prompts/motion-prompts-v3.json).

Existing v2 art is preserved. The renderer anchors the body across frame changes and adds landing squash, dash stretch and trails, breath, hit recoil and throw recovery. Run poses are selected by distance travelled; jump and attack states have explicit priority. Atlas source rectangles have a two-pixel inset against frame bleed. Reduce Motion disables the added deformation and trails.
