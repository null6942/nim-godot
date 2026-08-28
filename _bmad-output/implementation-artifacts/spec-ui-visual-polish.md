---
title: 'Polish HUD, fonts, and 3D table presentation'
type: 'feature'
created: '2026-08-27'
status: 'in-progress'
baseline_commit: '1e2e86ddb5c6ffad90b962ccb20b4de4001d7376'
review_loop_iteration: 0
context:
  - '{project-root}/AGENTS.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The 3D table, pearls, and overlay UI already play, but they read as a first pass: Google-default fonts, flat HUD chrome, a dim-only result overlay, and textures/lighting that do not match the salon idea.

**Approach:** Keep the gold-on-walnut/felt salon identity and raise every surface. New OFL display + UI fonts, new tileable table textures, a framed HUD/result treatment, and a richer pearl shader. Gameplay, setup lock, and code-built scenes stay.

## Boundaries & Constraints

**Always:**
- Boot into `_enter_setup`; start a match only from New game in setup.
- Keep Classic/Misère, difficulty lock, single-row take, `START = [1,3,5,7]`, and AI odds.
- Spawn world/UI/pearls from `main.gd`; keep `gl_compatibility`.
- Keep `Pearl.RADIUS`, pearl collision layer 1 vs board layer 2, `Phase.REMOVED` + `set_pickable(false)`, and shader uniforms `selected` / `hovered` / `dimmed` / `hue_shift`.
- After visual changes, re-export Web to `builds/web/index.html` so `executable` stays `index`.
- Fonts stay SIL OFL; credit them in `fonts/OFL.txt` and README.
- `*.uid` / `*.import` stay untracked.

**Never:**
- Do not rebuild the game as an editor-placed scene tree.
- Do not relicense, add MIT/Apache, or commit scratch web basenames (`nimopt`, etc.).
- Do not change rules, first-player randomization timing, or pick-and-take input.
- Do not switch renderer to Forward+.
- Do not invent a second HUD framework or add themes/Control scenes unless a small Theme resource clearly simplifies the existing `_style_button` helpers.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Setup | First load or New game from a match | Empty board, mode/diff enabled, polished HUD, no result card | N/A |
| In match | Options locked | Mode/diff look disabled, Take enabled only with a legal selection | Locked clicks still no-ops |
| Result | Last pearl taken | Framed result card over the table; New game still reachable | Dim does not eat New game |
| Pearl states | Hover / select / other-row dim / removed | Gold ring + shader respond; removed pearls never pick | Fallback StandardMaterial3D if shader missing |
| Web | Open `builds/web/index.html` | Loads `index.js`/`index.pck`/`index.wasm`; new look visible | Export must not retarget another basename |
| Font miss | Font file absent | `_font` fallback still renders; no crash | Existing load fallback |

</frozen-after-approval>

## Code Map

- `main.gd:8-15` -- color tokens; reuse, do not scatter new hex
- `main.gd:78-150` -- `_load_fonts`, `_apply_font`, `_box`, `_style_button`, `_mk_btn`; extend for primary / secondary / locked
- `main.gd:152-166` -- `_tex_mat` uv/roughness for new PNGs
- `main.gd:193-325` -- lights, camera, walnut/felt/floor, gold inlay
- `main.gd:335-500` -- HUD, SubViewport, result overlay, Take/New game
- `main.gd:502-553` -- `_options_locked`, `_enter_setup`, `_start_match`; behavior read-only
- `main.gd:574-586` -- row `Label3D` A–D; currently unfonted
- `pearl.gd` / `pearl.gdshader` -- look only; keep pick contract and uniform names
- `fonts/`, `textures/felt.png`, `walnut.png`, `floor.png` -- replace in place
- `export_presets.cfg` -- Web path `builds/web/index.html`
- `README.md` -- font credit line

## Tasks & Acceptance

**Execution:**
- [x] `fonts/` -- Install an OFL display face (Fraunces or equivalent high-contrast serif) for titles/result/row tags and an OFL grotesque (Figtree or equivalent) Regular+SemiBold for UI; update `OFL.txt`
- [x] `textures/` -- Replace felt, walnut, and floor with seamless tileable maps that read as deep baize, tight walnut, and dark stone at table scale
- [x] `main.gd` -- Wire new fonts; restyle HUD (title tracking, tokenized buttons: primary New game, secondary Take, locked mode/diff); framed result card via `_box`; status as quiet caption; apply display font to row Label3D; retune `_tex_mat` and lighting to the new maps
- [x] `pearl.gdshader` -- Richer iridescence and gold select/hover without renaming uniforms
- [x] `pearl.gd` -- Match ring/blob/fallback material to the shader gold; do not change pick/phase
- [x] `README.md` -- Credit the new fonts
- [x] `builds/web/index.html` -- `godot --headless --path . --export-release Web builds/web/index.html` and commit only `index.*`

**Acceptance Criteria:**
- Given first load, when the scene runs, then setup HUD uses the new fonts and chrome, the table uses the new textures, and no match has started.
- Given a match in progress, when the player hovers and selects pearls in one row, then select/hover/dim reads clearly and other rows stay dimmed and unselected.
- Given the last pearl is taken, when the overlay shows, then a framed result card appears over the table and New game remains usable.
- Given mode/diff during a match, when the player tries to change them, then they stay locked and look disabled.
- Given a web export, when `index.html` is opened, then it loads the `index` executable and shows the polished look.

## Spec Change Log

## Review Triage Log

## Design Notes

Elevate the salon look; do not invent a sci-fi or flat-mobile skin. Wordmark stays "NIM" with modest tracking. Buttons share `_box` radii: selected = gold fill + ink text; locked = muted, no glow. Result card is a dark panel with a gold hairline, not labels on a black dim.

Felt nap visible but not noisy at FOV 38; walnut grain should not blob on rails (triplanar already on). Pearls stay creamy with cool/warm iridescence; selected shifts gold, never neon. HUD stack: wordmark, subtitle, mode, difficulty, table, status, Take + New game.

## Verification

**Commands:**
- `godot --headless --path . --quit-after 1` -- expected: exits 0, no script errors
- `godot --headless --path . --export-release Web builds/web/index.html` -- expected: `index.html` `executable` is `index`; no `nim*.js` created

**Manual checks (if no CLI):**
- Run `godot --path .`: setup, start match, hover/select/take, finish a game, New game back to setup.
- Desktop and ~390px-wide window: HUD still readable, buttons not clipped.
- Confirm `builds/web/index.html` script src is `index.js`.
