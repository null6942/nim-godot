---
title: 'Salon HUD and UX polish pass'
type: 'feature'
created: '2026-09-16'
status: 'done'
baseline_commit: '1b406c1'
context:
  - '{project-root}/AGENTS.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Materials and fonts already read as a gold-on-walnut salon, but the HUD still feels like stacked chrome: dense plaques, equal-weight buttons in every state, abrupt result overlay, and utilitarian status copy.

**Approach:** Keep the salon identity and gameplay contracts. Raise HUD hierarchy, state-aware primary actions, soft result motion, and quieter framing so the table stays the hero and the controls feel intentional.

## Boundaries & Constraints

**Always:**
- Gold-on-walnut/felt identity; wordmark `NIM`; Fraunces + Figtree; reuse HUD color tokens (`GOLD`, `GOLD_DIM`, `INK`, `MUTED`, `FAINT`, `ROOM`, `BTN_BG`, `BTN_HOVER`).
- Boot into `_enter_setup`; start a match only from New game in setup.
- Keep Classic/Misère, difficulty lock, `START = [1, 3, 5, 7]`, pick-and-take, AI odds, `gl_compatibility`.
- Spawn world/UI/pearls from `main.gd`. Camera FOV 38; SubViewport MSAA_4X, scale 1.35, UPDATE_ALWAYS; light budget unchanged.
- Pearls: `Pearl.RADIUS`, layers, `Phase.REMOVED` + unpickable, shader uniform names, StandardMaterial3D fallback.
- After visual changes, re-export Web to `builds/web/index.html`. Keep `cachebust.js` and `index.service.worker.js`.
- HUD must still read at ~390px wide.

**Ask First:**
- Changing felt away from deep green baize, or replacing display/UI fonts.
- Running `scripts/deploy-web.sh`.

**Never:**
- Do not change rules, first-player timing, or input.
- Do not rebuild as an editor scene tree, add autoloads, extra viewports, reflection probes, or raise SphereMesh segments.
- Do not switch to Forward+ or invent a second HUD/Theme framework.
- Do not add a test suite. Do not relicense. Do not commit `*.uid` / `*.import` or non-`index.*` web basenames.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Setup | First load or New game from a match | Compact polished HUD; Take hidden or fully de-emphasized; New game is primary gold; options enabled; empty board | N/A |
| Match idle | Player turn, nothing selected | Take secondary/disabled; New game secondary; mode/diff locked look | Locked clicks no-op |
| Match select | Legal pearls selected | Take becomes primary gold with count; New game stays secondary | N/A |
| Result | Last pearl taken | Result card fades/scales in over table; New game still reachable | Dim does not block New game |
| Narrow | ~390px width | Title, labels, buttons remain readable and unclipped | N/A |

</frozen-after-approval>

## Code Map

- `main.gd:8-15` -- HUD color tokens; reuse
- `main.gd:122-200` -- `_box`, `_glow`, `_plaque`, `_style_button`, `_mk_btn`
- `main.gd:392-592` -- `_build_ui` HUD stack, SubViewport, result card, buttons
- `main.gd:606-645` -- `_refresh_copy`, `_enter_setup`, status strings
- `main.gd:747-754` -- `_refresh_take_button` primacy
- `main.gd:888-914` -- `_check_game_over` result reveal
- `pearl.gd` / `pearl.gdshader` -- touch only if HUD polish needs matching select feedback
- `builds/web/` -- re-export `index.*`; keep cachebust + kill-switch
- `export_presets.cfg` -- Web path `builds/web/index.html`

## Tasks & Acceptance

**Execution:**
- [x] `main.gd` -- Compact HUD hierarchy: tracked section labels for mode/difficulty, quieter plaques, gold hairline frame around the table viewport, refined spacing so the felt reads larger.
- [x] `main.gd` -- State-aware chrome: hide Take in setup; New game primary in setup; during match Take is primary only when a legal selection exists and New game is secondary; lock look unchanged.
- [x] `main.gd` -- Soft UX motion: animate result card (modulate + scale); optional short status fade; keep gameplay timing intact.
- [x] `main.gd` -- Polish status/result copy for salon voice without changing meaning.
- [x] `builds/web/index.html` -- Re-export Web; commit updated `index.*`; keep `cachebust.js` and `index.service.worker.js`.

**Acceptance Criteria:**
- Given setup, when the scene loads, then Take is not competing with New game and the table has more visual weight than the plaques.
- Given a match with pearls selected, when the HUD refreshes, then Take reads as the primary gold action.
- Given game over, when the overlay appears, then the result card animates in and New game remains usable.
- Given ~390px width, when viewing setup and match, then controls remain readable.

## Design Notes

Primary means gold fill + ink text via existing `_style_button(btn, true)`. Secondary means dark fill + muted/gold hover. Do not invent new color tokens unless a single derived alpha of GOLD is needed for hairlines.

Setup should feel like a salon invitation: wordmark, one-line rule, labeled option rows, one gold CTA. Match should feel like the table owns the screen with a thin control rail.

Result card stays a framed dark panel over the table — animate opacity/scale, do not replace with full-screen takeover.

## Verification

**Commands:**
- `godot --headless --path . --quit-after 1` -- expected: exits 0, no script errors
- `godot --headless --path . --export-release Web builds/web/index.html` -- expected: `executable` stays `index`; cachebust + kill-switch present

**Manual checks (if no CLI):**
- Setup → New game → select/take → finish → result animation → New game back to setup
- Desktop and ~390px-wide window readability
