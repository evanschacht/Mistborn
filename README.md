# Mistborn

Roblox prototype with metal anchors, targeting beams, and momentum-based pushing and pulling.

## Open the game

Open `Mistborn-Anchor-Prototype.rbxl` in Roblox Studio and press Play. This contains the complete map and scripts; no build step is required.

## Controls

- Hover near a blue cube to select it. Selection stays highlighted when the cursor moves away.
- Lines, selection, and push/pull reach 180 studs from the character center to the anchor center. Leaving range clears the selection and stops force from that anchor; returning requires a new key press.
- Ground push/pull uses a low sliding stance facing travel. The right arm aims at the pull target and the left at the push target. The stance persists through coasting and ends when stopped or airborne.
- Hold **Q** to push away from the hovered cube.
- Hold **E** to pull toward the hovered cube.
- Each key locks its own target until released. Hold both to combine forces and steer.
- Use the top-left **Metal Tuning** panel for eleven sliders. Pull/Push top speed now caps powered ground sliding; acceleration changes the time needed to reach it. With both keys held, forces combine and the higher active cap is used.
- **Slide friction** controls coasting after release. **Slide stop cutoff** snaps released ground motion to zero below the selected speed (default 5 studs/s). Set friction to 0 for no coasting resistance, or cutoff to 0 for no appreciable stop snap.
- Each slider has editable **Min**, **Max**, and current-value boxes. Enter a number and press Enter or leave the box. Invalid ranges revert; ranges must be nonnegative, increasing, and at most 10,000. Gravity assistance stays within 0–100%, and gravity buildup must remain positive.
- The **Speedometer** switch shows a circular meter at the bottom right, reporting total measured velocity in studs per second (including vertical motion).
- Tuning changes apply immediately for the current play session. Reset restores defaults.

The 180-stud anchor range still applies. For example, reaching 400 studs/s from rest at 50 studs/s² needs 8 seconds and about 1,600 studs of uninterrupted travel, so a nearby stationary anchor can end the pull before that speed is reached. Collisions and airborne gravity can also affect measured speed.

## Files

- `Mistborn-Anchor-Prototype.rbxl`: complete saved Roblox place.
- `src/StarterPlayerScripts/`: readable Luau exports of the scripts embedded in the place. These are not automatically synchronized with Studio.

## Prototype status

Includes 109 metal anchors of varied sizes, soft cylindrical targeting beams, sticky nearest-cursor selection, independent push/pull targets, ground sliding, gradual airborne gravity assistance, and live tuning controls. Movement is currently controlled locally for prototyping.
