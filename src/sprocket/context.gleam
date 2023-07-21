import gleam/int
import gleam/list
import gleam/option.{Option}
import gleam/erlang/process.{Subject}
import glisten/handler.{HandlerMessage}
import sprocket/internal/identifiable_callback.{CallbackFn,
  IdentifiableCallback}
import sprocket/hooks.{Hook}
import sprocket/internal/utils/ordered_map.{OrderedMap}
import sprocket/internal/utils/unique.{Unique}
import sprocket/internal/logger

pub type EventHandler {
  EventHandler(id: Unique, handler: CallbackFn)
}

pub type WebSocket =
  Subject(HandlerMessage)

pub type Updater(r) {
  Updater(send: fn(r) -> Result(Nil, Nil))
}

pub type ComponentHooks =
  OrderedMap(Int, Hook)

pub type ComponentWip {
  ComponentWip(hooks: ComponentHooks, index: Int, is_first_render: Bool)
}

pub type Context {
  Context(
    wip: ComponentWip,
    handlers: List(EventHandler),
    ws: Option(WebSocket),
    render_update: fn() -> Nil,
  )
}

pub fn new(ws: Option(WebSocket)) -> Context {
  Context(
    wip: ComponentWip(hooks: ordered_map.new(), index: 0, is_first_render: True),
    handlers: [],
    ws: ws,
    render_update: fn() { Nil },
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
