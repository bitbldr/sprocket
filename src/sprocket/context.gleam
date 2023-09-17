import gleam/int
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import sprocket/html/attributes.{Attribute}
import sprocket/internal/identifiable_callback.{CallbackFn,
  IdentifiableCallback}
import sprocket/hooks.{Hook}
import sprocket/internal/utils/ordered_map.{OrderedMap}
import sprocket/internal/utils/unique.{Unique}
import sprocket/internal/logger

pub type AbstractFunctionalComponent =
  fn(Context, Dynamic) -> #(Context, List(Element))

pub type FunctionalComponent(p) =
  fn(Context, p) -> #(Context, List(Element))

pub type Element {
  Element(tag: String, attrs: List(Attribute), children: List(Element))
  Component(component: FunctionalComponent(Dynamic), props: Dynamic)
  Debug(id: String, meta: Option(Dynamic), element: Element)
  Keyed(key: String, element: Element)
  IgnoreUpdate(element: Element)
  SafeHtml(html: String)
  Raw(text: String)
}

pub type EventHandler {
  EventHandler(id: Unique, handler: CallbackFn)
}

pub type Updater(r) {
  Updater(send: fn(r) -> Result(Nil, Nil))
}

pub type Dispatcher {
  Dispatcher(dispatch: fn(String, String, Option(String)) -> Result(Nil, Nil))
}

pub type ComponentHooks =
  OrderedMap(Int, Hook)

pub type ComponentWip {
  ComponentWip(hooks: ComponentHooks, index: Int, is_first_render: Bool)
}

pub type Context {
  Context(
    view: Element,
    wip: ComponentWip,
    handlers: List(EventHandler),
    render_update: fn() -> Nil,
    update_hook: fn(Unique, fn(Hook) -> Hook) -> Nil,
    dispatch_event: fn(Unique, String, Option(String)) -> Result(Nil, Nil),
  )
}

pub fn new(view: Element, dispatcher: Option(Dispatcher)) -> Context {
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
  identifiable_cb: IdentifiableCallback,
) -> #(Context, Unique) {
  let IdentifiableCallback(id, cb) = identifiable_cb

  #(Context(..ctx, handlers: [EventHandler(id, cb), ..ctx.handlers]), id)
}

pub fn get_event_handler(
  ctx: Context,
  id: Unique,
) -> #(Context, Result(EventHandler, Nil)) {
  let handler =
    list.find(
      ctx.handlers,
      fn(h) {
        let EventHandler(i, _) = h
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
