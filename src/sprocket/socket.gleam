import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import sprocket/render.{RenderContext}
import glisten/handler.{HandlerMessage}
import sprocket/uuid
import sprocket/component.{Effect, EffectCreated, EffectSpec}

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
  UpdateEffect(effect: Effect)
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
          let assert EffectSpec(effect_fn, deps) = effect
          let assert Ok(id) = uuid.v4()
          let updated_effects =
            list.reverse([Effect(id, effect_fn, deps, None), ..r_effects])

          process.send(reply_with, EffectCreated(id, effect_fn))

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

    UpdateEffect(effect) -> {
      actor.Continue(
        State(
          ..state,
          effects: list.map(
            state.effects,
            fn(e) {
              case e, effect {
                // if the effect id matches, update it to the new effect
                Effect(prev_effect_id, ..), Effect(new_effect_id, ..) if prev_effect_id == new_effect_id ->
                  effect
                _, _ -> e
              }
            },
          ),
        ),
      )
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
  process.call(socket, GetState(_), 100)
}

pub fn get_handler(socket, id) {
  process.call(socket, GetEventHandler(_, id), 100)
}

pub fn render_context(socket: Socket) {
  // reset for new render cycle
  process.send(socket, ResetContext)

  let fetch_or_create_reducer = fn(reducer) {
    process.call(socket, FetchOrCreateReducer(_, reducer), 100)
  }

  let push_event_handler = fn(handler) {
    process.call(socket, PushEventHandler(_, handler), 100)
  }

  let get_or_create_effect = fn(effect) {
    process.call(socket, FetchOrCreateEffect(_, effect), 100)
  }

  let update_effect = fn(effect) { process.send(socket, UpdateEffect(effect)) }

  RenderContext(
    fetch_or_create_reducer: fetch_or_create_reducer,
    push_event_handler: push_event_handler,
    render_update: fn() -> Nil {
      case get_socket(socket) {
        State(live_render_fn: Some(live_render_fn), ..) ->
          live_render_fn(socket)
        _ -> Nil
      }
    },
    get_or_create_effect: get_or_create_effect,
    update_effect: update_effect,
  )
}
