import gleam/list
import gleam/option.{Option}
import gleam/erlang/process.{Subject}
import glisten/handler.{HandlerMessage}
import sprocket/identifiable_callback.{CallbackFn, IdentifiableCallback}
import sprocket/hooks.{Hook}
import sprocket/utils/ordered_map.{OrderedMap}
import sprocket/utils/unique.{Unique}

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
  ComponentWip(hooks: ComponentHooks, index: Int)
}

pub type Socket {
  Socket(
    wip: ComponentWip,
    handlers: List(EventHandler),
    ws: Option(WebSocket),
    render_update: fn() -> Nil,
  )
}

pub fn new(ws: Option(WebSocket)) -> Socket {
  Socket(
    wip: ComponentWip(hooks: ordered_map.new(), index: 0),
    handlers: [],
    ws: ws,
    render_update: fn() { Nil },
  )
}

pub fn reset_for_render(socket: Socket) {
  Socket(..socket, handlers: [])
}

pub fn fetch_or_init_hook(
  socket: Socket,
  init: fn() -> Hook,
) -> #(Socket, Hook, Int) {
  let index = socket.wip.index
  let hooks = socket.wip.hooks

  case ordered_map.get(hooks, index) {
    Ok(hook) -> {
      // hook found, return it
      #(
        Socket(..socket, wip: ComponentWip(..socket.wip, index: index + 1)),
        hook,
        index,
      )
    }
    Error(Nil) -> {
      // TODO: add a check here for is_first_render and if it isnt, throw an error
      // case is_first_render {
      //   True -> {
      //     logger.error(
      //       "
      //       Hook not found for index: " <> int.to_string(index) <> ". This indicates a hook was dynamically
      //       created since first render which is not allowed.
      //     ",
      //     )

      //     // TODO: we should handle this error more gracefully in production environments
      //     panic
      //   }
      //   False -> Nil
      // }

      // first render, return the initialized hook and index
      let hook = init()

      #(
        Socket(
          ..socket,
          wip: ComponentWip(
            hooks: ordered_map.insert(socket.wip.hooks, index, hook),
            index: index + 1,
          ),
        ),
        hook,
        index,
      )
    }
  }
}

pub fn update_hook(socket: Socket, hook: Hook, index: Int) -> Socket {
  Socket(
    ..socket,
    wip: ComponentWip(
      ..socket.wip,
      hooks: ordered_map.update(socket.wip.hooks, index, hook),
    ),
  )
}

pub fn push_event_handler(
  socket: Socket,
  identifiable_cb: IdentifiableCallback,
) -> #(Socket, Unique) {
  let IdentifiableCallback(id, cb) = identifiable_cb

  #(Socket(..socket, handlers: [EventHandler(id, cb), ..socket.handlers]), id)
}

pub fn get_event_handler(
  socket: Socket,
  id: Unique,
) -> #(Socket, Result(EventHandler, Nil)) {
  let handler =
    list.find(
      socket.handlers,
      fn(h) {
        let EventHandler(i, _) = h
        i == id
      },
    )

  #(socket, handler)
}
