import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import glisten/handler.{HandlerMessage}
import sprocket/uuid
import sprocket/logger
import sprocket/component.{
  Effect, EffectCleanup, EffectDependencies, EffectTrigger, Element, Hook,
  NoCleanup, OnUpdate, WithDependencies,
}

pub type Socket {
  Socket(
    fetch_or_create_reducer: fn(fn() -> Dynamic) -> Dynamic,
    push_event_handler: fn(fn() -> Nil) -> String,
    request_live_update: fn() -> Nil,
    push_hook: fn(Hook) -> Nil,
  )
}

pub type SocketActor =
  Subject(Message)

// TODO: use a single index for both reducers and effects (hooks)
pub type IndexTracker {
  IndexTracker(reducer: Int, effect: Int)
}

pub type HookResult {
  EmptyResult
  EffectResult(cleanup: EffectCleanup, deps: Option(EffectDependencies))
}

pub type WebSocket =
  Subject(HandlerMessage)

pub type Renderer =
  fn(Element, Socket) -> String

pub type Updater {
  Updater(send: fn(String) -> Result(Nil, Nil))
}

pub type State {
  State(
    index_tracker: IndexTracker,
    reducers: List(Dynamic),
    pending_hooks: List(Hook),
    hook_results: Option(List(HookResult)),
    handlers: List(EventHandler),
    ws: Option(WebSocket),
    render_in_progress: Bool,
    render_waiting: Bool,
    view: Option(Element),
    renderer: Option(Renderer),
    updater: Option(Updater),
  )
}

pub type EventHandler {
  EventHandler(id: String, handler: fn() -> Nil)
}

pub type Message {
  Shutdown
  GetState(reply_with: Subject(State))
  UpdateState(updater: fn(State) -> State)
  ResetRenderContext
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

    UpdateState(updater) -> {
      state
      |> updater()
      |> actor.Continue()
    }

    ResetRenderContext ->
      actor.Continue(
        State(
          ..state,
          index_tracker: IndexTracker(reducer: 0, effect: 0),
          handlers: [],
          pending_hooks: [],
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
  view: Option(Element),
  renderer: Option(Renderer),
  updater: Option(Updater),
) {
  let assert Ok(actor) =
    actor.start(
      State(
        index_tracker: IndexTracker(reducer: 0, effect: 0),
        reducers: [],
        pending_hooks: [],
        hook_results: None,
        handlers: [],
        ws: ws,
        render_in_progress: False,
        render_waiting: False,
        view: view,
        renderer: renderer,
        updater: updater,
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

fn push_render_waiting(actor) {
  update_state(actor, fn(state) { State(..state, render_waiting: True) })
}

fn pop_render_waiting(actor) {
  case get_state(actor) {
    State(render_waiting: True, ..) -> {
      update_state(actor, fn(state) { State(..state, render_waiting: False) })
      True
    }
    _ -> False
  }
}

fn set_render_in_progress(actor, render_in_progress) {
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
      set_render_in_progress(actor, True)
      async_render_update(actor, view, renderer)
      Nil
    }
    _ -> {
      // a render is already in progress, set render_waiting to True
      push_render_waiting(actor)
    }
  }
}

fn async_render_update(
  actor,
  view,
  renderer render: fn(Element, Socket) -> String,
) {
  process.start(
    fn() {
      let body = render(view, get_socket(actor))
      process_pending_hooks(actor)

      // send the rendered update using updater
      get_state(actor).updater
      |> option.map(fn(updater) {
        case updater.send(body) {
          Ok(_) -> Nil
          Error(_) -> {
            logger.error("Failed to send update!")
            Nil
          }
        }
      })

      case pop_render_waiting(actor) {
        True -> {
          async_render_update(actor, view, render)
          Nil
        }
        _ -> {
          set_render_in_progress(actor, False)
        }
      }

      Nil
    },
    False,
  )
}

pub fn get_handler(actor, id) {
  process.call(actor, GetEventHandler(_, id), 100)
}

fn push_hook(actor, hook: Hook) {
  update_state(
    actor,
    fn(state) {
      State(
        ..state,
        pending_hooks: list.reverse([hook, ..list.reverse(state.pending_hooks)]),
      )
    },
  )
}

fn process_pending_hooks(actor) {
  // process.send(actor, ProcessEffects)

  let pending_hooks = get_state(actor).pending_hooks

  // prev_hook_results will be None on the first render cycle
  let prev_hook_results = get_state(actor).hook_results

  let hook_results =
    pending_hooks
    |> list.index_map(fn(i, hook: Hook) {
      let prev_hook_result: Option(HookResult) =
        prev_hook_results
        |> option.then(fn(r) {
          case list.at(r, i) {
            Ok(hook_result) -> Some(hook_result)
            _ -> None
          }
        })

      case hook {
        Effect(effect_fn, trigger) -> {
          // run the effect, returning the effect result
          run_effect(effect_fn, trigger, prev_hook_result)
        }
        _ -> EmptyResult
      }
    })

  update_state(
    actor,
    fn(state) {
      State(..state, pending_hooks: [], hook_results: Some(hook_results))
    },
  )
}

fn run_effect(
  effect_fn: fn() -> EffectCleanup,
  trigger: EffectTrigger,
  prev_hook_result: Option(HookResult),
) -> HookResult {
  case trigger {
    // trigger effect on every update
    OnUpdate -> {
      case prev_hook_result {
        Some(EffectResult(cleanup: cleanup, ..)) ->
          maybe_cleanup_and_rerun_effect(cleanup, effect_fn, None)
        _ -> EffectResult(effect_fn(), None)
      }
    }

    // only trigger the update on the first render and when the dependencies change
    WithDependencies(deps) -> {
      case prev_hook_result {
        Some(EffectResult(cleanup: cleanup, deps: Some(prev_deps))) -> {
          // zip deps together and compare each one with the previous to see if they are equal
          case list.strict_zip(prev_deps, deps) {
            // TODO: this should never occur and should issue a warning/error
            // dependency lists are different sizes, they must have changed
            Error(list.LengthMismatch) ->
              maybe_cleanup_and_rerun_effect(cleanup, effect_fn, Some(deps))

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
                True -> EffectResult(cleanup: cleanup, deps: Some(prev_deps))
                _ ->
                  maybe_cleanup_and_rerun_effect(cleanup, effect_fn, Some(deps))
              }
            }
          }
        }

        _ -> maybe_cleanup_and_rerun_effect(NoCleanup, effect_fn, Some(deps))
      }
    }
    _ -> EmptyResult
  }
}

fn maybe_cleanup_and_rerun_effect(
  cleanup: EffectCleanup,
  effect_fn: fn() -> EffectCleanup,
  deps: Option(EffectDependencies),
) {
  case cleanup {
    EffectCleanup(cleanup_fn) -> {
      cleanup_fn()
      EffectResult(effect_fn(), deps)
    }
    _ -> EffectResult(effect_fn(), deps)
  }
}

pub fn get_socket(actor: SocketActor) {
  // reset for new render cycle
  process.send(actor, ResetRenderContext)

  let fetch_or_create_reducer = fn(reducer) {
    process.call(actor, FetchOrCreateReducer(_, reducer), 100)
  }

  let push_event_handler = fn(handler) {
    process.call(actor, PushEventHandler(_, handler), 100)
  }

  Socket(
    fetch_or_create_reducer: fetch_or_create_reducer,
    push_event_handler: push_event_handler,
    request_live_update: fn() { request_live_update(actor) },
    push_hook: push_hook(actor, _),
  )
}
