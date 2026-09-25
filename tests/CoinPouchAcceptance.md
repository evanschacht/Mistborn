# Studio acceptance - 2026-09-24
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
