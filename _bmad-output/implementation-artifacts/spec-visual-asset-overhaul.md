---
title: 'Salon visual overhaul — prettier table, pearls, and HUD'
type: 'feature'
created: '2026-08-30'
status: 'done'
baseline_commit: '383e86fd71d5be493b608b1c7361912a9d2ffb7f'
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/AGENTS.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The table already plays as a gold-on-walnut salon, but the look is still a first pass: walnut and floor maps show 4-way mirror seams, felt is flat at table scale, pearls and HUD chrome do not feel as expensive as the identity wants.

**Approach:** Keep that salon feel and make it pretty. Replace the three albedo maps in place with seamless tiles, retune table materials/lighting to them, and raise pearl + HUD finish to match. Gameplay, setup lock, and script-spawned scenes stay.

## Boundaries & Constraints

**Always:**
- Gold-on-walnut/felt identity: wordmark `NIM`, creamy pearls that go gold on select, deep green baize — not neon, sci-fi, or a flat mobile skin.
- Boot into `_enter_setup`; start a match only from New game in setup.
- Keep Classic/Misère, difficulty lock, `START = [1, 3, 5, 7]`, pick-and-take, and AI odds.
- Spawn world, HUD, and pearls from `main.gd`. Keep `gl_compatibility`.
- Camera FOV 38. SubViewport `MSAA_4X`, `scaling_3d_scale` 1.35, `UPDATE_ALWAYS`. Light budget: sun + lamp + two omnis; shadows on sun and lamp only.
- Pearls: `Pearl.RADIUS`, collision layer 1 vs board layer 2, `Phase.REMOVED` + `set_pickable(false)` + hidden. Shader uniforms stay `selected` / `hovered` / `dimmed` / `hue_shift`. Keep the `StandardMaterial3D` fallback.
- Replace `textures/{felt,walnut,floor}.png` in place. Maps must tile at table scale with no visible cross-seam.
- Reuse HUD tokens (`GOLD`, `GOLD_DIM`, `INK`, `MUTED`, `FAINT`, `ROOM`, `BTN_BG`, `BTN_HOVER`). HUD must still read at ~390px wide.
- After visual changes, export Web to `builds/web/index.html` so `executable` stays `index`. Keep `cachebust.js` and `index.service.worker.js`.
- Fonts stay Fraunces + Figtree (SIL OFL). Credit stays in `fonts/OFL.txt` and README.

**Ask First:**
- Changing felt away from deep green baize, or replacing the display/UI fonts.
- Adding texture files beyond the three existing PNGs.
- Running `scripts/deploy-web.sh` (git push does not publish).

**Never:**
- Do not change rules, first-player timing, or input.
- Do not rebuild as an editor scene tree, add autoloads, extra viewports, reflection probes, per-pearl particles, or raise SphereMesh segments.
- Do not switch to Forward+ or add glow-heavy post beyond the current light/env budget.
- Do not introduce a second HUD framework or Theme scene tree.
- Do not add a test suite. Do not relicense. Do not commit `*.uid` / `*.import` or non-`index.*` web basenames.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Setup | First load or New game from a match | Empty board, prettier table/HUD, options enabled, no result card | Missing font/tex falls back; no crash |
| In match | Hover/select one row | Gold select/hover reads clearly; other rows dim; Take enabled only with a legal selection | Locked mode/diff look disabled and no-op |
| Result | Last pearl taken | Framed result card over the table; New game still reachable | Dim does not eat New game |
| Removed pearls | Take confirmed | Seat empty, not pickable, no ghost click | `REMOVED` + unpickable + hidden |
| Web | Open `builds/web/index.html` | Loads `index.js` / `index.pck` / `index.wasm`; new look visible | Export must not retarget another basename |

</frozen-after-approval>

## Code Map

- `main.gd:8-15` -- HUD color tokens; reuse, do not scatter new hex (`DIFF_COLORS` at 22 may stay as difficulty tints)
- `main.gd:80-200` -- fonts, `_box`, `_glow`, `_style_button`, `_mk_btn`
- `main.gd:202-216` -- `_tex_mat` UV / roughness / triplanar for the new PNGs
- `main.gd:243-375` -- env, four lights, camera FOV 38, walnut/felt/floor, gold inlay
- `main.gd:385-563` -- HUD stack, SubViewport, result card, Take / New game
- `main.gd:637-654` -- row Label3D A–D (Fraunces gold)
- `pearl.gdshader` -- look only; keep uniform names
- `pearl.gd` -- ring / blob / fallback; keep pick/phase contract
- `textures/felt.png`, `walnut.png`, `floor.png` -- replace in place
- `export_presets.cfg` -- Web path `builds/web/index.html`
- `README.md:41` -- font credit; do not drop

