# Coin push/pull acceptance

Final client regression: 67 airborne samples without player thrust, followed by a client-side contact ray proving the visible coin was on the solid surface. Replicated CoinContactCFrame explicitly synchronizes the final landing position when anchoring, avoiding a stale airborne physics position on clients.

Contact regression verified 2026-09-25: moving aerial drop with held push ran 74 airborne samples with no anchored coin and zero player thrust, then contacted a solid surface. A separate fixture verified that a coin with a gap remains airborne, actual contact enables reaction, and moving an anchored coin off its support clears both anchoring and reaction. Release alignment is now acknowledged before server contact detection; support is rechecked every frame. Contact probes use coin dimensions plus 0.025 studs, not a fixed forward lookahead.

Verified in Studio on 2026-09-25:

- A grounded coin locks in place and reports a push reaction for the acting player.
- Pulling unlocks the coin and accelerates it toward the player using the existing tuning.
- A solid obstacle immediately ahead freezes the coin and transfers the pull reaction to the player.
- Removing the obstacle resumes coin movement and clears the pull reaction.
- Retrieval removes the physical coin and restores inventory from 14 to 15.
- Live LocalScript integration: airborne push, ground contact, continued push reaction, pull, and retrieval completed in sequence.
- Free coins do not contribute thrust to the player; only grounded push or blocked pull does.
- Inventory is capped at CoinRules.Capacity. Existing range cleanup and selection highlights still apply.

Server control messages validate the existing tuning schema, target identity, range, player life, and a renewable control timeout. Dropped coins initially retain their release alignment window before server physics takes over.

## Retrieval pose and inherited momentum regression
- Grounded coin pull leaves MetalSliding false and preserves normal body joints; only right shoulder/elbow/wrist are overlaid.
- Coin-only retrieval in freefall at 70 studs/s does not activate flight or downward squat blends.
- Drop during forward movement and falling: preserve X/Z velocity and inherit Y velocity plus downward release speed; coin continues falling faster under existing 1.5x fall tuning.
- Verify ordinary cube propulsion and its coasting poses remain active when also retrieving a coin.

## Ballistic release regression
- Falling, rising, and initially stationary drops: single server-owned launch, nonpositive vertical release speed, constant horizontal velocity and monotonically decreasing vertical velocity during unobstructed free flight.
- Passed 31+ Heartbeat samples per case; no lateral or upward impulses.
- Pending coin remains hidden and noncolliding until authoritative release; dropped coins cannot collide with one another.

## Coin drag and render smoothing
- Coin Air Drag in the initially closed Coins category; defaults to 1.2, editable range 0-8, individual reset and master-save migration preserved.
- Live airborne release tests: horizontal speed ratio after 0.5s was 1.0 at drag 0, 0.546 at drag 1.2, and 0.128 at drag 4.
- Three client render tests, 30+ frames each, had no upward position reversals; landing mesh, halo and beam endpoints agree.
- Rendering uses a noncolliding local proxy; physics, range, push/pull targets, and retrieval remain server-authoritative.

## Coast stop, drop shadow, and release latency
- Starting at 80 studs/s, pull and hold S, release E while keeping S held: coasts to rest; powered S floor remains unchanged.
- Falling at 120 studs/s while moving horizontally: visible coin descends continuously and stays below the player (38 sampled frames); ground shadow tracks coin X/Z.
- Release originates beneath the feet, clipped above solid ground. Local timestamped flight begins before acknowledgement; server compensates message age and checks swept contact.
- Shadow is a noncolliding local surface marker and is removed with its coin.
