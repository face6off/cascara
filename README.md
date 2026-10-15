# Cascara

A 3D creature adventure for Windows and Linux, built with Godot 4.6.

Explore a coastal region, build a team, challenge eight Gyms, and help the people you meet along the way. Cascara includes 99 regional creatures and ten returning Pokémon.

## Play

Extract the game download and launch `Cascara.exe` on Windows or `Cascara.x86_64` on Linux. On Linux, you may need to enable permission to run the file. The editor is not required.

| Control | Action |
| --- | --- |
| WASD or arrow keys | Walk freely, including diagonally |
| E | Talk or examine nearby objects |
| E, Space, or Enter | Reveal dialogue, then advance to the next page |
| Mouse | Choose a response or menu action |
| P | Open the party |
| Escape | Close a menu |

The camera follows at a constant angle and distance, keeping the player centred. Walk through a building's doorway to enter. Walk onto the exit mat to leave. Trail signs at the edges of outdoor areas lead to the next map.

## Town life

All 12 towns have a red-roofed Pokémon Centre, a separate blue-roofed Poké Mart, two homes, and a field station. Towns without a Gym also have an enterable community hall. There are 64 new service and residential interiors, in addition to the eight Gyms.

The nurse restores your team's HP, status, and move PP. The storage PC is a computer inside the Centre. Shops sell supplies from a counter. Noor's daycare and Elin's training service are inside Alderwick's Trail House.

Visit the resident's home in each town for an errand. Accept the request, find the labelled parcel on the named route, and return to the resident. The Journal button tracks accepted errands. Rewards are granted once; a full party sends a creature reward to storage. If both are full, the resident holds the reward for you.

Mara in Brackenbay rewards Eevee, June in Millford rewards Lotad, and Ada in Mossmere rewards Ralts. Other residents offer Potions or Great Balls.

## Shiny variants

Every species has an alternate palette, a star marker, and a sparkle effect. Shiny colours appear on battle models and summary portraits. Wild generation uses a 1 in 4,096 shiny roll. A creature keeps its shiny state through saving, storage, and evolution. Shiny colours do not change stats.

## Development

Open `project.godot` in Godot 4.6 stable. Install the matching export templates to build standalone executables.

```sh
godot --headless --editor --import --quit
godot --headless -- --self-test
# Run with a graphical display:
godot -- --city-test
mkdir -p builds/windows builds/linux
godot --headless --export-release Windows builds/windows/Cascara.exe
godot --headless --export-release Linux builds/linux/Cascara.x86_64
```

Tests write saves to Godot's user-data directory. Use a separate user-data location for tests if you have a personal save to preserve.

| File | Purpose |
| --- | --- |
| `scripts/adventure.gd` | World, menus, encounters, quests, movement, and camera |
| `scripts/rpg.gd` | Combat rules, creature data, breeding, and saves |
| `scripts/settlements.gd` | Town exteriors and building interiors |
| `scripts/conversation.gd` | Paged dialogue and response choices |
| `scripts/fauna.gd` | Creature models and shiny palettes |
| `scripts/creature_motion.gd` | Articulated starter and Peepuddle animation |
| `data/cascara.json` | Species, world, trainers, and campaign records |

## Current scope

This is a playable development build. The campaign graph, eight Gyms, catching, storage, daycare, eggs, IVs, EVs, training, and local saves are connected. Towns now have functional buildings, but share a base street layout with regional colours and details. Most routes still use shared scenery. Four creatures have articulated rigs; the remaining roster needs more animation work.

Learnsets and several combat rules are simplified, and only some assigned abilities have executable effects. The older campaign investigations still use menu steps. Controller support, multiplayer, cloud saves, and a full fresh-player balance pass remain unfinished. Windows builds are unsigned and need testing on Windows hardware.

This is an unofficial fan project. Pokémon names and designs belong to their respective rights holders. Keep `THIRD-PARTY-NOTICES.txt` and `GODOT-COPYRIGHT.txt` with distributed builds.
