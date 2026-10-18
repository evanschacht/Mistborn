# Agent handoff

Documentation reviewed against repository source on 2026-10-18, including the entry menu and tutorial routing additions. This guide describes the architecture; current test evidence must be recorded separately from the historical checks below.

## First steps

1. Read the root README and AGENTS.md. Check `git status`, branch, and remote before editing. The intended remote is `https://github.com/evanschacht/Mistborn.git`, branch `main`.
2. Open `Mistborn-Anchor-Prototype.rbxl`. If using Studio MCP, list current Studio instances and inspect the selected session and data model before reads or mutations. Never reuse an old session ID blindly.
3. Inspect live tuning before stopping Play. Unsaved runtime slider changes can be lost when Play stops. Capture the actual active settings, not an assumed set of defaults.
4. Locate the relevant modules using the README map. Keep the binary place and source exports synchronized. There is no checked-in automatic source-to-Studio sync/build configuration.

The last gameplay/settings checkpoint before this handoff is `6a0a85b` (saved shared tuning preset). Recent predecessors are `1cc391d` (guided coin retrieval) and `7a4e220` (coasting stop, drop shadow, release latency). Use Git history for the exact patch and rollback boundaries.

## Studio source mapping

Directories under `src/` mirror Roblox services. Files ending `.client.luau` are LocalScripts; `.server.luau` are Scripts; remaining `.luau` files are ModuleScripts. Instance names omit file suffixes. StarterPlayerScripts belongs under StarterPlayer. Runtime PlayerScripts are copies, so changes made only there do not persist into Edit mode.

Update the Edit data model and matching source exports together. Do not export injected test scripts or Roblox-generated Play scripts as project source. Save the complete place using ordinary Save after gameplay changes. Documentation-only changes do not require rewriting an unchanged place file.

## Entry menu and tutorial server routing

- `ReplicatedFirst.EntryMenu` creates the initial menu without requiring a character or waiting for StarterPlayerScripts. It connects `ReplicatedStorage.EntryFlow.Status` before sending the `ChooseMode` Ready handshake. Choices are `Dev` and `Tutorial`; status values are Ready, Loading, Entered and Error. Error responses permit retry; repeated Ready handshakes replay the current server status.
- `ServerScriptService.EntryFlow` sets `Players.CharacterAutoLoads=false` before any yield. Keep that property false in the saved Edit model as well. Characters spawn only after server admission; `Player.EntryMode` records Dev or Tutorial, and respawns preserve that mode. Existing coin and aerial scripts bind through CharacterAdded and support the initial absence of a character.
- Dev Mode admits the player into the existing map. A published Tutorial Level selection uses `TeleportService:TeleportAsync(game.PlaceId, {player}, options)` with `ShouldReserveServer=true`. Its versioned TeleportData identifies Tutorial, source place, user and request. No additional place needs to be created or published.
- Automatic tutorial arrival requires a reserved server (`PrivateServerId` is nonempty and `PrivateServerOwnerId` is zero), matching server-provided join source place and valid routing data. A public server never replaces its development map for a tutorial choice. Tutorial build is shared by concurrent valid arrivals; Dev admission is blocked once the tutorial build starts.
- `ServerStorage.TutorialWorld.Build(parent)` synchronously returns a root Model and SpawnLocation. EntryFlow first builds under ServerStorage, validates the result, then swaps the map before admitting a character. It preserves Terrain and Camera instances, clears old terrain only after construction succeeds, and preserves the identity of `workspace.MetalAnchors` while emptying its contents because coin scripts capture that Folder. The original map remains available for rollback until the swap succeeds.
- Studio uses an explicit isolated preview in a fresh single-player Play session. It refuses replacement after Dev admission or while multiple players are present. A failed preview restores the original map and allows another choice. Ending Play discards the preview and restores Edit. Studio preview does not verify actual reserved-server travel.
- Explicit teleport failures return Error and release both choices for retry; request IDs reject stale failures. The 45-second teleport watchdog releases the busy UI but retains the unresolved transfer token and asks the player to rejoin. Roblox provides no teleport cancellation, so this prevents a late transfer racing a new mode choice or Dev spawn; only TeleportInitFailed or a thrown TeleportAsync failure clears that token. Character loads have a 25-second UI watchdog; a still-running LoadCharacterAsync retains its flight token so retries cannot overlap it, and a late successful completion can still enter the player. Choice cooldown rejections replay a status after the cooldown instead of silently stranding a disabled menu.
- Once a player has entered and the menu has closed, failed death respawns retry automatically after 2, 4 and 8 seconds. Exhausting those three retries disconnects with a clear request to rejoin; a respawn engine call that remains unresolved for 25 seconds uses the same recovery because it cannot safely be overlapped or cancelled. Death during an in-flight load retains the respawn request until that load completes. A successful living character resets the retry count.

