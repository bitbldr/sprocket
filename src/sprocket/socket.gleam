import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import sprocket/render.{RenderContext}
import glisten/handler.{HandlerMessage}
import sprocket/uuid
import sprocket/component.{Effect, NewEffect}

pub type Socket =
  Subject(Message)

pub type IndexTracker {
  IndexTracker(reducer: Int, effect: Int)
}

pub type WebSocket =
  Subject(HandlerMessage)

pub type State {
  State(
    index_tracker: IndexTracker,
    reducers: List(Dynamic),
    effects: List(Effect),
    handlers: List(EventHandler),
    ws: Option(WebSocket),
    live_render_fn: Option(fn(Socket) -> Nil),
  )
}

pub type EventHandler {
  EventHandler(id: String, handler: fn() -> Nil)
}

pub type Message {
  Shutdown
  GetState(reply_with: Subject(State))
  ResetContext
  FetchOrCreateReducer(
    reply_with: Subject(Dynamic),
    reducer_init: fn() -> Dynamic,
  )
  FetchOrCreateEffect(reply_with: Subject(Effect), effect: Effect)
  PushEventHandler(reply_with: Subject(String), handler: fn() -> Nil)
  GetEventHandler(reply_with: Subject(Result(EventHandler, Nil)), id: String)
}

fn handle_message(message: Message, state: State) -> actor.Next(State) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    GetState(reply_with) -> {
      process.send(reply_with, state)

      actor.Continue(state)
    }

    ResetContext ->
      actor.Continue(
        State(
          ..state,
          index_tracker: IndexTracker(reducer: 0, effect: 0),
          handlers: [],
        ),
      )

    FetchOrCreateReducer(reply_with, reducer_init) -> {
      let index = state.index_tracker.reducer
      case list.at(state.reducers, index) {
        Ok(r) -> {
          // reducer found, return it
          process.send(reply_with, r)
          actor.Continue(
            State(
              ..state,
              index_tracker: IndexTracker(
                ..state.index_tracker,
                reducer: index + 1,
              ),
            ),
          )
        }
        Error(Nil) -> {
          // reducer doesnt exist, create it
          let reducer = reducer_init()
          let r_reducers = list.reverse(state.reducers)
          let updated_reducers = list.reverse([reducer, ..r_reducers])

          process.send(reply_with, reducer)

          let index = state.index_tracker.reducer

          actor.Continue(
            State(
              ..state,
              reducers: updated_reducers,
              index_tracker: IndexTracker(
                ..state.index_tracker,
                reducer: index + 1,
              ),
            ),
          )
        }
      }
    }

    FetchOrCreateEffect(reply_with, effect) -> {
      let index = state.index_tracker.effect

      case list.at(state.effects, index) {
        Ok(r) -> {
          // effect found, return it
          process.send(reply_with, r)
          actor.Continue(
            State(
              ..state,
              index_tracker: IndexTracker(
                ..state.index_tracker,
                effect: index + 1,
              ),
            ),
          )
        }
        Error(Nil) -> {
          // effect doesnt exist, create it
          let r_effects = list.reverse(state.effects)
          let updated_effects = list.reverse([effect, ..r_effects])

          process.send(reply_with, NewEffect(effect.deps))

          actor.Continue(
            State(
              ..state,
              effects: updated_effects,
              index_tracker: IndexTracker(
                ..state.index_tracker,
                effect: index + 1,
              ),
            ),
          )
        }
      }
    }

    PushEventHandler(reply_with, handler) -> {
      let assert Ok(id) = uuid.v4()

      process.send(reply_with, id)

      actor.Continue(
        State(..state, handlers: [EventHandler(id, handler), ..state.handlers]),
      )
    }

    GetEventHandler(reply_with, id) -> {
      let handler =
        list.find(
          state.handlers,
          fn(h) {
            let EventHandler(i, _) = h
            i == id
          },
        )

      process.send(reply_with, handler)

      actor.Continue(state)
    }
  }
}

pub fn start(ws: Option(WebSocket), live_render_fn) {
  let assert Ok(socket) =
    actor.start(
      State(
        index_tracker: IndexTracker(reducer: 0, effect: 0),
        reducers: [],
        effects: [],
        handlers: [],
        ws: ws,
        live_render_fn: live_render_fn,
      ),
      handle_message,
    )

  socket
}

pub fn stop(socket) {
  process.send(socket, Shutdown)
}

pub fn get_socket(socket) {
  process.call(socket, GetState(_), 10)
}

pub fn get_handler(socket, id) {
  process.call(socket, GetEventHandler(_, id), 10)
}

pub fn render_context(socket: Socket) {
  // reset for new render cycle
  process.send(socket, ResetContext)

  let fetch_or_create_reducer = fn(reducer) {
    process.call(socket, FetchOrCreateReducer(_, reducer), 10)
  }

  let push_event_handler = fn(handler) {
    process.call(socket, PushEventHandler(_, handler), 10)
  }

  let get_or_create_effect = fn(effect) {
    process.call(socket, FetchOrCreateEffect(_, effect), 10)
  }

  RenderContext(
    fetch_or_create_reducer: fetch_or_create_reducer,
    push_event_handler: push_event_handler,
    render_update: fn() -> Nil {
      case get_socket(socket).live_render_fn {
        Some(f) -> f(socket)
        None -> Nil
      }
    },
    get_or_create_effect: get_or_create_effect,
  )
}
