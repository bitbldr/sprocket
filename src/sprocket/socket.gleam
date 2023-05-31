import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/io
import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import glisten/handler.{HandlerMessage}
import sprocket/uuid
import sprocket/component.{
  EffectCleanup, EffectDependencies, EffectSpec, EffectTrigger, Element,
  OnUpdate, WithDependencies,
}
import mist/websocket
import mist/internal/websocket.{TextMessage} as internal_websocket
import gleam/json.{array}

pub type Socket {
  Socket(
    fetch_or_create_reducer: fn(fn() -> Dynamic) -> Dynamic,
    push_event_handler: fn(fn() -> Nil) -> String,
    request_live_update: fn() -> Nil,
    push_effect: fn(EffectSpec) -> Nil,
    set_render_in_progress: fn(Bool) -> Nil,
    push_render_waiting: fn() -> Nil,
    pop_render_waiting: fn() -> Bool,
  )
}

pub type SocketActor =
  Subject(Message)

// TODO: use a single index for both reducers and effects (hooks)
pub type IndexTracker {
  IndexTracker(reducer: Int, effect: Int)
}

pub type WebSocket =
  Subject(HandlerMessage)

pub type PrevEffect {
  PrevEffect(cleanup: EffectCleanup, deps: Option(EffectDependencies))
}

pub type Effect {
  Effect(
    effect_fn: fn() -> EffectCleanup,
    trigger: EffectTrigger,
    cleanup: Option(EffectCleanup),
    prev: Option(PrevEffect),
  )
}

pub type Renderer =
  fn(Element, Socket) -> String

pub type State {
  State(
    index_tracker: IndexTracker,
    reducers: List(Dynamic),
    effects: List(Effect),
    handlers: List(EventHandler),
    ws: Option(WebSocket),
    render_in_progress: Bool,
    render_waiting: Bool,
    view: Option(Element),
    renderer: Option(Renderer),
  )
}

pub type EventHandler {
  EventHandler(id: String, handler: fn() -> Nil)
}