Run `tests/EntryFlow.spec.luau` as a temporary server Script to validate tutorial join acceptance and rejection. Integration checks must cover the initial menu with no character, Dev admission without map replacement, a fresh Studio tutorial preview, death/respawn in each mode, rejection of incompatible Studio multiplayer preview, and retry after a reported failure. Real same-place reserved-server travel requires a published Roblox client; do not report Studio preview as that release check. See [Roblox's teleport documentation](https://create.roblox.com/docs/projects/teleport).

## Behavior to preserve

- Q push uses direction sign -1; E pull uses +1. MetalMotion keeps independent targets and exposes `GetTarget`. Sticky selection, active push, and active pull are separate visual states.
- Gravity remains active on the player. Forces recalculate direction from current geometry; releasing a control preserves momentum. Do not reintroduce hover states or instantaneous velocity alignment.
- When the character overlaps an anchor's footprint, force geometry permits a perfectly vertical force even off-center. The visible line still points to the anchor center.
- Size-adjusted sensing range is clamped to 80%-110% of the base Steel and iron range. The same effective range gates visuals, selection, and force. Separate push/pull falloff uses near/far distance clamps; force is zero at the effective range boundary.
- Lines vary with object size/distance and active selection state. Coins have stronger visibility and a gold selected/active glow. Preserve all three simultaneous target highlights.
- Sliding W accelerates only while powered and has its own speed cap. During coasting it only reduces friction. S has a powered minimum speed, but after force release must coast/brake to zero even if S stays held. It must never accelerate a slower character up to that minimum.
- Ground and aerial movement have separate speed/acceleration settings. Rotation should remain smooth. Flight lean uses horizontal speed; slower aerial movement retains its other pose. Below-anchor squat and coin-toss arm overlays have their own conditions.
- Pulling a free coin alone must not trigger slide, forward-flight, or squat body poses: only the right arm aims. Existing body movement from another force can continue. Coin toss temporarily owns the right-arm pose without cancelling the underlying force.

## Coin lifecycle and rendering

The pouch holds 15 coins. R is nonqueued. The server validates drops/control messages and owns physical coin motion and inventory. Coins are removed when they leave their owner's effective sensing range; retrieval increments inventory only up to capacity.

Release preserves horizontal momentum and downward velocity, suppresses upward launch, adds downward release speed, and uses stronger coin gravity plus horizontal drag. Client prediction begins at release; the server compensates message age and checks swept contact. Keep that handoff intact to avoid the old hovering or behind-player spawn bug.

MetalAwareness renders a noncolliding local proxy, halo, line endpoint, and ground shadow. The real server coin remains the physics/control target. Free-flight visuals use timestamped ballistic calculations; contact synchronization uses `CoinContactCFrame`. Do not apply collision or gameplay forces to the visual proxy.

CoinPhysics states include Falling, Pushed, Pulling, Grounded, and Blocked. A free airborne pushed coin moves away without moving the player. Actual solid contact enables grounded push reaction. Pulling normally moves the coin toward the player; a solid obstruction enables a pull reaction on the player until freed. Reaction attributes identify the acting player and must agree with the physical state, not merely a nearby ray hit.

Guided retrieval uses CoinRules' 4x pull acceleration, lateral velocity damping and arrival braking, while retaining the configured pull speed cap. The guidance compensates coin gravity during retrieval; this is separate from player gravity. Verify moving-player retrieval, obstruction, contact and inventory together when touching this path.

## Tuning and persistence

- `MetalTuningConfig.Specs`: factory Reset defaults, bounds/validation and migration of older saves.
- `MetalTuningPreset`: portable saved values, slider ranges and speedometer flag. At checkpoint 6a0a85b: pull/push acceleration 750, pull falloff 0.4, push falloff 0.1, both speed caps 160, base range 750, gravity 60, ground/air speed 40, jump height 8, coin air drag 1.2. Read the file for the complete authoritative snapshot.
- `MetalMotion.Snapshot(showSpeedometer)`: current client values/ranges. Preserve the actual UI speedometer flag when capturing a full preset.
- `MetalTuningPersistence`: DataStore `MistbornMetalTuning_v1`, key `master`, revisioned shared record replicated through `MetalTuningMasterState`. Other servers poll approximately every 30 seconds. Studio permits saving; live saves require the user owner or group rank 255. Saves are throttled.
- If DataStore loading succeeds, its master can override the fallback preset. Save Tuning failure must be reported, not described as a successful global save. The last recorded tuning checkpoint had unavailable external save service; local preset/place/Git backup succeeded. Recheck service availability rather than assuming it is still unavailable.

New controls belong in the appropriate existing collapsed category, or a new category if necessary. Include schema validation/migration, persistence, reset, bounds, and runtime consumers when adding a setting.

## Verification and known gaps

Tests are individual Studio scripts, not a single CLI suite. Client probes generally need Play mode with a spawned LocalPlayer and run as temporary LocalScripts; server specs need the server modules. Read each test first: some move characters, create anchors, change settings or monkey-patch controls. Use a disposable test session and remove fixtures afterward. A raw command-bar/MCP require can use a different module context from running game scripts, so prefer actual Script/LocalScript integration for live behavior.

`tests/CoinPhysicsAcceptance.md` and `tests/CoinPouchAcceptance.md` document historical checks. JSON result files are historical too. There are known stale assertions:

- `SlideBrakeFloor.client.luau` expects the old coasting 30-stud/s floor, which conflicts with the fixed behavior. Its direct helper calls also omit the newer powered argument.
- `MasterTuning.spec.luau` hardcodes an old range of 290; the saved preset now has 750. Derive expectations from the fixture before using it as a regression gate.
- Other old probes may assume earlier tuning/API defaults. Audit relevant tests before running or interpreting failures.

The earlier documentation-only handoff did not include new gameplay tests. Consult current entry-flow test evidence separately, and do not claim a current multiplayer, performance, or publication pass from old notes. Procedural poses and visual proxies run locally; verify remote-player appearance in a multi-client test before promising replicated animation behavior.

For a gameplay change, test the affected path plus nearby regressions: simultaneous push/pull, release momentum, S coasting stop, free versus grounded coin reactions, moving/falling release, guided retrieval/obstruction, inventory cap, and range cleanup as appropriate. Check Output for errors and preserve the user's tuning afterward.

## Assets and checkpoint workflow

Pouch assets include a Three.js generator, GLB, Blender file, and runtime primitive data. The established toolchain is `C:\Users\evans\Documents\Codex\2026-09-13\im\work\threejs`: Node/pnpm, Three.js 0.182, Meshoptimizer 0.24, and the existing GLTFExporter FileReader shim. Inspect it and run `pnpm verify` before asset changes. Three.js generates assets; Blender finalizes them; Roblox runs the game. Asset toolchain verification is unnecessary for documentation-only work.

After meaningful gameplay changes: capture intended tuning, update Edit scripts and exports, save the full place, inspect the complete diff, commit and push. Verify `git rev-parse HEAD` matches `git ls-remote origin refs/heads/main` and that `git status --short` is empty before saying everything is backed up. Publishing to Roblox is a separate operation and should be reported separately.
