import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import sprocket/render.{RenderContext}
import glisten/handler.{HandlerMessage}
import sprocket/uuid

pub type Socket =
  Subject(Message)

pub type WebSocket =
  Subject(HandlerMessage)

pub type State {
  State(
    r_index: Int,
    reducers: List(Dynamic),
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

    ResetContext -> actor.Continue(State(..state, r_index: 0, handlers: []))

    FetchOrCreateReducer(reply_with, reducer_init) -> {
      case list.at(state.reducers, state.r_index) {
        Ok(r) -> {
          // reducer found, return it
          process.send(reply_with, r)
          actor.Continue(State(..state, r_index: state.r_index + 1))
        }
        Error(Nil) -> {
          // reducer doesnt exist, create it
          let reducer = reducer_init()
          let r_reducers = list.reverse(state.reducers)
          let updated_reducers = list.reverse([reducer, ..r_reducers])

          process.send(reply_with, reducer)

          actor.Continue(
            State(
              ..state,
              reducers: updated_reducers,
              r_index: state.r_index + 1,
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
        r_index: 0,
        reducers: [],
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

  RenderContext(
    fetch_or_create_reducer: fetch_or_create_reducer,
    push_event_handler: push_event_handler,
    render_update: fn() -> Nil {
      case get_socket(socket).live_render_fn {
        Some(f) -> f(socket)
        None -> Nil
      }
    },
  )
}
