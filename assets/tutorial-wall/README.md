# Tutorial stone wall

The tutorial world contains only a plain 720 x 720 stud baseplate, an invisible player spawn facing the wall, and the medieval stone wall. The wall is 300 studs wide and 100 high, with a 12 stud masonry body. Its stepped buttresses project to a total 36.2 stud depth. Twenty-three staggered masonry courses, eight restrained stone colors, 25 crenellations, coping and nine buttresses per face give it scale and readable masonry.

`src/ServerStorage/TutorialWorld.luau` is the deployable Roblox asset. `Build(parent)` synchronously returns `(rootModel, spawnLocation)`. It constructs an unparented model, cleans up on error, and parents the complete result only after successful construction. It never clears the existing world, replaces `MetalAnchors`, or touches tuning. Baseplate top is y=0; wall center is z=-80; spawn is at (0, 0.5, 120), facing -Z. The routing code owns world isolation and cleanup.

All wall parts are anchored Concrete and explicitly nonmetal, outside `MetalAnchors`. The wall has 1,074 primitives: 548 masonry blocks, 75 parapet pieces, 450 buttress pieces and one continuous core. Only 141 wall pieces collide or participate in queries; decorative stone has collisions, queries and touch events disabled. The continuous core closes mortar seams. The runtime requires no uploaded asset IDs. The baseplate and spawn add two parts to the world.

## Generation and finishing

Run `pnpm verify` in `C:\Users\evans\Documents\Codex\2026-09-13\im\work\threejs`, then from the repository run `node assets/tutorial-wall/generate.mjs`. `MISTBORN_THREEJS_ROOT` can point to the same installed toolchain at another location. This reuses its existing headless FileReader shim, Three.js GLTFExporter and Meshoptimizer readiness check. It writes the primitive manifest, source GLB, generation report and matching Luau module; the shared toolchain is not modified.

Run `finish-blender.py` in Blender to join the wall into one mesh, merge exact duplicates, clean degenerate geometry, recalculate normals, retain box UVs, consolidate eight PBR stone materials and place the portable asset pivot at ground center. It writes a standalone `.blend` asset library, final GLB, Blender report and review render. The user's active scene, selection and file remain intact. The final GLB is an optional future mesh import; Roblox currently builds the exact manifest as native primitives.

## Verification recorded 2026-10-18

- Fresh toolchain gate: Three.js revision 182, Meshoptimizer ready, 10,704 verification GLB bytes.
- Source GLB: 114,116 bytes; positive finite dimensions and positions validated for every manifest part.
- Blender 5.2.1: one wall mesh, 8,592 vertices, 12,888 triangles, eight PBR materials and one UV layer; final GLB 909,892 bytes and `.blend` 1,326,627 bytes. Final GLB inspected to confirm it contains only the wall mesh.
- `wall-preview.png` rendered and visually inspected for silhouette, masonry, buttresses and battlements.
- Blender's default Scene was preserved. The connected add-on reports an older protocol; execution and rendering succeeded through its supported fallback.
- `tests/TutorialWorld.spec.luau` validates the runtime build, dimensions, spawn orientation, nonmetal flags, collision budget and preservation of the existing anchors. This asset task did not run Studio; the integrating agent owns the live Studio check and place checkpoint.

These asset checks do not establish multiplayer performance or publication status.
