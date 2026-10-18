# Mistborn movement prototype

A Roblox Studio prototype for steel pushing, iron pulling, momentum-based movement, and throwable/retrievable coins.

Open **Mistborn-Anchor-Prototype.rbxl** in Roblox Studio and press Play. Choose **Dev Mode** from the entry menu to play the existing development map. No external build step is required to play the saved place. The `src/` directory contains readable exports of the project scripts; editing those files alone does not update the place.

Start with [the handoff guide](docs/HANDOFF.md) before changing the game. [AGENTS.md](AGENTS.md) describes the checkpoint requirements.

**Tutorial Level** opens an isolated tutorial map: an empty baseplate with a huge medieval stone wall. In a published Roblox client, the server reserves a fresh server of this same place and teleports the player there; no second place ID is needed. The destination builds its tutorial world before spawning the player. Dev Mode keeps the existing development map in the current server.

Studio cannot test real teleports. In a fresh single-player Play session, choosing Tutorial Level previews the isolated tutorial map locally in that test server. Stop Play to return to the saved development map. Studio preview is rejected if Dev Mode has already started or other players are present. Published server travel still needs verification in the Roblox client.

## Controls

| Input | Action |
| --- | --- |
| Mouse near a metal object | Select it; selection persists when the pointer moves away |
| Hold Q | Push on the selected object |
| Hold E | Pull on the selected object |
| R | Take and drop a coin; presses during the animation are ignored |
| WASD / Space | Walk, steer in the air, and jump |
| WASD while sliding | W boosts while powered or reduces coasting drag; S brakes; A/D steer |

Q and E lock their targets independently when pressed. Selecting another object does not change an ongoing push or pull. Selected, pushed, and pulled objects can all be highlighted simultaneously.

The expandable Metal Tuning panel groups movement, forces, sensing, coins, and pose settings. Each slider supports editable bounds and an individual reset. Resets restore the saved settings used at join, including saved slider bounds; Reset all also restores the saved speedometer setting. It also includes a speedometer toggle and shared tuning save.

## Code map

| Location | Responsibility |
| --- | --- |
| [EntryMenu](src/ReplicatedFirst/EntryMenu.client.luau) | Initial Dev Mode / Tutorial Level menu, loading/error feedback, camera and input gating |
| [EntryFlow](src/ServerScriptService/EntryFlow.server.luau), [EntryFlowConfig](src/ServerScriptService/EntryFlowConfig.luau) | Server admission, same-place reserved tutorial travel, join validation and manual respawn |
| [TutorialWorld](src/ServerStorage/TutorialWorld.luau) | Tutorial baseplate, spawn and medieval stone wall builder |
| [MetalMotion](src/StarterPlayerScripts/MetalMotion.luau) | Player forces, target locking, sliding, tuning snapshots, coin reaction gates |
| [MetalAwarenessClient](src/StarterPlayerScripts/MetalAwarenessClient.client.luau) | Selection, lines, highlights, coin visual proxies and drop shadows |
| [AerialMovement](src/StarterPlayerScripts/AerialMovement.luau) | Ground and air locomotion, gravity/jump tuning, pose coordination |
| [MetalSlideControl](src/StarterPlayerScripts/MetalSlideControl.luau) | Sliding WASD calculations |
| [MetalSlidePose](src/StarterPlayerScripts/MetalSlidePose.luau), [AerialFlightPose](src/StarterPlayerScripts/AerialFlightPose.luau), [CoinTossPose](src/StarterPlayerScripts/CoinTossPose.luau) | Procedural character poses and arm overlays |
| [CoinPouchClient](src/StarterPlayerScripts/CoinPouchClient.client.luau) | Drop input, inventory UI, release prediction and server handoff |
| [CoinPouch server](src/ServerScriptService/CoinPouch.server.luau), [CoinPhysics](src/ServerScriptService/CoinPhysics.luau) | Coin creation, inventory, authoritative motion, contact and retrieval |
| [MetalTuningConfig](src/ReplicatedStorage/MetalTuningConfig.luau) | Schema/migration fallbacks, sensing range and force/line scaling |
| [MetalTuningPreset](src/ReplicatedStorage/MetalTuningPreset.luau) | Saved tuning values, slider bounds and speedometer setting |
| [MetalTuningPanel](src/StarterPlayerScripts/MetalTuningPanel.client.luau) | Categorized tuning UI |
| [MetalTuningPersistence](src/ServerScriptService/MetalTuningPersistence.server.luau), [MetalTuningMaster](src/ServerScriptService/MetalTuningMaster.luau) | Shared DataStore tuning and revision handling |
| [AerialPhysics](src/ServerScriptService/AerialPhysics.server.luau) | Server gravity and character jump height |
| [MetalForceGeometry](src/ReplicatedStorage/MetalForceGeometry.luau), [CoinRules](src/ReplicatedStorage/CoinRules.luau) | Shared geometry, coin constants and ballistic calculations |
| [map/anchors.json](map/anchors.json) | Exported anchor layout |
| [assets/coin-pouch](assets/coin-pouch/README.md) | Pouch generator, Blender/GLB assets and primitive manifest |
| [assets/tutorial-wall](assets/tutorial-wall/README.md) | Tutorial wall generator, optimized mesh exports and Roblox primitive manifest |
| [tests](tests) | Studio probes, acceptance notes and historical result snapshots |

## Saving and verification

There are three separate kinds of save:

1. **Save Tuning** writes a shared DataStore master configuration when that service is available. It does not commit files to Git.
2. **Studio Save** writes the local place. Keep its project scripts synchronized with `src/` and capture the intended tuning in `MetalTuningPreset` for a portable checkpoint.
3. **Git commit and push** backs up the full project. It does not publish a new Roblox experience version.

The current checked-in tuning is in `MetalTuningPreset`, which provides both join settings and reset defaults. A successfully loaded or saved DataStore master replaces both together. Local previews and failed saves leave reset defaults unchanged. `MetalTuningConfig.Specs` retains fallback values for schema migration. See the handoff guide for persistence limitations and test caveats.

This is a prototype with Studio-based checks, not an automated CI-tested release. Historical test results are evidence of past runs, not proof that the current environment has been retested.
