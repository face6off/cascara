# Cascara source handoff

## Build

Use Godot 4.6 stable and its matching export templates. From the project folder:

```sh
godot --headless --editor --import --quit
godot --headless -- --self-test
godot --headless --export-release Windows builds/Cascara.exe
godot --headless --export-release Linux builds/Cascara.x86_64
```

Create the output folders first. The Windows preset embeds the game pack in the executable. The renderer uses Godot's compatibility backend to support a wider range of desktop graphics hardware.

## Release scope

The native edition is a playable foundation with a connected campaign. A studio can open it in the editor, inspect the code and data, replace the procedural scene construction with authored scenes, and continue production. It should be evaluated as a development handoff, not a finished gold-master build.

## Production priorities

1. Play the campaign from a clean save with all three starters. Tune encounter frequency, experience, trainer teams, capture odds, and economy from observed playtime.
2. Replace shared map layouts with authored terrain, collision, buildings, ferry travel, weather, and scene-specific landmarks. Review all 24 routes and 14 dungeons individually.
3. Finish the 77 category-based creature representations, rig the full roster, and author walking, idle, attack, hit, faint, and capture animations. Add trainer portraits and cinematic blocking.
4. Author legal level-up learnsets, reusable TMs, egg moves, move reminder behavior, full signature moves, and all assigned ability interactions. Keep combat rules separate from animation.
5. Stage quests with world clues and character scenes. Add dialogue variants after badges, rescues, legendary trials, and the League.
6. Expand native tests to fresh-player campaign simulation, all ability interactions, failed imports, interrupted writes, invalid item use, breeding limits, and every soft-lock state.
7. Test on Windows hardware, controllers, different resolutions, and lower-end GPUs. Add remappable controls, text scaling, color-safe puzzle cues, and reduced effects.
8. Add release artwork, versioned save migrations, crash reporting choices, installer packaging, signing, and a support plan before public release.

## Known simplifications

The project does not claim exact rules parity with every Pokemon generation. It uses a six-stat IV/EV model and familiar type relationships, with draft move sets, simplified status timing, and a limited ability resolver. Egg compatibility uses one authored group per species. Capture uses a simplified chance model. Trading, multiplayer, cloud persistence, and platform achievements are absent.

Tests can run headlessly, but a passing headless test is not evidence that the graphics or complete player experience have been verified. The provided QA record states what was actually checked.

## Assets and dependencies

Godot is licensed under MIT. GLB models are simplified geometric representations carried over from the browser project; additional creatures are assembled procedurally in Godot. Three original music arrangements were rendered into WAV assets. The concept board is a design reference and is not a model sheet or animation atlas.

Keep engine notices with builds. Do not add a claim of official franchise affiliation. Returning Pokemon are fan-game content and are not an original intellectual-property roster for commercial use.
