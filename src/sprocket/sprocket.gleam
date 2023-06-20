import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/option.{None, Option, Some}
import sprocket/logger
import sprocket/socket.{
  Effect, EffectCleanup, EffectDependencies, EffectResult, EffectTrigger,
  Element, EmptyResult, EventHandler, Hook, HookResult, OnUpdate, Socket,
  Updater, WebSocket, WithDependencies,
}
import sprocket/render.{RenderResult, RenderedElement, live_render}
import sprocket/patch.{Patch}

pub type Sprocket =
  Subject(Message)

type State {
  State(
    socket: Socket,
    view: Option(Element),
    updater: Option(Updater(Patch)),
    rendered: Option(RenderedElement),
  )
}

pub type Message {
  Shutdown
  HasWebSocket(reply_with: Subject(Bool), websocket: WebSocket)
  SetRenderUpdate(fn() -> Nil)
  RenderImmediate(reply_with: Subject(RenderedElement))
  RenderUpdate
  GetEventHandler(reply_with: Subject(Result(EventHandler, Nil)), id: String)
}

fn handle_message(message: Message, state: State) -> actor.Next(State) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    HasWebSocket(reply_with, websocket) -> {
      case state.socket {
        Socket(ws: Some(ws), ..) -> {
          actor.send(reply_with, ws == websocket)
        }
        _ -> {
          actor.send(reply_with, False)
        }
      }

      actor.Continue(state)
    }

    SetRenderUpdate(render_update_fn) -> {
      actor.Continue(
        State(
          ..state,
          socket: Socket(..state.socket, render_update: render_update_fn),
        ),
      )
    }

    RenderImmediate(reply_with) -> {
      let state = case state {
        State(socket: socket, view: Some(view), ..) -> {
          let RenderResult(socket, rendered) =
            socket
            |> socket.reset_for_render
            |> live_render(view)

          actor.send(reply_with, rendered)

          process_pending_hooks(
            State(..state, socket: socket, rendered: Some(rendered)),
          )
        }
        _ -> {
          logger.error("No renderer found!")
          state
        }
      }

      actor.Continue(state)
    }

    RenderUpdate -> {
      let state = case state {
        State(
          socket: socket,
          view: Some(view),
          updater: Some(updater),
          rendered: Some(prev_rendered),
        ) -> {
          let RenderResult(socket, rendered) =
            socket
            |> socket.reset_for_render
            |> live_render(view)

          let update = patch.create(prev_rendered, rendered)

          // send the rendered update using updater
          case updater.send(update) {
            Ok(_) -> Nil
            Error(_) -> {
              logger.error("Failed to send update patch!")
              Nil
            }
          }

          // hooks might contain effects that will trigger a rerender. That is okay because any
          // RenderUpdate messages sent during this operation will be placed into this actor's mailbox
          // and will be processed in order after this current render is complete
          process_pending_hooks(
            State(..state, socket: socket, rendered: Some(rendered)),
          )
        }
        _ -> {
          case state {
            State(view: None, ..) ->
              logger.error("No view found! A view must be provided to render.")
            State(updater: None, ..) ->
              logger.error(
                "No updater found! An updater must be provided to send updates to the client.",
              )
            State(rendered: None, ..) ->
              logger.error(
                "No previous render found! View must be rendered at least once before updates can be sent.",
              )
          }

          state
        }
      }

      actor.Continue(state)
    }

    GetEventHandler(reply_with, id) -> {
      let handler =
        list.find(
          state.socket.handlers,
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
  updater: Option(Updater(Patch)),
) {
  let assert Ok(actor) =
    actor.start(
      State(
        socket: socket.new(ws),
        view: view,
        updater: updater,
        rendered: None,
      ),
      handle_message,
    )

  actor.send(actor, SetRenderUpdate(fn() { actor.send(actor, RenderUpdate) }))

  actor
}

pub fn stop(actor) {
  actor.send(actor, Shutdown)
}

pub fn has_websocket(actor, websocket) -> Bool {
  actor.call(actor, HasWebSocket(_, websocket), 100)
}

pub fn get_handler(actor, id) {
  actor.call(actor, GetEventHandler(_, id), 100)
}

pub fn render(actor) -> RenderedElement {
  actor.call(actor, RenderImmediate(_), 100)
}

pub fn render_update(actor) -> Nil {
  actor.send(actor, RenderUpdate)
}

fn process_pending_hooks(state: State) -> State {
  let pending_hooks = state.socket.pending_hooks

  // prev_hook_results will be None on the first render cycle
  let prev_hook_results = state.socket.hook_results

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

  State(
    ..state,
    socket: Socket(
      ..state.socket,
      pending_hooks: [],
      hook_results: Some(hook_results),
    ),
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

        _ -> maybe_cleanup_and_rerun_effect(None, effect_fn, Some(deps))
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
    Some(cleanup_fn) -> {
      cleanup_fn()
      EffectResult(effect_fn(), deps)
    }
    _ -> EffectResult(effect_fn(), deps)
  }
}
