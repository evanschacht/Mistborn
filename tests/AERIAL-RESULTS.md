# Aerial movement checkpoint — 2026-09-20

## Cause and changes

The previous MetalMotion applied horizontal drag after release, full-vector drag while held, and strong off-axis braking with up to 98% gravity support. The normal Humanoid controller also fought force-driven motion. Together these caused braking and a misleading hover/standing phase.

MetalMotion now uses one mass-scaled VectorForce physics loop, continuous gravity, and camera-relative acceleration. Its render hook synchronizes the normal walking controller with the current trajectory, preventing default controls from braking aerial momentum. Q/E retain separate target locks. Stop removes only the selected ability target; it does not write velocity. Ground drag remains ground-only.

Presentation layers a small procedural lean over the current animation in PreSimulation and removes the preceding offset before the next Animator update. Both Motor6D and the current avatar's AnimationConstraint are supported. This follows [Roblox's animation-joint guidance](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint/MaxForce). The physics root is not tilted.

Changed: MetalMotion, MetalAwarenessClient (WASD routing through existing input listeners), MetalTuningPanel (control hints). Added: shared AllomancyConfig, AllomancyBoost RemoteEvent, and server boost validator. All 109 anchors and targeting visuals remain intact.

## Default tuning

| Setting | Value |
|---|---:|
| EffectiveGravityMultiplier | 0.8 |
| GravityTransitionTime | 0.3 s |
| AirAcceleration | 28 studs/s² |
| AirTurnStrength | 0.65 |
| MaximumHorizontalSpeed | 140 studs/s, soft steering/boost ceiling |
| AirBoostSpeed | 28 studs/s added |
| AirBoostUpwardSpeed | 16 studs/s added |
| AirBoostCooldown | 1.2 s |
| DoubleTapWindow | 0.25 s |
| OneBoostPerAirtime | true |
| CharacterTiltAmount | 10° procedural lean |
| CharacterTiltResponsiveness | 8 |
| GroundCoastDrag | 2.3 |
| Push/PullAcceleration | 340 studs/s² each |
| Push/PullSpeed | 160 studs/s thrust target each |

The soft ceiling limits additional acceleration; it never clamps existing momentum. Push/pull retain their own speed targets. Live UI sliders are session-local; shared boost settings are edited in AllomancyConfig.

## Studio acceptance results

All 21 assertions passed in the final instrumented playtest. Inputs were driven through the same Motion input methods used by the keyboard handlers; the boosts traveled through the real client/server RemoteEvent. These are Studio character-physics tests, not a network-latency or multiplayer load test.

| Test | Result |
|---|---|
| Diagonal push, then release | Passed. Release velocity (71.05, 36.22, -0.03) studs/s; immediate release changed no velocity component. |
| Forward momentum | Passed. Horizontal X speed 71.05 → 71.57 over ~0.8 s; no forced stop. |
| Apex and accelerating fall | Passed. Y samples +5.11 → -5.44 → -16.63; no zero-velocity hold. Measured vertical acceleration -158.52 studs/s², close to 0.8 × 196.2. |
| Left/right steering | Passed. X changed -6.95 → +8.00; forward Z remained approximately -67 to -68 studs/s. |
| W boost | Passed; forward component 26.39 studs/s after observation delay. |
| A boost | Passed; left component 25.33 studs/s. |
| S boost | Passed; backward component 23.95 studs/s. |
| D boost | Passed; right component 25.65 studs/s. |
| Cooldown | Passed after each of the four boosts. |
| One boost per airtime | Passed, including waiting past cooldown while still airborne. |
| Landing reset | Passed before each directional boost; next airtime allowed a new boost. |
| Airborne state and lean | Passed. Freefall, PlatformStand false, visible joint transform changed. Total animation-plus-lean rotation was 17.66°; the added procedural lean is capped per axis at 10°. |
| Landing lean recovery | Passed; measured root animation rotation returned to 0°. |
| 20 repeated simultaneous push/pull cycles | Passed; no force or motion attachment remained after ground settling. |
| Respawn | Passed separately: old force cleaned, new ability starts, exactly one force while active, zero after cancel. |

Raw measurements are in results/aerial-2026-09-20.json. The acceptance LocalScript is stored in tests but removed from the saved place.

## Scope

The project retains its existing locally owned character movement. The server validates boost requests and supplies a fixed impulse, with alive/airborne checks, direction validation, cooldown, request throttling and one-per-airtime enforcement. This does not claim full server-authoritative movement or exploit prevention.

The complete place and all five source exports were compared against the Studio Edit sources before saving. This checkpoint saves the Roblox place; it is not a claim that the public experience was republished.

