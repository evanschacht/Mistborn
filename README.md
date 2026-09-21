# Mistborn

Roblox prototype with metal anchors, targeting beams, and momentum-based pushing and pulling.

## Open the game

Open `Mistborn-Anchor-Prototype.rbxl` in Roblox Studio and press Play. This contains the complete map and scripts; no build step is required.

## Controls

- Every metal anchor in sensing range has a thin blue outline visible through walls. The selected anchor has a brighter, thicker outline and a highlighted fill. Hover near a blue cube to select it; selection stays highlighted when the cursor moves away.
- **Steel and iron range** adjusts blue lines, selection, and push/pull reach together, measured from character center to anchor center. Default: 180 studs; initial slider range: 0–500, with editable Min/Max. Leaving range clears selection and stops force from that anchor; returning requires a new key press.
- Ground push/pull uses a low sliding stance facing travel. The right arm aims at the pull target and the left at the push target. The stance persists through coasting and ends when stopped or airborne.
- Hold **Q** to push away from the highlighted cube, even with the mouse elsewhere.
- Hold **E** to pull toward the highlighted cube, even with the mouse elsewhere.
- Each key locks its own target until released. Hold both to combine forces and steer.
- Use the top-left **Metal Tuning** panel for seven sliders. Pull/Push top speed now caps powered ground sliding; acceleration changes the time needed to reach it. With both keys held, forces combine and the higher active cap is used.
- **Slide friction** controls coasting after release. **Slide stop cutoff** snaps released ground motion to zero below the selected speed (default 5 studs/s). Set friction to 0 for no coasting resistance, or cutoff to 0 for no appreciable stop snap.
- Each slider has editable **Min**, **Max**, and current-value boxes. Enter a number and press Enter or leave the box. Invalid ranges revert; ranges must be nonnegative, increasing, and at most 10,000.
- The **Speedometer** switch shows a circular meter at the bottom right, reporting total measured velocity in studs per second (including vertical motion).
- **Save Metal Tuning**, beneath Reset All, saves values, slider Min/Max bounds, and speedometer visibility to one master configuration for all players. Saving applies it immediately to this server; other live servers refresh within about 30 seconds. New sessions load the master configuration. Save failures are shown explicitly; unsaved changes remain temporary.
- Each slider has **Reset to Default**, restoring only its original value and range. Reset All restores all original slider defaults. Resetting does not overwrite the master configuration until you press Save.
- The project includes the captured tuning preset: range 290, push/pull acceleration 230, slide friction 1.5, stop cutoff 30, and speedometer on. Other values retain their original defaults. This preset loads when no master configuration exists.
- Studio persistence requires Game Settings → Security → **Enable Studio Access to API Services**. Published games use Roblox DataStoreService. The master configuration is shared across Studio and the published experience; old per-player profiles are no longer read; the in-game Save button does not commit to GitHub or rewrite the place file.

The selected anchor range still applies. For example, reaching 400 studs/s from rest at 50 studs/s² needs 8 seconds and about 1,600 studs of uninterrupted travel, so a nearby stationary anchor can end the pull before that speed is reached. Collisions and airborne gravity can also affect measured speed.

## Files

- `Mistborn-Anchor-Prototype.rbxl`: complete saved Roblox place.
- `src/StarterPlayerScripts/`: readable Luau exports of the scripts embedded in the place. These are not automatically synchronized with Studio.
- `src/ReplicatedStorage/`: tuning schema, validation, and captured startup preset.
- `src/ServerScriptService/`: validated, rate-limited master configuration persistence.

## Prototype status

Includes 109 metal anchors of varied sizes, soft cylindrical targeting beams, sticky nearest-cursor selection, independent push/pull targets, ground sliding, continuous gravity, and live tuning controls. Movement is currently controlled locally for prototyping.

Only the experience owner (or owning group owner) may save master tuning in published servers. Studio testing also permits saves. Other players receive the master settings without the tuning editor. Unsaved owner edits are local previews.

## Gravity and force direction

Gravity always acts at Workspace.Gravity. Every physics step recomputes the direction from the player to each held anchor; pull adds acceleration along that direction and push adds acceleration opposite it. The resulting upward component must exceed gravity to lift the player. No automatic weight support, vertical drag, or off-axis braking cancels falling. Released air motion retains normal vertical gravity; slide/coast friction acts horizontally only.

The former gravity assistance, assistance buildup, momentum braking, and airborne drag sliders were removed. Older saved configurations remain compatible: obsolete fields are ignored. Strength, top speed, range, slide friction, and stop cutoff are preserved.