## Tasks & Acceptance

**Execution:**
- [x] `textures/{felt,walnut,floor}.png` -- Replace with seamless tileable albedo maps: deep baize nap, tight walnut grain, dark salon floor. No 4-way mirror cross. Same filenames.
- [x] `main.gd` -- Retune `_tex_mat` tints/UV/roughness to the new maps. HUD: keep tokens; make chrome read as a salon overlay (breathing room, New game stays the gold primary, Take is secondary until a legal selection, locked mode/diff still look disabled). Result card stays framed over the table. Do not change setup/match flow.
- [x] `pearl.gdshader` -- Richer cream iridescence and clearer gold select/hover/dim without renaming uniforms.
- [x] `pearl.gd` -- Match ring, blob, and fallback material to the shader gold; do not change pick/phase/`RADIUS`.
- [x] `builds/web/index.html` -- `godot --headless --path . --export-release Web builds/web/index.html`. Commit only updated `index.*`. Keep `cachebust.js` and `index.service.worker.js`.

**Acceptance Criteria:**
- Given first load, when the scene runs, then setup HUD and table show the new finish, the board is empty, and no match has started.
- Given a match, when the player hovers and selects pearls in one row, then select/hover/dim is obvious and other rows stay dimmed and unselected.
- Given the last pearl is taken, when the overlay shows, then a framed result card appears over the table and New game remains usable.
- Given walnut rails and the floor in camera view, when the table is inspected, then no 4-way texture cross-seam is visible.
- Given a ~390px-wide layout, when the HUD is shown, then title, mode/diff, status, and buttons remain readable.

## Design Notes

Walnut and floor today are mirrored quadrants — a dark cross through the middle of each PNG. New maps must be actually tileable (triplanar walnut/floor, UV felt). Felt should read as cloth nap at the 6.02×4.82 bed, not a uniform green noise plate.

Pretty means richer materials and chrome in the existing language, not new systems. Albedo PNGs + current `StandardMaterial3D` / shader uniforms. No extra PBR maps, viewports, or lights.

## Verification

**Commands:**
- `godot --headless --path . --quit-after 1` -- expected: exits 0, no script errors
- `godot --headless --path . --export-release Web builds/web/index.html` -- expected: `builds/web/index.html` still loads basename `index`; `cachebust.js` and `index.service.worker.js` still present

**Manual checks (if no CLI):**
- Setup: empty board, options enabled, prettier HUD/table
- Match: single-row take, gold select, dim other rows, removed seats not pickable
- Result: framed card; New game clickable
- Narrow width ~390px: HUD still reads
- Desktop play (`godot --path .`): table looks like a salon, not a tiled demo

## Suggested Review Order

**Table maps**

- Felt is one UV copy on the bed — no offset/plus, or nap kaleidoscopes.
  [`felt.png`](../../textures/felt.png)

- Walnut rails and floor albedo, retuned tint/UV/roughness for the new maps.
  [`main.gd:324`](../../main.gd#L324)

**HUD chrome**

- Gold-edged plaques wrap setup/match chrome without a second UI framework.
  [`main.gd:140`](../../main.gd#L140)

- Title plaque sits above the table; buttons stay in the existing `_style_button` tokens.
  [`main.gd:423`](../../main.gd#L423)

- Result card stays over the table; New game remains outside the dim.
  [`main.gd:517`](../../main.gd#L517)

**Pearls**

- Stronger gold select/hover/dim; uniform names unchanged.
  [`pearl.gdshader:26`](../../pearl.gdshader#L26)

- Ring and fallback cream track the shader gold.
  [`pearl.gd:161`](../../pearl.gd#L161)

**Web pack**

- Export still loads `index`; `mainPack` stays `nim3d.pck` so caches cannot revive the 2D pack.
  [`index.html:114`](../../builds/web/index.html#L114)

- Cachebust token bumped with the new pack.
  [`cachebust.js:3`](../../builds/web/cachebust.js#L3)
