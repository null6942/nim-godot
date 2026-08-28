<!-- bmad:context -->
<!-- Verified 2026-08-27 against 39792f2. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## Nim

3D Nim in Godot 4.4 (GL Compatibility): Marienbad 1-3-5-7, Classic and Misère, UI built in script. Source is a stub scene plus `main.gd` / `pearl.gd`. Planning artifacts go in `_bmad-output/`. The tree is proprietary (`LICENSE`).

## Policy

- Treat the tree as proprietary (`LICENSE`); do not relicense or add an OSS license.
- Do not commit `.godot/`, `*.uid`, `*.import`, `builds/mac/`, `builds/linux/`, `builds/windows/`, or `builds/*.zip`.
- After a gameplay or asset change, re-export Web to `builds/web/index.html` and include the updated `index.*` in the same change. Do not commit other web basenames (`nim3d`, `nimopt`, and similar).

## Where things are

- Game entry: `main.tscn` → `main.gd`. Pearls: `pearl.gd`, look in `pearl.gdshader`.
- Web export output: `builds/web/index.html` (preset `Web` in `export_presets.cfg`).
- BMad planning and implementation artifacts: `_bmad-output/`.

## Running and verifying

- Requires Godot 4.4+ with export templates (`project.godot` features, README).
- Run from repo root: `godot --path .`
- Editor: `godot --editor --path .`
- Web release export: `godot --headless --path . --export-release Web builds/web/index.html`
- No test suite; play the scene or the web export to verify.

## Conventions that differ from defaults

- Keep world, UI, and pearls spawned from `main.gd`; do not rebuild them as an editor scene tree unless asked.
- Keep `gl_compatibility` for desktop, mobile, and web in `project.godot`.
- Boot into setup (`_enter_setup`); start a match only when New game is pressed from setup. Do not start or randomize first player from `_ready`.
- Godot `*.uid` and `*.import` files are gitignored here; leave them untracked.

## Known pitfalls

- Exporting Web to a path other than `builds/web/index.html` rewrites `index.html` to load that basename. Always use the preset path so `executable` stays `index`.
- Removed pearls must not stay pickable (`Pearl.Phase.REMOVED` and `set_pickable(false)` in `pearl.gd`); ghost clicks on empty seats were a real bug.

<!-- /bmad:context -->
