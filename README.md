# Mistborn movement prototype

A Roblox Studio prototype for steel pushing, iron pulling, momentum-based movement, and throwable/retrievable coins.

Open **Mistborn-Anchor-Prototype.rbxl** in Roblox Studio and press Play. No external build step is required to play the saved place. The `src/` directory contains readable exports of the project scripts; editing those files alone does not update the place.

Start with [the handoff guide](docs/HANDOFF.md) before changing the game. [AGENTS.md](AGENTS.md) describes the checkpoint requirements.

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

The expandable Metal Tuning panel groups movement, forces, sensing, coins, and pose settings. Each slider supports editable bounds and an individual reset. It also includes a speedometer toggle and shared tuning save.

## Code map

| Location | Responsibility |
| --- | --- |
| [MetalMotion](src/StarterPlayerScripts/MetalMotion.luau) | Player forces, target locking, sliding, tuning snapshots, coin reaction gates |
| [MetalAwarenessClient](src/StarterPlayerScripts/MetalAwarenessClient.client.luau) | Selection, lines, highlights, coin visual proxies and drop shadows |
| [AerialMovement](src/StarterPlayerScripts/AerialMovement.luau) | Ground and air locomotion, gravity/jump tuning, pose coordination |
| [MetalSlideControl](src/StarterPlayerScripts/MetalSlideControl.luau) | Sliding WASD calculations |
| [MetalSlidePose](src/StarterPlayerScripts/MetalSlidePose.luau), [AerialFlightPose](src/StarterPlayerScripts/AerialFlightPose.luau), [CoinTossPose](src/StarterPlayerScripts/CoinTossPose.luau) | Procedural character poses and arm overlays |
| [CoinPouchClient](src/StarterPlayerScripts/CoinPouchClient.client.luau) | Drop input, inventory UI, release prediction and server handoff |
| [CoinPouch server](src/ServerScriptService/CoinPouch.server.luau), [CoinPhysics](src/ServerScriptService/CoinPhysics.luau) | Coin creation, inventory, authoritative motion, contact and retrieval |
| [MetalTuningConfig](src/ReplicatedStorage/MetalTuningConfig.luau) | Factory defaults, schema/migration, sensing range and force/line scaling |
| [MetalTuningPreset](src/ReplicatedStorage/MetalTuningPreset.luau) | Saved tuning values, slider bounds and speedometer setting |
| [MetalTuningPanel](src/StarterPlayerScripts/MetalTuningPanel.client.luau) | Categorized tuning UI |
| [MetalTuningPersistence](src/ServerScriptService/MetalTuningPersistence.server.luau), [MetalTuningMaster](src/ServerScriptService/MetalTuningMaster.luau) | Shared DataStore tuning and revision handling |
| [AerialPhysics](src/ServerScriptService/AerialPhysics.server.luau) | Server gravity and character jump height |
| [MetalForceGeometry](src/ReplicatedStorage/MetalForceGeometry.luau), [CoinRules](src/ReplicatedStorage/CoinRules.luau) | Shared geometry, coin constants and ballistic calculations |
| [map/anchors.json](map/anchors.json) | Exported anchor layout |
| [assets/coin-pouch](assets/coin-pouch/README.md) | Pouch generator, Blender/GLB assets and primitive manifest |
| [tests](tests) | Studio probes, acceptance notes and historical result snapshots |

## Saving and verification

There are three separate kinds of save:

1. **Save Tuning** writes a shared DataStore master configuration when that service is available. It does not commit files to Git.
2. **Studio Save** writes the local place. Keep its project scripts synchronized with `src/` and capture the intended tuning in `MetalTuningPreset` for a portable checkpoint.
3. **Git commit and push** backs up the full project. It does not publish a new Roblox experience version.

The current checked-in tuning is in `MetalTuningPreset`; factory Reset defaults in `MetalTuningConfig` intentionally differ. A successfully loaded DataStore master can override the preset. See the handoff guide for persistence limitations and test caveats.

This is a prototype with Studio-based checks, not an automated CI-tested release. Historical test results are evidence of past runs, not proof that the current environment has been retested.
