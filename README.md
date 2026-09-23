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
- Use the top-left **Metal Tuning** panel for ten sliders. Pull/Push top speed now caps powered ground sliding; acceleration changes the time needed to reach it. With both keys held, forces combine and the higher active cap is used.
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

## Distance falloff

Force falloff, Close clamp distance, and Far clamp distance affect both push and pull. Defaults are 1, 5 studs, and 150 studs. Acceleration sliders specify full close-range strength. The multiplier is 1 / (1 + falloff * (clampedDistance / closeClamp - 1)); falloff 1 is inverse-linear, 0 is constant, and higher values weaken force faster. Close distance prevents spikes; far distance stops further weakening. If far is set below close, its effective value is close. Steel and iron range overrides both clamps: at or beyond that range, force is zero, lines/outlines disappear, selection clears, and held targets release.

Older saved master configurations acquire the three new defaults while preserving their existing values. Each new control supports editable Min/Max, individual reset, and Save Metal Tuning like the other controls.

When the character is above an anchor and any part of the HumanoidRootPart body footprint overlaps the anchor's projected footprint, its force is exactly vertical: push up, pull down. Rotated blocks use their actual projected shape. Fully leaving the footprint restores the center-directed force. Existing lateral momentum is preserved; the force adds no sideways drift while overlapping. Visual beams, distance falloff, and range still measure to the center.

### Aerial movement reference pass
Gravity is continuously 60 studs/s², with an 8-stud jump (about one second airborne). `AerialMovement` adds camera-relative keyboard/gamepad steering at 85 studs/s² toward 32 studs/s along the input direction. It preserves faster metal momentum and leaves vertical velocity to gravity and metal forces. Released airborne drag is 0.15; the existing slide-friction tuning now affects the ground only. The procedural R15 airborne pose blends into raised arms and tucked knees, restores on landing, and faces horizontal travel. This is an approximation of the recording, not the original animation asset. Custom touch steering and remote-player replication of the procedural pose are not included in this pass.

Validation: live jump height 8.19 studs, airtime 1.016 s, landing restored WalkSpeed 16; steering integration reached 32; input in the same direction preserved 160 studs/s metal momentum; opposite input decelerated it. Live keyboard steering reached 21.49 studs/s in Freefall with no client errors.

Air-input fix: the late render update now retains the steering command computed for the current frame instead of replacing it with old measured velocity. Facing follows actual horizontal travel for walking, sliding, coasting and flight. Jump-first tests (Space, wait 250 ms, then each WASD key for 500 ms) produced 21.0–21.75 studs/s; facing dot products exceeded 0.99999 in every direction. Landing restored WalkSpeed 16, with no client errors.

Faster aerial tuning: air speed 64 (was 32), acceleration 240 (was 85), same gravity and drag. Both airborne shoulders have a local 180-degree twist so bent forearms point forward. The same jump-first 500 ms WASD tests reached 61.76–63.45 studs/s instead of 21–22, maintaining facing alignment above 0.99999 with no client errors. Approach informed by independent air-control/friction parameters in Epic's CharacterMovementComponent documentation: https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UCharacterMovementComponent .
