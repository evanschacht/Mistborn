# Mistborn

Roblox prototype with metal anchors, targeting beams, and momentum-based pushing and pulling.

## Open the game

Open `Mistborn-Anchor-Prototype.rbxl` in Roblox Studio and press Play. This contains the complete map and scripts; no build step is required.

## Controls

- Hover near a blue cube to select it. Selection stays highlighted when the cursor moves away.
- Lines, selection, and push/pull reach 180 studs from the character center to the anchor center. Leaving range clears the selection and stops force from that anchor; returning requires a new key press.
- Ground push/pull uses a low sliding stance facing travel. The right arm aims at the pull target and the left at the push target. The stance persists through coasting and ends when stopped or airborne; movement tuning is unchanged.
- Hold **Q** to push away from the hovered cube.
- Hold **E** to pull toward the hovered cube.
- Each key locks its own target until released. Hold both to combine forces and steer.
- Use the top-left **Metal Tuning** panel to adjust acceleration, speed targets, gravity assistance, and momentum. Scroll for all ten sliders; click the title to collapse.
- Tuning changes apply immediately for the current play session. Reset restores defaults.

## Files

- `Mistborn-Anchor-Prototype.rbxl`: complete saved Roblox place.
- `src/StarterPlayerScripts/`: readable Luau exports of the scripts embedded in the place. These are not automatically synchronized with Studio.

## Prototype status

Includes 109 metal anchors of varied sizes, soft cylindrical targeting beams, sticky nearest-cursor selection, independent push/pull targets, ground sliding, gradual airborne gravity assistance, and live tuning controls. Movement is currently controlled locally for prototyping.
