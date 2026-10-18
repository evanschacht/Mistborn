# Saved defaults regression acceptance

`ResetDefaults.client.luau` is the regression probe for saved reset defaults. Run it as a temporary **LocalScript in the real LocalPlayer.PlayerScripts** in a fresh Studio Play session, after choosing Dev Mode and letting tuning load. It must run before changing any tuning. It does not invoke Save Tuning or write to DataStore. It saves and restores both the current live snapshot and the saved reset baseline, including speedometer state, even if an assertion fails. Remove the temporary test script after execution; it normally destroys itself.

The result is JSON in `LocalPlayer:GetAttribute("ResetDefaultsResults")`. Require `passed=true`, `restored=true`, and every recorded check to pass. A failure of `Fresh join settings equal saved baseline` means either the join defaults are inconsistent or the session was already edited; repeat in a fresh session before interpreting it. The probe uses synthetic saved presets locally and restores the initial baseline; those fixtures are never shared or saved.

`ResetDefaultsMaster.client.luau` additionally exercises the actual panel's replicated-state listener in Studio. Run it as a temporary LocalScript and inspect `LocalPlayer:GetAttribute("ResetDefaultsMasterResults")`. It changes `MetalTuningMasterState.Value` only on that client, with no remote calls, server writes, or DataStore writes. It verifies a higher revision updates values, bounds, UI and reset defaults; positive stale records, revision zero, and invalid newer records are ignored; then a newer valid record is accepted. Unexpected external state changes abort the fixture. It restores the original StringValue, defaults and live tuning, but the panel's private revision remains advanced: **restart Play immediately afterward**, before any further tuning use. Require `passed=true`, `restored=true`, and `externalChange=false`.

The probe covers:

- Reset immediately after joining leaves all saved values, slider bounds, and speedometer state unchanged.
- Every individual slider reset restores its saved value and bounds while preserving other settings and the current speedometer toggle.
- Reset all after local edits restores the portable preset rather than factory schema values.
- A successfully accepted master becomes the new reset baseline; later local preview edits do not replace it.
- Invalid saved data is rejected without changing live tuning or defaults.
- Input tables, snapshots, and returned saved defaults cannot mutate live state or the saved baseline through table aliasing.
- The shared serialized baseline matches the saved configuration, and an omitted Snapshot flag preserves the current speedometer state.
- Reset all restores the saved speedometer setting in Motion, the panel flag, toggle label, and visible speedometer.
- Reset does not advance the replicated master revision. This checks the observed local revision; it is not a live DataStore availability test.

In addition to the scripted checks, verify the real buttons in a disposable Play session:

1. Record the complete joined snapshot, saved baseline, and master revision. Click **Reset all to defaults** immediately; require an identical snapshot and unchanged revision.
2. Expand **Push & pull**, change Pull acceleration and its Min/Max, then click its **Reset to Default** button. Require its saved value and saved bounds, with Push acceleration unchanged. Check **Metal sensing** similarly with the saved range and its bounds.
3. Change multiple categories and the speedometer toggle, then click **Reset all to defaults**. Require all values/ranges and the speedometer to match the saved baseline; inspect visible row text and slider positions.
4. Exercise the master broadcast path with a temporary, locally replicated fixture only, or a deliberately authorized shared save. Require the panel to apply the accepted master, then change a slider and reset it. It must restore the latest accepted master rather than the join fallback. Do not silently write synthetic test settings to the live shared master.
5. Re-require Motion in a fresh command/MCP context and confirm it preserves existing runtime tuning and the shared saved baseline. This is separate from requiring the module again inside the same LocalScript, which is cached.
6. Check Output for errors. Restore the intended tuning and speedometer before capturing a portable checkpoint. Capture the preset from the saved baseline or intended live settings explicitly; never replace the preset with factory defaults as a side effect of verification.

`TuningPersistence.client.luau` is historical: its assertions that reset returns `CoastDrag=2.3` and all factory `spec.default/spec.min/spec.max` describe the superseded behavior. Do not run it as this change's acceptance gate. `MasterTuning.spec.luau` also contains a historical AnchorRange=290 assertion; its failure alone does not establish a reset regression. This document and the new probe do not imply those historical tests have been updated.

## Evidence

Verified in Studio on 2026-10-18 against place 116229497870769:

- `ResetDefaults.client.luau`: 288 checks passed, original tuning restored.
- `ResetDefaultsMaster.client.luau`: 19 actual panel-handler checks passed, original tuning and client-local state restored. Play was restarted after the synthetic revision test. This used local fixtures, not live shared saves.
- Native UI: clicking Reset all immediately after entry preserved all 29 values, all bounds and the speedometer; all visible row attributes matched the live values afterward.
- Native UI: Ground walking speed was changed from 40 to 78 using its slider; its individual Reset to Default restored 40 with bounds 0–100, while push acceleration remained 750.
- Studio inspection preserved the live edited value 78 and separately reported the saved default 40; inspection no longer reapplies the portable preset over the running settings.
- The intended preset remained unchanged: pull/push acceleration 750, pull/push falloff 0.4/0.1, sensing range 750, ground/air speed 40, and speedometer enabled.

DataStore was unavailable in this Studio session, so the portable preset supplied the join defaults. No live DataStore, multiplayer, or publication pass is claimed. Temporary probes are not included in the saved place.
