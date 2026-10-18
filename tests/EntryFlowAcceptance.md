# Entry flow acceptance — 2026-10-18

Verified in Roblox Studio against place 116229497870769, experience 10767187899.

- Initial Play: EntryMenu is Ready, Character is absent, camera is Scriptable, and the opaque menu covers the world. Both requested button labels are present.
- Native UI click on Dev Mode: character spawns in the existing sandbox, all 109 original anchors remain, menu disappears, and CoinCounter/MetalTuning restore. Death respawns in Dev Mode without showing the entry menu again.
- Fresh Play and native UI click on Tutorial Level: Studio preview replaces the test server's map with TutorialWorld. The original MetalAnchors folder remains empty, with no sandbox geometry beside the tutorial. Player spawns at approximately (0, 3.01, 120).
- Tutorial: baseplate is 720 x 720; wall is 300 wide x 100 high, with 36.2 total depth including buttresses. The builder spec passed 1,074 wall parts / 141 collision pieces, nonmetal flags, spawn orientation, bounds and anchor preservation.
- Tutorial death respawns successfully. Pressing R produces a server coin in the preserved MetalAnchors folder.
- Final tutorial arrival: initial replication finishes before the menu fades; camera faces the wall (look vector approximately 0, -0.031, -1). Normal character camera resumes afterward.
- EntryFlow join-validation and respawn retry schedule spec passed. Code review addressed rapid retry response loss, overlapping character loads, failed post-entry respawns and ambiguous pending teleport timeouts.
- Stopping Play restores the original Edit map. Players.CharacterAutoLoads is saved false; the server explicitly admits and respawns players.
- Existing source exports matched the pre-change Studio scripts after line-ending/trailing-whitespace normalization. Runtime tuning values, slider ranges and enabled speedometer matched the existing preset and were preserved.

The complete Edit place was downloaded through Studio's File > Download a Copy command and saved as Mistborn-Anchor-Prototype.rbxl. The open session was a cloud place, so the file command was used instead of Save to Roblox. New project scripts are synchronized with src; temporary tests were not added to the saved place.

## Limits

Actual TeleportAsync travel to a reserved Roblox server cannot run in Studio and has not been live-tested. This checkpoint has not been published to Roblox. Multi-client behavior, mobile/gamepad input and exhaustive simulated service-failure cases have not been tested. Validation of retry timing is a configuration check, not an injected avatar-service outage.

Studio Output contains the existing StudioAccessToApisNotAllowed warning for tuning DataStore loading and Roblox CoreGui FoundationProvider warnings. The local preset fallback remains active. No new EntryFlow, EntryMenu or TutorialWorld runtime errors were observed in the successful tests.
