# Client Components — Feature Design Document

## Context

- Sprocket today runs Gleam on BEAM for rendering and uses a TypeScript/Snabbdom client to hydrate and patch via WebSockets.
- We want “client components” that run in the browser, mountable into DOM nodes, while reusing Gleam code across server and client through multi-target compilation.
- The repository must be refactored into three Gleam projects (`server/`, `client/`, `shared/`).

## Goals

- Introduce a multi-target architecture enabling shared Gleam modules to compile to Erlang (server) and JavaScript (browser).
- Provide two mounting modes:
  - **Server mounting**: server renders placeholders; client runtime hydrates/mounts automatically.
  - **Client mounting**: browser API mounts a client component into any DOM node on demand.
- Define a `mount` HTML element/DSL helper to mark client component placeholders in server-rendered output.
- Keep existing server runtime and WebSocket patch protocol intact while paving a path to replace the TS client with Gleam-generated JS.
- Document build, dependency, and testing expectations for the new layout.

## Non-Goals

- No immediate rewrite of existing TS runtime; it will co-exist until the Gleam JS client reaches parity.
- Build orchestration is flexible; we can introduce lightweight scripts or tooling if they simplify multi-target builds.
- No protocol changes to server ↔ browser WebSocket messages in this phase.

## Architecture Overview

```
                   +------------------+
                   |   shared (Gleam) |
                   +------------------+
                    / \             / \
                   /   \           /   \
          Erlang target   JavaScript target
                 |               |
        +----------------+  +----------------+
        | server project |  | client project |
        +----------------+  +----------------+
                 |               |
      BEAM runtime + WS patches   |
                 |               |
        +----------------------------------+
        |        Browser / DOM             |
        |  (mount scanner + manual API)    |
        +----------------------------------+
```

## Repository Layout (proposed)

```
.
├── server/            # Gleam app targeting Erlang/OTP
│   ├── gleam.toml
│   └── src/sprocket/...  (server runtime, hooks, renderers)
├── client/            # Gleam app targeting JavaScript
│   ├── gleam.toml
│   └── src/sprocket_js/... (browser runtime, mount API)
├── shared/            # Gleam library compiled to both targets
│   ├── gleam.toml
│   └── src/sprocket_shared/... (DOM AST, props codecs, hook contracts)
├── client_ts/         # existing TS runtime (kept during transition)
└── docs/features/client_components/fdd.md
```

- `server` and `client` depend on `shared` via local path in their `gleam.toml`.
- `shared` exposes only target-agnostic modules (pure data types, codecs, helpers).

## Module Responsibilities

