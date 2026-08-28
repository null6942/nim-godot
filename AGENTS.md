<!-- bmad:context -->
<!-- Verified 2026-08-28 against 8b6b525 after history rewrite (old 2D wasm/pck blobs stripped). Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## Nim

3D Nim in Godot 4.4 (GL Compatibility): Marienbad 1-3-5-7, Classic and Misère, UI built in script. Source is a stub scene plus `main.gd` / `pearl.gd`. Planning artifacts go in `_bmad-output/`. The tree is proprietary (`LICENSE`). Live play is `https://nim.yermom.dev` (Jupiter nginx, not GitHub Pages).

## Policy

- Treat the tree as proprietary (`LICENSE`); do not relicense or add an OSS license.
- Do not commit `.godot/`, `*.uid`, `*.import`, `builds/mac/`, `builds/linux/`, `builds/windows/`, or `builds/*.zip`.
- After a gameplay or asset change, re-export Web to `builds/web/index.html` and include the updated `index.*` in the same change. Do not commit other web basenames (`nim3d`, `nimopt`, and similar). Then run `scripts/deploy-web.sh` — **git push does not publish the site**.
- Keep `builds/web/cachebust.js` and `builds/web/index.service.worker.js`. Godot export does not write them.

## Where things are

- Game entry: `main.tscn` → `main.gd`. Pearls: `pearl.gd`, look in `pearl.gdshader`.
- Web export output: `builds/web/index.html` (preset `Web` in `export_presets.cfg`). `html/head_include` injects `cachebust.js`.
- Live files: Jupiter `/home/aaron/docker/nim/html/` (Portainer stack **nim**, id 42). Stack notes: `jupiter-config/docker/stacks/nim/README.md`.
- Deploy: `scripts/deploy-web.sh` rsyncs `builds/web/` (minus `*.import`) to that html dir and copies `index.pck` → `nim3d.pck` so browsers cannot reuse a cached 2D pack.
- BMad planning and implementation artifacts: `_bmad-output/`.

## Running and verifying

- Requires Godot 4.4+ with export templates (`project.godot` features, README).
- Run from repo root: `godot --path .`
- Editor: `godot --editor --path .`
- Web release export: `godot --headless --path . --export-release Web builds/web/index.html`
- Publish to the live site: `scripts/deploy-web.sh`
- Confirm the live HTML contains `<!-- nim-3d` and `cachebust.js`. A 2D green card with "click pearls to select, then confirm" is the May 2026 UI — origin is wrong or the browser is still on `index.pck`.
- No test suite; play the scene or `https://nim.yermom.dev` to verify.

## Conventions that differ from defaults

- Keep world, UI, and pearls spawned from `main.gd`; do not rebuild them as an editor scene tree unless asked.
- Keep `gl_compatibility` for desktop, mobile, and web in `project.godot`.
- Boot into setup (`_enter_setup`); start a match only when New game is pressed from setup. Do not start or randomize first player from `_ready`.
- Godot `*.uid` and `*.import` files are gitignored here; leave them untracked.

## Known pitfalls

- Exporting Web to a path other than `builds/web/index.html` rewrites `index.html` to load that basename. Always use the preset path so `executable` stays `index`.
- Removed pearls must not stay pickable (`Pearl.Phase.REMOVED` and `set_pickable(false)` in `pearl.gd`); ghost clicks on empty seats were a real bug.
- Pushing `main` does not update `nim.yermom.dev`. After rsync, if the table does not change, the browser is serving a cached `index.pck` (the 2D pack was 78 KB). `cachebust.js` appends `?v=` and `cache: 'reload'`; live HTML also sets `mainPack` to `nim3d.pck`. Bump `VERSION` in `cachebust.js` if a pack change still does not show.
- Do not 404 a Godot service worker. An old worker keeps intercepting fetches after origin updates. Ship `index.service.worker.js` as a kill-switch (unregister + clear Cache Storage). `progressive_web_app/enabled` stays false.
- `rsync --delete` may wipe `cachebust.js` / the kill-switch if they are missing from the source tree. Never rsync a web dir that lacks those two files.

<!-- /bmad:context -->
