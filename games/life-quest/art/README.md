# Artwork direction and generation prompts

The v2 visual pass uses original AI-generated bitmap artwork created with the built-in ImageGen tool. The complete prompt set is retained verbatim in [prompts.json](prompts.json). The cover was the visual reference for the environment and character assets.

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
