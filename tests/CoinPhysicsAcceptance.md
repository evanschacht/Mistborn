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
