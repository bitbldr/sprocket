import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import sprocket/internal/exceptions.{throw_on_unexpected_deps_mismatch}
import sprocket/internal/logger
import sprocket/internal/utils/common.{dynamic_from}
import sprocket/internal/utils/cuid
import sprocket/internal/utils/ordered_map.{type OrderedMap}
import sprocket/internal/utils/unique.{type Unique}
import sprocket/internal/utils/unsafe_coerce.{unsafe_coerce}

pub type ElementId

pub type EventHandler {
  EventHandler(id: Unique(ElementId), kind: String, cb: fn(Dynamic) -> Nil)
}

pub type ClientHookId {
  ClientHookId(
    element_id: Unique(ElementId),
    name: String,
    hook_id: Unique(HookId),
  )
}

pub type Attribute {
  Attribute(name: String, value: Dynamic)
  Event(kind: String, cb: fn(Dynamic) -> Nil)
  ClientHook(id: Unique(HookId), name: String)
}

pub type StatefulComponent(p) =
  fn(Context, p) -> #(Context, Element)

pub type DynamicStatefulComponent =
  fn(Context, Dynamic) -> #(Context, Element)

pub type Element {
  Element(tag: String, attrs: List(Attribute), children: List(Element))
  Component(component: DynamicStatefulComponent, props: Dynamic)
  Fragment(children: List(Element))
  Debug(id: String, meta: Option(Dynamic), element: Element)
  Keyed(key: String, element: Element)
  IgnoreUpdate(element: Element)
  Provider(key: String, value: Dynamic, element: Element)
  Text(text: String)
  Custom(kind: String, data: String)
}

/// Creates a new stateful component element from a given component function and props.
pub fn component(c: StatefulComponent(p), props: p) -> Element {
  let component =
    c
    |> dynamic_from()
    |> unsafe_coerce()

  let props =
    props
    |> dynamic_from()

  Component(component, props)
}

pub type Updater(r) =
  fn(r) -> Result(Nil, Nil)

pub type ClientHookEventDispatcher =
  fn(Unique(HookId), String, Option(Dynamic)) -> Nil

pub type ComponentHooks =
  OrderedMap(Int, Hook)

pub type HookDependency =
  Dynamic

pub type HookDependencies =
  List(HookDependency)

pub type EffectCleanup =
  Option(fn() -> Nil)

pub type EffectResult {
  EffectResult(cleanup: EffectCleanup, deps: Option(HookDependencies))
}

pub type CallbackResult {
  CallbackResult(deps: Option(HookDependencies))
}

pub type MemoResult {
  MemoResult(deps: Option(HookDependencies))
}

pub type ClientHookDispatcher =
  fn(String, Option(Dynamic)) -> Nil

pub type ClientHookEventHandler =
  fn(String, Dynamic, ClientHookDispatcher) -> Nil

pub type HookId

pub type Hook {
  Callback(
    id: Unique(HookId),
    callback: fn() -> Nil,
    prev: Option(CallbackResult),
  )
  Memo(id: Unique(HookId), value: Dynamic, prev: Option(MemoResult))
  Effect(
    id: Unique(HookId),
    effect: fn() -> EffectCleanup,
    deps: HookDependencies,
    prev: Option(EffectResult),
  )
  Reducer(id: Unique(HookId), reducer: Dynamic, cleanup: fn() -> Nil)
  State(id: Unique(HookId), value: Dynamic)
  Client(
    id: Unique(HookId),
    name: String,
    handle_event: Option(ClientHookEventHandler),
  )
}

// Returns true if the hook has the given id
pub fn has_id(hook: Hook, hook_id: Unique(HookId)) -> Bool {
  case hook {
    Callback(id, _, _) if id == hook_id -> True
    Memo(id, _, _) if id == hook_id -> True
    Effect(id, _, _, _) if id == hook_id -> True
    State(id, _) if id == hook_id -> True
    Client(id, _, _) if id == hook_id -> True
    _ -> False
  }
}

pub type Compared(a) {
  Changed(changed: a)
  Unchanged
}

