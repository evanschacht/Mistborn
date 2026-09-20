# Mistborn

Roblox prototype with metal anchors, targeting beams, and momentum-based pushing and pulling.

## Open the game

Open `Mistborn-Anchor-Prototype.rbxl` in Roblox Studio and press Play. This contains the complete map and scripts; no build step is required.

## Controls

- Hover near a blue cube to select it. Selection stays highlighted when the cursor moves away.
- Hold **Q** to push away from the hovered cube.
- Hold **E** to pull toward the hovered cube.
- Each key locks its own target until released. Hold both to combine forces and steer.
- While airborne after using metal, **WASD** gently steers relative to the camera.
- **Double-tap W/A/S/D** for an additive directional air boost with a small upward kick. One boost per airtime, with a 1.2-second cooldown.
- Releasing Q/E preserves aerial momentum. Gravity carries you through the apex into a fall.
- Use the top-left **Metal Tuning** panel to adjust acceleration, speed targets, aerial gravity, steering, lean, and ground slowdown. Scroll for all ten sliders; click the title to collapse.
- Tuning changes apply immediately for the current play session. Reset restores defaults.

## Files

- `Mistborn-Anchor-Prototype.rbxl`: complete saved Roblox place.
- `src/StarterPlayerScripts/`: readable Luau exports of the scripts embedded in the place. These are not automatically synchronized with Studio.
- `src/ReplicatedStorage/AllomancyConfig.luau`: commented aerial settings shared by client and server.
- `src/ServerScriptService/AllomancyBoost.server.luau`: boost validation and cooldown/airtime enforcement. The place also contains the `ReplicatedStorage.AllomancyBoost` RemoteEvent.
- `tests/AerialAcceptance.client.luau`: Studio-only acceptance harness; it is deliberately excluded from the saved game.

## Prototype status

Includes 109 metal anchors of varied sizes, soft cylindrical targeting beams, sticky nearest-cursor selection, independent push/pull targets, ground sliding, ballistic aerial movement, steering, limited air boosts, and live tuning controls.

The existing locally owned character physics remains in place. Boost requests are validated on the server (direction, grounded/alive state, cooldown, one per airtime, and fixed impulse size); this is not a complete server-authoritative movement or anti-cheat system. Live sliders affect the current client session; boost limits use the shared configuration defaults.

To run the acceptance harness, temporarily insert it as a LocalScript under StarterPlayerScripts, then Play. It teleports the test character and temporarily moves one anchor, logs assertions, and writes JSON results to the Workspace AerialTestResults attribute. Stop Play and remove the harness before saving or publishing.
