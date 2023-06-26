import gleam/list
import gleam/option.{None, Option}
import gleam/dynamic.{Dynamic}
import gleam/erlang/process.{Subject}
import glisten/handler.{HandlerMessage}
import sprocket/uuid
import sprocket/hooks.{Hook, HookResult}

pub type IndexTracker {
  IndexTracker(reducer: Int, effect: Int)
}

pub type EventHandler {
  EventHandler(id: String, handler: fn() -> Nil)
}

pub type WebSocket =
  Subject(HandlerMessage)

pub type Updater(r) {
  Updater(send: fn(r) -> Result(Nil, Nil))
}

pub type Socket {
  Socket(
    index_tracker: IndexTracker,
    reducers: List(Dynamic),
    pending_hooks: List(Hook),
    hook_results: Option(List(HookResult)),
    handlers: List(EventHandler),
    ws: Option(WebSocket),
    render_update: fn() -> Nil,
  )
}

pub fn new(ws: Option(WebSocket)) -> Socket {
  Socket(
    index_tracker: IndexTracker(reducer: 0, effect: 0),
    reducers: [],
    pending_hooks: [],
    hook_results: None,
    handlers: [],
    ws: ws,
    render_update: fn() { Nil },
  )
}

pub fn reset_for_render(socket: Socket) {
  Socket(
    ..socket,
    index_tracker: IndexTracker(reducer: 0, effect: 0),
    handlers: [],
    pending_hooks: [],
  )
}

pub fn fetch_or_create_reducer(
  socket: Socket,
  reducer_init: fn() -> Dynamic,
) -> #(Socket, Dynamic) {
  let index = socket.index_tracker.reducer
  case list.at(socket.reducers, index) {
    Ok(reducer) -> {
      // reducer found, return it
      #(
        Socket(
          ..socket,
          index_tracker: IndexTracker(
            ..socket.index_tracker,
            reducer: index + 1,
          ),
        ),
        reducer,
      )
    }
    Error(Nil) -> {
      // reducer doesnt exist, create it
      let reducer = reducer_init()
      let r_reducers = list.reverse(socket.reducers)
      let updated_reducers = list.reverse([reducer, ..r_reducers])

      let index = socket.index_tracker.reducer

      #(
        Socket(
          ..socket,
          reducers: updated_reducers,
          index_tracker: IndexTracker(
            ..socket.index_tracker,
            reducer: index + 1,
          ),
        ),
        reducer,
      )
    }
  }
}

pub fn push_event_handler(
  socket: Socket,
  handler: fn() -> Nil,
) -> #(Socket, String) {
  let assert Ok(id) = uuid.v4()

  #(
    Socket(..socket, handlers: [EventHandler(id, handler), ..socket.handlers]),
    id,
  )
}

pub fn get_event_handler(
  socket: Socket,
  id: String,
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

pub fn push_hook(socket: Socket, hook: Hook) -> Socket {
  Socket(
    ..socket,
    pending_hooks: list.reverse([hook, ..list.reverse(socket.pending_hooks)]),
  )
}
