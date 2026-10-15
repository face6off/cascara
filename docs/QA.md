# Validation

Engine: Godot 4.6 stable. Renderer: GL compatibility. Targets: Windows and Linux x86-64.

The core test covers the 109-species roster, acquisition paths, campaign links, elemental rules, IV stats, EV limits, breeding, save round trips, eight Gym reward paths including doubles, story gates, and model loading.

The city test checks all 12 towns and 64 new interiors for reachable service doors and NPCs. It verifies that outdoor storage and shop NPCs are gone, that Centres contain a nurse and PC, and that entering and leaving returns to the correct doorway. It checks continuous diagonal movement, constant camera orientation, player centring, fractional-position saves, and building collisions.

Quest checks cover item collection, saved progress, creature and item rewards, and prevention of duplicate rewards. Shiny checks cover model creation for all species, save persistence, battle palettes, star labels, and a rendered summary portrait. NPC dialogue and an animated battle are exercised with the graphical test.

Tests use a virtual Linux display with software rendering. Windows hardware execution, real audio output, physical-device performance, controller support, and a fresh-player campaign playthrough remain outside this validation. The high-level Gym test checks progression, not balance.
