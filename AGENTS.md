# Project checkpoint workflow

- Start with README.md and docs/HANDOFF.md for architecture, behavior, tuning persistence, and test caveats.
- After every meaningful gameplay change, save the complete Roblox place, export updated project scripts, commit the complete project checkpoint, and push it to GitHub.
- Keep Mistborn-Anchor-Prototype.rbxl and all project scripts under src/ synchronized in each gameplay checkpoint. Documentation-only changes do not require rewriting an unchanged place.
- Capture current runtime tuning before stopping Play; preserve values, slider bounds, and the speedometer setting in the intended checkpoint.
- Verify the remote commit matches the local commit and the working tree is clean before reporting the checkpoint as backed up.
- Prefer Studio's direct Save command. Leave Play mode running after verification when practical.
- Do not export scripts injected by Roblox or temporary test scripts during Play mode as project source.
- Add new tuning controls to the appropriate existing category, creating a category only when needed. Keep schema, migration, reset, bounds, and save behavior consistent.
- Treat historical test results as historical evidence; consult the handoff's stale-test caveats before using old probes.