- **shared/**
  - `sprocket_shared/html`: target-neutral element AST and the new `mount` node definition.
  - `sprocket_shared/component`: common component type alias to normalize signatures across targets.
  - `sprocket_shared/serialize`: JSON encoders/decoders for props, mount metadata, and hook payloads that are stable across BEAM/JS.
  - `sprocket_shared/ids`: `cuid` or equivalent unique ID generator interfaces with pluggable per-target backends.
- **server/**
  - Adapts existing `sprocket/html` and render pipeline to emit `mount` nodes as HTML placeholders (e.g., `<spkt-mount data-component="..." data-props="..."></spkt-mount>`).
  - Extends runtime to register server-mounted client components (for hydration) without altering WS patch semantics.
  - Exposes helper `mount(component, props, attrs)` in the HTML DSL; guarantees deterministic hook ordering (respecting current invariants).
- **client/**
  - Browser runtime compiled from Gleam to JS; wraps DOM APIs.
  - Mount scanner: on DOMContentLoaded (or manual trigger) finds `spkt-mount` placeholders, resolves component module, decodes props, and mounts.
  - Manual API: `mount(component, target, props, opts)` for direct mounting; returns a handle exposing `set_props(new_props)` and `unmount()`.
  - Global registry API: `register(name, component)` makes user-defined components discoverable by name for both scanner-based and manual mounts (e.g., `register("example_component", example_component)` then `mount("example_component", node, props, opts)`).
  - Integrates with current TS runtime during transition through a thin JS bridge (shared registries for components and hook event dispatch).
  - Provides stable entrypoints for bundlers via `package.json` `"exports"` and `gleam build --target javascript`.
  - Uses Snabbdom for DOM patching initially; design keeps VDOM shape/codec generic so a future Gleam diff/patch engine can replace Snabbdom without changing server outputs or public APIs.

## `mount` Element Specification

- Rendered as a custom tag `<spkt-mount>` to avoid clashing with standard elements.
- Required attributes:
  - `data-component`: canonical module identifier or registered name (e.g., `sprocket_js.todo_list` or `example_component`).
  - `data-props`: JSON string encoded via `shared/serialize`.
  - `data-mode`: `"client"` (pure client) or `"server"` (server-rendered shell that expects WS rehydration).
  - `data-key`: stable key for diffing and hook identity when present.
- Optional attributes:
  - `data-hooks`: serialized list of client hooks to preload.
  - `data-bootstrap`: inline payload to seed client state before WS connect.
- Server DSL helper `mount(component, props, attrs)` guarantees correct encoding and escapes JSON for safe embedding.
- Runtime keeps an instance registry keyed by `(data-component, data-key | DOM node identity)`; when `data-props` changes (via DOM patch or manual API), the existing instance receives `set_props` and re-renders while preserving hook/state.

## Mounting Flows

### 1) Server Mounting (hydration)

1. Server renders HTML and includes `<spkt-mount ...>` placeholders produced by the DSL helper.
2. HTML delivered to browser; TS runtime continues to handle WS patches.
3. Gleam JS runtime scans for `spkt-mount` nodes, resolves component modules (via registry of `register(name, component)` plus built-ins), decodes props, and calls `mount(...)`.
4. Mounted component renders into the placeholder; for `"server"` mode it also attaches WS event bridges so updates stay in sync with BEAM runtime.
5. Cleanup hooks ensure unmounting when the node is removed by patches.
6. If the server updates `data-props` in a subsequent patch, the runtime detects the change, calls `set_props` on the existing instance, and re-renders without recreating hooks/state.

### 2) Client Mounting (imperative API)

1. App code imports `sprocket_js` bundle, optionally registers components (`register("example_component", example_component)`), and calls `mount(component_or_name, target, props, opts)`.
2. Runtime compiles/render VDOM (Snabbdom-compatible or future Gleam VDOM) and patches into `target`.
3. Subsequent `handle.set_props(new_props)` triggers re-render on the same instance (no hook recreation), maintaining state.
4. Optional integration with WS for hybrid components: opts may pass a `socket` or `event dispatcher`.

## Component Interface (shared contract)

- Components stay pure functions over props; effects isolated in hooks.
- Proposed signature (target-neutral):
  - `pub type Component(ctx: Context, props: Props) -> Rendered`
  - `Context` becomes an interface that can be satisfied by BEAM runtime or browser runtime; hook ordering invariants remain identical.
- Props and event payloads must be JSON serializable via `shared/serialize`; no `Dynamic` or target-specific types cross the boundary.
- Runtime must retain the same `Context`/hook indices across prop updates so `set_props` triggers a re-render, not a re-creation.
- VDOM shape/codec defined in `shared` must be Snabbdom-compatible now and forward-compatible with a future Gleam diff/patcher; avoid Snabbdom-specific types leaking into shared interfaces.

## Build & Packaging

- Each project owns its `gleam.toml`; root `package.json` adds scripts:
  - `yarn server:build` → `cd server && gleam build`
  - `yarn client:build` → `cd client && gleam build --target javascript`
  - `yarn shared:test` → `cd shared && gleam test --target javascript`
- Browser bundle: start with `gleam build --target javascript` output; bundle via existing or new tooling (Parcel/Vite/other) to package `build/dev/javascript/**/*.mjs` as the distributed client runtime. Snabbdom remains the patcher during the transition; the bundling setup must allow swapping to a Gleam-based patcher later with minimal surface changes.
- CI updates:
  - Run `gleam test` in `server`.
  - Run `gleam test --target javascript` in `shared` and (when available) `client`.
  - Preserve current `yarn test` for TS runtime until removed.

## Compatibility & Migration

- Phase 1: Gleam JS runtime coexists with current TS runtime; both can mount components. Shared registry avoids double initialization on the same node. Snabbdom remains the browser patcher.
- Phase 2: Move TS logic (render, patch, hooks, events) into `client` Gleam modules using `shared` contracts; still backed by Snabbdom via an adapter.
- Phase 3: Evaluate/benchmark a Gleam diff/patcher. If acceptable, replace Snabbdom behind the adapter without changing public APIs; otherwise keep Snabbdom.
- Phase 4: Drop TS runtime and rely solely on Gleam-generated JS bundle with the chosen patcher (Snabbdom or Gleam).

## Data Contracts

- Mount metadata JSON schema (stable across targets):
  ```json
  {
    "component": "sprocket_js.example",
    "props": { "...": "..." },
    "mode": "client|server",
    "key": "optional",
    "hooks": ["optional hook names"],
    "bootstrap": { "optional": "payload" }
  }
  ```
- Event payloads continue to use existing WS envelope (`["event", {...}]`, `["hook", {...}]`); client runtime reuses encoders from `shared/serialize`.

## Testing Strategy

- Shared: gleeunit suites validating JSON codecs, mount metadata, and hook ordering invariants compiled for both BEAM and JS targets.
- Client: browser-target tests via `gleam test --target javascript` plus lightweight DOM/VDOM assertions run in Node (JSDOM) before integrating with Playwright.
- Props-update contract tests: ensure `set_props` re-renders without resetting hook state for both server-driven (`data-props` patch) and manual API flows.
- Patcher-pluggability tests: adapters to ensure Snabbdom and any future Gleam patcher can consume the shared VDOM shape interchangeably; golden VDOM fixtures rendered by server must hydrate correctly under both patchers.
- Server: extend existing tests to cover HTML rendering of `mount` helper and lifecycle (cleanup, reconciliation).
- Cross-target contract tests: golden JSON fixtures asserting identical encodings from BEAM and JS builds.

## Operational Considerations

- Logging: reuse structured logging; client runtime exposes minimal `console.error` only on unrecoverable mount failures.
- Performance: mount scanner runs once on DOMContentLoaded and can be re-run idempotently after patch batches.
- Security: CSRF token flow unchanged; mount metadata must be sanitized and encoded by server helper to avoid injection.

## Risks & Mitigations

- **Dual runtimes collision**: ensure single owner per `spkt-mount` via attribute `data-owner="gleam-js|ts"` and runtime checks.
- **Bundle size**: monitor Gleam JS output; tree-shake unused modules via bundler entrypoints.
- **Cross-target parity**: keep `shared` small and pure; avoid BEAM-specific modules leaking into JS target.
- **Hook invariants**: maintain stable ordering; add tests that compare hook sequences across targets.
- **Interop loading**: require explicit registration map from module name → factory in the JS bundle to avoid dynamic `import()` at runtime in production builds.

## Open Questions

- Should `mount` support streaming props updates, or remain a one-time bootstrap until WS resumes control?
- What is the minimal public surface for the client runtime (e.g., expose `connect` replacement now or after TS parity)?
- How do we version shared schemas to allow progressive rollout without breaking older clients?
