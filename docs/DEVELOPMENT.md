# Continuing development

## Baseline

The current game is Cascara 0.6, a playable native development build for Godot 4.6 stable. project.godot is the entry point for the editor. No JavaScript package installation is needed.

The repository includes the complete project, source scripts, creature and world data, editable GLB models, normal and shiny rendering, original WAV tracks, notices, and desktop export presets. Standalone Windows and Linux downloads are distributed separately.

## Local setup

1. Install Godot 4.6 stable from the official Godot website.
2. Clone this repository or extract the source archive.
3. Import project.godot into the Godot editor.
4. Let asset imports finish, then run the project with F6 for the current scene or F5 for the project.
5. Install the matching export templates through Godot to export desktop builds.

The scripts are GDScript. The renderer uses the GL compatibility backend. The project targets a 1280 by 800 window.

## Checks and exports

From the project root, with the Godot executable available as godot:

```sh
godot --headless --editor --import --quit
godot --headless -- --self-test
godot -- --city-test
mkdir -p builds/windows builds/linux
godot --headless --export-release Windows builds/windows/Cascara.exe
godot --headless --export-release Linux builds/linux/Cascara.x86_64
```

On Windows, replace godot with the path to the Godot executable and create the build folders in File Explorer or PowerShell. The city test requires a working graphical display. It captures images in Godot's application user-data directory.

Tests create and overwrite save slots in the application's user-data directory. Back up personal saves or use a separate OS user-data location before running them. Do not include any save files in commits.

## Architecture

| Component | Files |
| --- | --- |
| Main game controller, movement, camera, menus, encounters | scripts/adventure.gd |
| Stats, combat rules, breeding, saves | scripts/rpg.gd |
| Towns and interiors | scripts/settlements.gd |
| Routes and Gym scenery | scripts/scenery.gd |
| Paged dialogue and response buttons | scripts/conversation.gd |
| Creature models and shiny palettes | scripts/fauna.gd |
| Four creature rigs | scripts/creature_motion.gd |
| Character walking animation | scripts/walker.gd |
| Shiny sparkle effect | scripts/shimmer.gd |
| Species, world, trainers, campaign | data/cascara.json |

## Completed in 0.6

- Continuous movement with diagonal input and collision checks.
- A centred camera at a constant overworld angle and distance.
- Twelve town exteriors with Centres, Marts, homes, and field stations.
- Sixty-four service and residential interiors plus the existing eight Gyms.
- Storage PCs inside healing centres instead of outdoor NPCs.
- Twelve saved town errands with item or creature rewards and duplicate-reward prevention.
- Alternate shiny palettes for all 109 species, star markers, sparkles, and summary portraits.
- Paged NPC conversations and battle messages.
- Fractional-position save support and whole-number creature field normalisation.

## Verified baseline

The previous development session passed Godot import, core debug tests, Linux graphical city tests, native Windows and Linux exports, and a Linux exported-runtime smoke test. The graphical test used a virtual display with software rendering. Windows execution on physical hardware has not been verified.

The core test checks the roster, acquisition coverage, campaign links, type rules, IV stats, EV limits, breeding, saves, eight Gym reward paths including doubles, and story gates. It uses a prepared high-level party and is not a campaign balance test.

## Recommended next work

1. Verify a fresh game on Windows, including save and load, indoor PCs, shopping, healing, and the first Gym.
2. Give each town and route a more distinct authored layout while keeping every exit and interaction reachable.
3. Add more NPC routines and dialogue variations, then expand errands beyond the current parcel searches.
4. Rig and animate more of the creature roster. Only the three first-stage starters and Peepuddle currently have articulated rigs.
5. Build authored learnsets and implement the assigned ability interactions that remain data-only.
6. Improve Gym puzzles and older campaign investigations, which still use menus.
7. Add remappable controls, controller support, accessibility options, and a performance pass.

Keep the current source as the starting point. Do not describe the project as a finished commercial release. See docs/HANDOFF.md for broader production priorities and docs/QA.md for test limits.
