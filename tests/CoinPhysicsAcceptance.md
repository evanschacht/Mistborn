# Coin push/pull acceptance

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
