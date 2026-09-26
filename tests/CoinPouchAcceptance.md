# Studio acceptance - 2026-09-24
Update verified 2026-09-25: release shortened to 0.34 seconds with a 0.55-second animation. Moving airborne release measured 0 horizontal offset and 0 sideways drift, arriving after about 0.42 seconds in Studio. Owner-side release alignment waits for the replicated coin by name. Coin-only downward force supplies 2.25 times gravity and initial downward speed is multiplied by 1.5, yielding approximately 1.5 times faster descent. Character gravity is unchanged.

Verified in a live Studio client/server session:
- Spawn creates 61 noncolliding pouch details, 15 visible pouch coins and bottom-left counter.
- Real R key input starts a toss; repeated R during the animation consumes exactly one coin.
- Server accepts one of ten simultaneous Toss requests.
- Held pull target and nonzero VectorForce survive the right-hand animation.
- Hand-held coin hides after release.
- All 15 coins can be used; no negative inventory or additional toss at zero.
- Pouch decorative coins become invisible at zero; HUD reads Coins: 0 / 15.
- Released physical coins settle on the floor and show enabled blue beams.
- Moving the real mouse over a tossed coin selects it and assigns its highlight.
- Motion.Start rejects both push and pull on coins.
- Owner moving 2000 studs away cleans up dropped coins.
- Tossing from 25 studs above the player spawn produces an airborne coin that falls and rests on the floor.
- Inspected pouch placement and coin-lifting phase from a front camera view.
- No new runtime errors; pre-existing Studio DataStore access warning remains.
