# Working on Cascara

Cascara is a native Godot 4.6 game. Keep the project editable in Godot and exportable for Windows and Linux. The active scene is main.tscn and its controller is scripts/adventure.gd.

## Before changing the game

Read README.md, docs/DEVELOPMENT.md, and docs/QA.md. Inspect the relevant scripts before proposing changes. Continue from the existing game rather than replacing it with a browser prototype.

## Gameplay and art direction

- Keep the cartoon and animated feel of the creatures and environment.
- Preserve free movement, diagonal input, collisions, and a camera that holds the player in the middle at a constant angle and distance.
- Towns need enterable buildings, indoor shopkeepers, healing centres, and storage PCs inside the centres.
- Use paged dialogue for conversations and battle messages.
- Preserve normal and shiny variants, shiny save persistence, and one-time quest rewards.
- Keep Antlerath's Pressure and Voltaryn's and Stratovar's Intimidate assignments.
- Preserve daycare, breeding, IVs, EVs, natures, catching, storage, and save compatibility.

## Engineering

Keep combat rules in scripts/rpg.gd separate from presentation where practical. Preserve existing save files and fractional player positions. Avoid broad rewrites unless the requested change requires one. Run the tests that cover the behavior changed, and report any checks that could not run.

Use Godot 4.6 stable with matching export templates. Import before running headless tests. The city test needs a graphical display and must be run with --city-test. Isolate test saves from personal play saves.

Keep first-party documentation clear and factual. Do not use em dashes. Keep credentials, personal saves, logs, editor caches, and build binaries out of git. Retain required dependency and asset notices. Do not claim that this development build is a finished release or that untested behavior has been verified.
