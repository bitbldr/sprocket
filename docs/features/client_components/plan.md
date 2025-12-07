# Client Components — Implementation Plan

> Instructions: Every phase and task uses a checkbox. Check items as they complete. Each phase ends with a DEVOPS subsection; keep all feasible work in developer tasks and reserve DEVOPS only for actions that cannot be done in code or by the developer.

## Phase 0 — Project Bootstrapping
- [ ] Create `shared/`, `server/`, `client/` Gleam project skeletons (`gleam new`) and move existing sources into the appropriate roots.
- [ ] Wire local path dependencies (`server` → `shared`, `client` → `shared`) and ensure both BEAM/JS builds succeed.
- [ ] Add root `package.json` scripts (`server:build`, `client:build`, `shared:test`) and verify `yarn` tasks run.
- [ ] Add `mount` helper stub in server HTML DSL emitting placeholder tag with encoded props.
- [ ] Document new layout in `README.md` and update AGENTS.md pointers if needed.
- DEVOPS
  - [ ] None (developer-owned).

## Phase 1 — Shared Contracts & VDOM Shape
- [ ] Define shared VDOM/node types and codecs in `shared` (Snabbdom-compatible, patcher-agnostic).
- [ ] Extract shared IDs/serialization utilities used by server/client.
- [ ] Add gleeunit tests for cross-target codec parity (BEAM vs JS).
- [ ] Integrate shared VDOM shape into server render output (without changing runtime behavior).
- DEVOPS
  - [ ] None (developer-owned).

## Phase 2 — Client Runtime (Gleam → JS) Coexisting with TS
- [ ] Implement `sprocket_js` runtime scaffold: registry (`register/2`), `mount/4`, scanner for `<spkt-mount>`.
- [ ] Bridge to existing TS patcher (Snabbdom) via adapters consuming shared VDOM.
- [ ] Ensure prop updates call `set_props` and preserve hook/state; add contract tests.
- [ ] Expose bundler entrypoints and outputs consistent with current `client/dist` usage.
- [ ] Update docs and examples to demonstrate manual mounting and server-rendered mounting.
- DEVOPS
  - [ ] None (developer-owned).

## Phase 3 — Server Runtime Integration
- [ ] Extend server runtime to emit `spkt-mount` placeholders and to send prop updates via patches.
- [ ] Ensure hook invariants and reconciliation semantics remain stable with new `mount` nodes.
- [ ] Add server-side tests for mount rendering, cleanup, and prop-update paths.
- [ ] Verify end-to-end: server-rendered page hydrates and prop changes re-render without remount.
- DEVOPS
  - [ ] None (developer-owned).

## Phase 4 — CI, Packaging, and Release Prep
- [ ] Update CI workflows to build/test `shared`, `server`, `client` (JS target) and keep existing TS tests until sunset.
- [ ] Add patcher-pluggability test job (Snabbdom + future Gleam patcher placeholder).
- [ ] Publish migration notes in docs and changelog.
- DEVOPS
  - [ ] Configure CI secrets or runners if needed for new JS build/test matrix (only if not already available).

## Phase 5 — Patcher Evaluation & Swap (Optional)
- [ ] Prototype Gleam diff/patcher; benchmark against Snabbdom on representative fixtures.
- [ ] Implement adapter layer so either patcher can be toggled via build flag/config.
- [ ] Decide go/no-go; if go, switch default to Gleam patcher and deprecate Snabbdom dependency.
- [ ] Remove redundant TS client once parity is confirmed and coverage retained.
- DEVOPS
  - [ ] Update CDN/package publishing targets if bundle names change during patcher swap.
