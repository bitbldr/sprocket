import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import ids/cuid
import sprocket/internal/exceptions.{throw_on_unexpected_deps_mismatch}
import sprocket/internal/logger
import sprocket/internal/utils/ordered_map.{type OrderedMap}
import sprocket/internal/utils/unique.{type Unique}

pub type ElementId

pub type EventHandler {
  EventHandler(id: Unique(ElementId), kind: String, cb: fn(Dynamic) -> Nil)
}

pub type Attribute {
  Attribute(name: String, value: Dynamic)
  Event(kind: String, cb: fn(Dynamic) -> Nil)
  ClientHook(id: Unique(HookId), name: String)
}

pub type AbstractFunctionalComponent =
  fn(Context, Dynamic) -> #(Context, Element)

pub type FunctionalComponent(p) =
  fn(Context, p) -> #(Context, Element)

pub type Element {
  Element(tag: String, attrs: List(Attribute), children: List(Element))
  Component(component: FunctionalComponent(Dynamic), props: Dynamic)
  Fragment(children: List(Element))
  Debug(id: String, meta: Option(Dynamic), element: Element)
  Keyed(key: String, element: Element)
  IgnoreUpdate(element: Element)
  Provider(key: String, value: Dynamic, element: Element)
  Text(text: String)
  Custom(kind: String, data: String)
}

pub type Updater(r) {
  Updater(send: fn(r) -> Result(Nil, Nil))
}

pub type EventEmitter =
  fn(String, String, Option(String)) -> Result(Nil, Nil)

pub type ComponentHooks =
  OrderedMap(Int, Hook)

pub type HookDependencies =
  List(Dynamic)

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

pub type ClientDispatcher =
  fn(String, Option(String)) -> Result(Nil, Nil)

pub type ClientEventHandler =
  fn(String, Option(Dynamic), ClientDispatcher) -> Nil

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
    handle_event: Option(ClientEventHandler),
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

// helper function to create a dependency from a value
pub fn dep(dependency: a) -> Dynamic {
  dynamic.from(dependency)
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
    view: Element,
    wip: ComponentWip,
    handlers: List(EventHandler),
    render_update: fn() -> Nil,
    update_hook: fn(Unique(HookId), fn(Hook) -> Hook) -> Nil,
    emit: fn(Unique(HookId), String, Option(String)) -> Result(Nil, Nil),
    cuid_channel: Subject(cuid.Message),
    providers: Dict(String, Dynamic),
  )
}

pub fn new(
  view: Element,
  cuid_channel: Subject(cuid.Message),
  emitter: Option(EventEmitter),
  render_update: fn() -> Nil,
  update_hook: fn(Unique(HookId), fn(Hook) -> Hook) -> Nil,
) -> Context {
  Context(
    view: view,
    wip: ComponentWip(hooks: ordered_map.new(), index: 0, is_first_render: True),
    handlers: [],
    render_update: render_update,
    update_hook: update_hook,
    emit: fn(id, name, payload) {
      case emitter {
        Some(emitter) -> emitter(unique.to_string(id), name, payload)
        None -> Error(Nil)
      }
    },
    cuid_channel: cuid_channel,
    providers: dict.new(),
  )
}

pub fn prepare_for_reconciliation(ctx: Context) {
  Context(..ctx, handlers: [])
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

pub fn emit_event(
  ctx: Context,
  id: Unique(HookId),
  name: String,
  payload: Option(String),
) {
  ctx.emit(id, name, payload)
}

pub fn provider(key: String, value: v, element: Element) -> Element {
  Provider(key, dynamic.from(value), element)
}