pub fn compare_deps(
  prev_deps: HookDependencies,
  deps: HookDependencies,
) -> Compared(HookDependencies) {
  // zip deps together and compare each one with the previous to see if they are equal
  case list.strict_zip(prev_deps, deps) {
    Error(_) ->
      // Dependency lists are different sizes, so they must have changed
      // this should never occur and means that a hook's deps list was dynamically changed
      throw_on_unexpected_deps_mismatch(#("compare_deps", prev_deps, deps))

    Ok(zipped_deps) -> {
      case
        list.all(zipped_deps, fn(z) {
          let #(a, b) = z
          a == b
        })
      {
        True -> Unchanged
        _ -> Changed(deps)
      }
    }
  }
}

pub type ComponentWip {
  ComponentWip(hooks: ComponentHooks, index: Int, is_first_render: Bool)
}

pub type Context {
  Context(
    el: Element,
    wip: ComponentWip,
    handlers: List(EventHandler),
    client_hooks: List(ClientHookId),
    trigger_reconciliation: fn() -> Nil,
    update_hook: fn(Unique(HookId), fn(Hook) -> Hook) -> Nil,
    dispatch_client_hook_event: ClientHookEventDispatcher,
    cuid_channel: Subject(cuid.Message),
    providers: Dict(String, Dynamic),
  )
}

pub fn new(
  el: Element,
  cuid_channel: Subject(cuid.Message),
  dispatch_client_hook_event: ClientHookEventDispatcher,
  trigger_reconciliation: fn() -> Nil,
  update_hook: fn(Unique(HookId), fn(Hook) -> Hook) -> Nil,
) -> Context {
  Context(
    el: el,
    wip: ComponentWip(hooks: ordered_map.new(), index: 0, is_first_render: True),
    handlers: [],
    client_hooks: [],
    trigger_reconciliation: trigger_reconciliation,
    update_hook: update_hook,
    dispatch_client_hook_event: dispatch_client_hook_event,
    cuid_channel: cuid_channel,
    providers: dict.new(),
  )
}

pub fn prepare_for_reconciliation(ctx: Context) {
  Context(..ctx, handlers: [], client_hooks: [])
}

pub fn fetch_or_init_hook(
  ctx: Context,
  init: fn() -> Hook,
) -> #(Context, Hook, Int) {
  let index = ctx.wip.index
  let hooks = ctx.wip.hooks

  case ordered_map.get(hooks, index) {
    Ok(hook) -> {
      // hook found, return it
      #(
        Context(..ctx, wip: ComponentWip(..ctx.wip, index: index + 1)),
        hook,
        index,
      )
    }
    Error(Nil) -> {
      // check here for is_first_render and if it isnt, throw an error
      case ctx.wip.is_first_render {
        True -> Nil
        False -> {
          logger.error("
            Hook not found for index: " <> int.to_string(index) <> ". This indicates a hook was dynamically
            created since first render which is not allowed.
          ")

          // TODO: handle this error more gracefully in production environments
          panic
        }
      }

      // first render, return the initialized hook and index
      let hook = init()

      #(
        Context(
          ..ctx,
          wip: ComponentWip(
            hooks: ordered_map.insert(ctx.wip.hooks, index, hook),
            index: index + 1,
            is_first_render: ctx.wip.is_first_render,
          ),
        ),
        hook,
        index,
      )
    }
  }
}

pub fn update_hook(ctx: Context, hook: Hook, index: Int) -> Context {
  Context(
    ..ctx,
    wip: ComponentWip(
      ..ctx.wip,
      hooks: ordered_map.update(ctx.wip.hooks, index, hook),
    ),
  )
}

pub fn push_event_handler(ctx: Context, handler: EventHandler) -> Context {
  Context(..ctx, handlers: [handler, ..ctx.handlers])
}

pub fn get_event_handler(
  ctx: Context,
  id: Unique(ElementId),
) -> #(Context, Result(EventHandler, Nil)) {
  let handler =
    list.find(ctx.handlers, fn(h) {
      let EventHandler(i, _, _) = h
      i == id
    })

  #(ctx, handler)
}

pub fn push_client_hook(ctx: Context, hook: ClientHookId) -> Context {
  Context(..ctx, client_hooks: [hook, ..ctx.client_hooks])
}

pub fn get_client_hook(
  ctx: Context,
  id: Unique(ElementId),
  name: String,
) -> #(Context, Result(ClientHookId, Nil)) {
  let hook =
    list.find(ctx.client_hooks, fn(h) {
      let ClientHookId(i, n, _) = h
      i == id && n == name
    })

  #(ctx, hook)
}

pub fn dispatch_client_hook_event(
  ctx: Context,
  id: Unique(HookId),
  kind: String,
  payload: Option(Dynamic),
) {
  ctx.dispatch_client_hook_event(id, kind, payload)
}
