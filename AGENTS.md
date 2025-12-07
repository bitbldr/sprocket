# AGENTS.md — Sprocket Repository Guide

Scope: This file governs the entire repository.

Read this first if you’re contributing, reviewing, or acting as an automated coding agent.

## Reading Order

README.md (overview & usage)
CONTRIBUTING.md (workflow & setup)
GitHub Issues (tasks/backlog): https://github.com/bitbldr/sprocket/issues
HexDocs (public API reference): https://hexdocs.pm/sprocket/

## Intent & Principles

- SOLID, KISS, YAGNI
- Functional-first: pure Gleam functions where possible; isolate effects in hooks/runtime
- Security by default: server <-> client over WS with CSRF token; least-privilege event handling
- Testability: deterministic hooks/reconciler; prefer fast gleeunit/Jest tests before integration
- Clarity: idiomatic Gleam naming; minimal comments unless behavior is non-obvious

## Expectations for Agents/Contributors

- Skim README.md and client/server entry points before coding.
- Drive planning via GitHub Issues; no in-repo trackers.
- Keep changes small and focused; open an issue/ADR for protocol or API changes.
- Add/Update tests for behaviors you touch. New features get both Gleam (server) and TS (client) coverage when feasible.
- Respect hook invariants: do not create hooks conditionally; order must stay stable between renders.
- Structured logging only: use `sprocket/internal/logger` on the server; avoid console noise in client except errors.

## Session Handoff Protocol (GitHub Issues)

- Start: pick a ready P0/P1 issue, self-assign, post a brief “Session Start” plan.
- During: add concise updates at milestones; adjust labels as needed.
- End: comment “What landed” + “Next steps”; update labels/boards. If behavior/architecture changed, update README or add a short note in the issue.

### Task Tooling

No in-repo automation scripts. Use GitHub UI/CLI (`gh issue status|view|comment`) to track status. Keep tokens out of the repo.

## Code Organization

- `server/` — BEAM-targeted Gleam project (runtime, hooks, renderers). Public API lives in `server/src/sprocket*.gleam`; internals under `server/src/sprocket/internal/*`; FFI in `server/src/sprocket_ffi.erl`. Tests live in `server/test/`.
- `client/` — Gleam → JavaScript project scaffold for the future browser runtime (currently placeholder).
- `shared/` — Gleam project for cross-target contracts/utilities compiled to both BEAM and JS (currently placeholder).
- `client_ts/` — Existing TypeScript client (Parcel + Snabbdom): entry `client_ts/src/sprocket.ts`, rendering/patching in `render.ts`, `patch.ts`, event & hook plumbing in `events.ts`, `hooks.ts`.
- Generated artifacts: `server/build/`, `client/build/`, `shared/build/`, `client_ts/dist/`, `.parcel-cache/` (keep out of git).

### File/Layout Rules

- Gleam: keep modules focused; avoid sprawling functions. Public surface lives outside `internal/`.
- TypeScript: one module per concern; prefer named exports; keep client protocol constants centralized.
- Internal modules listed in `gleam.toml` remain undocumented; do not promote them without updating the config.

## Workflow & Quality

- Protocol stability matters: server runtime messages (`"ok"`, `"update"`, `"hook"`, `"error"`) must stay in sync with client handlers.
- Hooks: `compare_deps` treats length changes as errors; `fetch_or_init_hook` panics if hooks are added conditionally. Preserve `trigger_reconciliation` semantics.
- Keys & IDs: Node identity depends on `cuid` + `key_attr` (`spkt-key`). Keep IDs/keys stable when touching reconciliation or patch logic.
- Testing/Build commands:
  - `yarn server:build` — `cd server && gleam build`
  - `yarn client:build` — `cd client && gleam build --target javascript`
  - `yarn shared:test` — `cd shared && gleam test --target javascript`
  - `yarn test` — runs server gleeunit, shared JS tests, and TS client jest suite
  - `yarn client_ts:test` — jest against legacy TS client
  - `yarn build` — server BEAM build + Gleam JS build + Parcel bundle for `client_ts`
  - `yarn clean` — remove build/dist caches
- Formatting: `gleam format`; TS currently unopinionated—match existing style.
- CI expectation: green tests before merge; no generated artifacts committed.

## Roadmap & Priorities

- Track priorities in GitHub Issues/Milestones (no in-repo roadmap file). Label by P0/P1/P2.

## Coding Standards

- Gleam: pure functions by default; effects inside hooks/runtime actors. Pattern match exhaustively; avoid `panic` except in invariant enforcement.
- BEAM: use actors (`gleam/otp`) for concurrency; honor `call_timeout` (1000 ms). Clean up effects/client hooks on shutdown.
- TypeScript client: keep side effects localized; prefer pure helpers for VDOM transformations; avoid global state.
- Logging: structured via `logger` backend; client `console.error` for surfaced errors only.
- Naming: modules snake_case, functions lower_snake_case, types PascalCase (Gleam); TS follows lowerCamel for vars, PascalCase for types.
- No dead code; remove unused helpers/tests when obsolete.

## Documentation Rules

- README.md is source of truth for usage; extend it when public APIs change.
- Update HexDocs annotations when adding public functions/types.
- All planning/progress in GitHub Issues; link issues in PRs/commits.

## Ambiguity

- Prefer the simplest design that satisfies current requirements.
- If multiple options exist, note the rationale in the issue/PR and, if architectural, add a short design note to README or a new doc.
- User requirements and public API stability take precedence over internal convenience.
