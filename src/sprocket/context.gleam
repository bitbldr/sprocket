import gleam/int
import gleam/list
import gleam/map.{Map}
import gleam/option.{type Option, None, Some}
import gleam/erlang/process.{type Subject}
import gleam/dynamic.{type Dynamic}
import ids/cuid
import sprocket/internal/utils/ordered_map.{type OrderedMap}
import sprocket/internal/utils/unique.{type Unique}
import sprocket/internal/logger
import sprocket/internal/exceptions.{throw_on_unexpected_deps_mismatch}

pub type HandlerFn =
  fn(Option(CallbackParam)) -> Nil

pub type CallbackParam {
  CallbackString(value: String)
}

pub fn callback_param_from_string(value: String) -> CallbackParam {
  CallbackString(value)
}

pub type IdentifiableHandler {
  IdentifiableHandler(id: Unique, handler_fn: HandlerFn)
}

pub type Attribute {
  Attribute(name: String, value: Dynamic)
  Event(name: String, handler: IdentifiableHandler)
  ClientHook(id: Unique, name: String)
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
  SafeHtml(html: String)
  Raw(text: String)
}

pub type Updater(r) {
  Updater(send: fn(r) -> Result(Nil, Nil))
}

pub type Dispatcher {
  Dispatcher(dispatch: fn(String, String, Option(String)) -> Result(Nil, Nil))
}

pub type ComponentHooks =
  OrderedMap(Int, Hook)

pub type HookDependencies =
  List(Dynamic)

// helper function to create a dependency from a value
pub fn dep(dependency: a) -> Dynamic {
  dynamic.from(dependency)
}

pub type HookTrigger {
  OnMount
  OnUpdate
  WithDeps(deps: HookDependencies)
}

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

pub type Hook {
  Callback(id: Unique, callback: fn() -> Nil, prev: Option(CallbackResult))
  Memo(id: Unique, value: Dynamic, prev: Option(MemoResult))
  Effect(
    id: Unique,
    effect: fn() -> EffectCleanup,
    trigger: HookTrigger,
    prev: Option(EffectResult),
  )
  Handler(id: Unique, handler_fn: HandlerFn)
  Reducer(id: Unique, reducer: Dynamic, cleanup: fn() -> Nil)
  State(id: Unique, value: Dynamic)
  Client(id: Unique, name: String, handle_event: Option(ClientEventHandler))
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
    Error(list.LengthMismatch) ->
      // Dependency lists are different sizes, so they must have changed
      // this should never occur and means that a hook's deps list was dynamically changed
      throw_on_unexpected_deps_mismatch(#("compare_deps", prev_deps, deps))

    Ok(zipped_deps) -> {
      case
        list.all(
          zipped_deps,
          fn(z) {
            let #(a, b) = z
            a == b
          },
        )
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
    handlers: List(IdentifiableHandler),
    render_update: fn() -> Nil,
    update_hook: fn(Unique, fn(Hook) -> Hook) -> Nil,
    dispatch_event: fn(Unique, String, Option(String)) -> Result(Nil, Nil),
    cuid_channel: Subject(cuid.Message),
    providers: Map(String, Dynamic),
  )
}

pub fn provider(key: String, value: v, element: Element) -> Element {
  Provider(key, dynamic.from(value), element)
}

pub fn new(
  view: Element,
  cuid_channel: Subject(cuid.Message),
  dispatcher: Option(Dispatcher),
) -> Context {
  Context(
    view: view,
    wip: ComponentWip(hooks: ordered_map.new(), index: 0, is_first_render: True),
    handlers: [],
    render_update: fn() { Nil },
    update_hook: fn(_index, _updater) { Nil },
    dispatch_event: fn(id, name, payload) {
      case dispatcher {
        Some(Dispatcher(dispatch: dispatch)) ->
          dispatch(unique.to_string(id), name, payload)
        None -> Error(Nil)
      }
    },
    cuid_channel: cuid_channel,
    providers: map.new(),
  )
}

pub fn reset_for_render(ctx: Context) {
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
          logger.error(
            "
            Hook not found for index: " <> int.to_string(index) <> ". This indicates a hook was dynamically
            created since first render which is not allowed.
          ",
          )

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

pub fn push_event_handler(
  ctx: Context,
  identifiable_cb: IdentifiableHandler,
) -> #(Context, Unique) {
  let IdentifiableHandler(id, cb) = identifiable_cb

  #(Context(..ctx, handlers: [IdentifiableHandler(id, cb), ..ctx.handlers]), id)
}

pub fn get_event_handler(
  ctx: Context,
  id: Unique,
) -> #(Context, Result(IdentifiableHandler, Nil)) {
  let handler =
    list.find(
      ctx.handlers,
      fn(h) {
        let IdentifiableHandler(i, _) = h
        i == id
      },
    )

  #(ctx, handler)
}

pub fn dispatch_event(
  ctx: Context,
  id: Unique,
  name: String,
  payload: Option(String),
) {
  ctx.dispatch_event(id, name, payload)
}