pub type Message {
  Shutdown
  GetState(reply_with: Subject(State))
  UpdateState(updater: fn(State) -> State)
  ResetContext
  FetchOrCreateReducer(
    reply_with: Subject(Dynamic),
    reducer_init: fn() -> Dynamic,
  )
  PushEffect(effect: EffectSpec)
  ProcessEffects
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

    UpdateState(updater) -> {
      state
      |> updater()
      |> actor.Continue()
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

    PushEffect(EffectSpec(effect_fn: effect_fn, trigger: trigger)) -> {
      let index = state.index_tracker.effect

      // find previous effect at this index and set the prev field to it.
      // cleanup will always be None here as we are pushing a new effect and will
      // be set after the effect is run.
      let updated_effects = case list.at(state.effects, index) {
        Ok(prev_effect) -> {
          // TODO: learn how to actually use panic
          // trigger == prev_effect.trigger || panic(
          //   "Effect trigger mismatch! Effect triggers must be consistent across renders.",
          // )

          let prev = case prev_effect {
            Effect(trigger: WithDependencies(deps), cleanup: Some(cleanup), ..) ->
              Some(PrevEffect(cleanup, Some(deps)))
            Effect(cleanup: Some(cleanup), ..) ->
              Some(PrevEffect(cleanup, None))
            _ -> None
          }

          let effect =
            Effect(
              effect_fn: effect_fn,
              trigger: trigger,
              cleanup: None,
              prev: prev,
            )

          list.index_map(
            state.effects,
            fn(i, e) {
              case i == index {
                True -> effect
                _ -> e
              }
            },
          )
        }

        _ -> {
          // theres no existing effect at this index, create a new one
          // this should only occur on the first render
          let effect =
            Effect(
              effect_fn: effect_fn,
              trigger: trigger,
              cleanup: None,
              prev: None,
            )

          list.reverse([effect, ..list.reverse(state.effects)])
        }
      }

      io.debug("updated_effects")
      io.debug(updated_effects)

      actor.Continue(
        State(
          ..state,
          effects: updated_effects,
          index_tracker: IndexTracker(..state.index_tracker, effect: index + 1),
        ),
      )
    }

    ProcessEffects -> {
      let effects =
        list.map(
          state.effects,
          fn(effect) {
            let Effect(trigger: trigger, prev: prev, ..) = effect

            case trigger {
              // trigger effect on every update
              OnUpdate -> run_effect(effect)
              // only trigger the update on the first render and when the dependencies change
              WithDependencies(deps) -> {
                case prev {
                  Some(PrevEffect(deps: Some(prev_deps), ..)) -> {
                    // zip deps together and compare each one with the previous to see if they are equal
                    case list.strict_zip(prev_deps, deps) {
                      Error(list.LengthMismatch) -> run_effect(effect)
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
                          True -> effect
                          _ -> run_effect(effect)
                        }
                      }
                    }
                  }

                  _ -> run_effect(effect)
                }
              }
              _ -> effect
            }
          },
        )

      actor.Continue(State(..state, effects: effects))
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

pub fn start(
  ws: Option(WebSocket),
  liveview: Option(Element),
  live_renderer: Option(Renderer),
) {
  let assert Ok(actor) =
    actor.start(
      State(
        index_tracker: IndexTracker(reducer: 0, effect: 0),
        reducers: [],
        effects: [],
        handlers: [],
        ws: ws,
        render_in_progress: False,
        render_waiting: False,
        view: liveview,
        renderer: live_renderer,
      ),
      handle_message,
    )

  actor
}

pub fn stop(actor) {
  process.send(actor, Shutdown)
}

fn get_state(actor) {
  process.call(actor, GetState(_), 100)
}

fn update_state(actor, updater: fn(State) -> State) {
  process.send(actor, UpdateState(updater))
}

pub fn matches_websocket(actor, websocket) {
  case get_state(actor) {
    State(ws: Some(ws), ..) -> ws == websocket
    _ -> False
  }
}

pub fn push_render_waiting(actor) {
  update_state(actor, fn(state) { State(..state, render_waiting: True) })
}

pub fn pop_render_waiting(actor) {
  case get_state(actor) {
    State(render_waiting: True, ..) -> {
      update_state(actor, fn(state) { State(..state, render_waiting: False) })
      True
    }
    _ -> False
  }
}

pub fn set_render_in_progress(actor, render_in_progress) {
  update_state(
    actor,
    fn(state) { State(..state, render_in_progress: render_in_progress) },
  )
}

pub fn request_live_update(actor) {
  case get_state(actor) {
    State(
      render_in_progress: False,
      view: Some(view),
      renderer: Some(renderer),
      ..,
    ) -> {
      // no update in progress, kick off an update immediately
      async_render_update(actor, view, renderer)
      Nil
    }
    _ -> {
      // a render is already in progress, set render_waiting to True
      update_state(actor, fn(state) { State(..state, render_waiting: True) })
    }
  }
}

fn update_to_json(html: String) -> String {
  array(["update", html], of: json.string)
  |> json.to_string
}

fn process_effects(actor) {
  process.send(actor, ProcessEffects)
}

fn async_render_update(
  actor,
  view,
  renderer render: fn(Element, Socket) -> String,
) {
  process.start(
    fn() {
      set_render_in_progress(actor, True)
      let body = render(view, get_socket(actor))

      process_effects(actor)

      case get_state(actor).ws {
        Some(ws) -> {
          let _ = websocket.send(ws, TextMessage(update_to_json(body)))
        }
        _ -> Nil
      }

      case get_state(actor).render_waiting {
        True -> {
          async_render_update(actor, view, render)
          Nil
        }
        _ -> Nil
      }

      set_render_in_progress(actor, False)

      Nil
    },
    False,
  )
}

pub fn get_handler(actor, id) {
  process.call(actor, GetEventHandler(_, id), 100)
}

fn run_effect(effect) {
  let Effect(effect_fn, prev: prev, ..) = effect

  // run the previous effect's cleanup function if it exists
  prev
  |> option.map(fn(prev_effect) {
    let PrevEffect(cleanup: cleanup, deps: deps) = prev_effect

    case cleanup {
      EffectCleanup(cleanup_fn) -> cleanup_fn()
      _ -> Nil
    }
  })

  // run the effect, capture the cleanup function
  let cleanup = effect_fn()

  // update the effect with the cleanup function
  Effect(..effect, cleanup: Some(cleanup))
}

pub fn get_socket(actor: SocketActor) {
  // reset for new render cycle
  process.send(actor, ResetContext)

  let fetch_or_create_reducer = fn(reducer) {
    process.call(actor, FetchOrCreateReducer(_, reducer), 100)
  }

  let push_event_handler = fn(handler) {
    process.call(actor, PushEventHandler(_, handler), 100)
  }

  let push_effect = fn(effect) { process.send(actor, PushEffect(effect)) }

  Socket(
    fetch_or_create_reducer: fetch_or_create_reducer,
    push_event_handler: push_event_handler,
    request_live_update: fn() { request_live_update(actor) },
    push_effect: push_effect,
    set_render_in_progress: fn(render_in_progress) {
      set_render_in_progress(actor, render_in_progress)
    },
    push_render_waiting: fn() { push_render_waiting(actor) },
    pop_render_waiting: fn() { pop_render_waiting(actor) },
  )
}
