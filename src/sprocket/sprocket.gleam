import gleam/io
import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import sprocket/logger
import sprocket/element.{Element}
import sprocket/socket.{EventHandler, Socket, Updater, WebSocket}
import sprocket/hooks.{
  Callback, CallbackResult, Effect, EffectCleanup, EffectResult, Hook,
  HookDependencies, HookTrigger, OnUpdate, Reducer, WithDeps,
}
import sprocket/render.{RenderResult, RenderedElement, live_render}
import sprocket/patch.{Patch}
import sprocket/ordered_map.{KeyedItem, OrderedMapIter}

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
  // SetAsyncCallbackDispatch(fn() -> Nil)
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

    SetRenderUpdate(render_update) -> {
      actor.Continue(
        State(
          ..state,
          socket: Socket(..state.socket, render_update: render_update),
        ),
      )
    }

    // SetAsyncCallbackDispatch(async_callback_dispatch) -> {
    //   actor.Continue(
    //     State(
    //       ..state,
    //       socket: Socket(
    //         ..state.socket,
    //         async_callback_dispatch: async_callback_dispatch,
    //       ),
    //     ),
    //   )
    // }
    // AsyncCallbackDispatch(id: String) -> {
    // }
    RenderImmediate(reply_with) -> {
      let state = case state {
        State(socket: socket, view: Some(view), ..) -> {
          let RenderResult(socket, rendered) =
            socket
            |> socket.reset_for_render
            |> live_render(view)

          actor.send(reply_with, rendered)

          process_hooks(
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
          process_hooks(
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
  // actor.send(
  //   actor,
  //   SetAsyncCallbackDispatch(fn() {
  //     actor.send(actor, AsyncCallbackDispatch)
  //   }),
  // )

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

fn process_hooks(state: State) -> State {
  let #(r_ordered, by_index, size) =
    state.socket.hooks
    |> ordered_map.iter()
    |> process_next_hook(#([], map.new(), 0))

  State(
    ..state,
    socket: Socket(
      ..state.socket,
      hooks: ordered_map.from(list.reverse(r_ordered), by_index, size),
    ),
  )
}

fn process_next_hook(
  iter: OrderedMapIter(Int, Hook),
  acc: #(List(KeyedItem(Int, Hook)), Map(Int, Hook), Int),
) -> #(List(KeyedItem(Int, Hook)), Map(Int, Hook), Int) {
  case ordered_map.next(iter) {
    Ok(#(iter, KeyedItem(index, hook))) -> {
      let #(ordered, by_index, size) = acc

      let updated = case hook {
        Callback(callback_fn, trigger, prev) -> {
          let result = handle_callback(callback_fn, trigger, prev)
          Callback(callback_fn, trigger, Some(result))
        }
        Effect(effect_fn, trigger, prev) -> {
          let result = handle_effect(effect_fn, trigger, prev)

          Effect(effect_fn, trigger, Some(result))
        }
        Reducer(reducer: reducer) -> {
          Reducer(reducer)
        }
      }

      process_next_hook(
        iter,
        #(
          [KeyedItem(index, updated), ..ordered],
          map.insert(by_index, index, updated),
          size + 1,
        ),
      )
    }
    Error(_) -> acc
  }
}

fn handle_effect(
  effect_fn: fn() -> EffectCleanup,
  trigger: HookTrigger,
  prev: Option(EffectResult),
) -> EffectResult {
  case trigger {
    // trigger effect on every update
    OnUpdate -> {
      case prev {
        Some(EffectResult(cleanup: cleanup, ..)) ->
          maybe_cleanup_and_rerun_effect(cleanup, effect_fn, None)
        _ -> EffectResult(effect_fn(), None)
      }
    }

    // only trigger the update on the first render and when the dependencies change
    WithDeps(deps) -> {
      case prev {
        Some(EffectResult(cleanup, Some(prev_deps))) -> {
          case compare_deps(prev_deps, deps) {
            Changed(_) ->
              maybe_cleanup_and_rerun_effect(cleanup, effect_fn, Some(deps))
            Unchanged -> EffectResult(cleanup, Some(deps))
          }
        }

        None -> maybe_cleanup_and_rerun_effect(None, effect_fn, Some(deps))

        _ -> {
          // this should never occur and means that a hook was dynamically added
          throw_on_unexpected_hook_result(#("handle_effect", prev))
        }
      }
    }
  }
}

fn maybe_cleanup_and_rerun_effect(
  cleanup: EffectCleanup,
  effect_fn: fn() -> EffectCleanup,
  deps: Option(HookDependencies),
) {
  case cleanup {
    Some(cleanup_fn) -> {
      cleanup_fn()
      EffectResult(effect_fn(), deps)
    }
    _ -> EffectResult(effect_fn(), deps)
  }
}

fn handle_callback(
  callback_fn: fn() -> Nil,
  trigger: HookTrigger,
  prev: Option(CallbackResult),
) -> CallbackResult {
  case trigger {
    // recompute callback on every update
    OnUpdate -> {
      replace_callback(callback_fn, None)
    }

    // only compute callback on the first render and when the dependencies change
    WithDeps(deps) -> {
      case prev {
        Some(
          CallbackResult(callback: _, deps: Some(prev_deps)) as prev_callback_result,
        ) -> {
          case compare_deps(prev_deps, deps) {
            Changed(_) -> replace_callback(callback_fn, Some(deps))
            Unchanged -> prev_callback_result
          }
        }

        Some(prev_callback_result) -> prev_callback_result

        None -> replace_callback(callback_fn, Some(deps))

        _ -> {
          // this should never occur and means that a hook was dynamically added
          throw_on_unexpected_hook_result(#("handle_callback", prev))
        }
      }
    }
  }
}

fn replace_callback(
  callback_fn: fn() -> Nil,
  deps: Option(HookDependencies),
) -> CallbackResult {
  CallbackResult(callback_fn, deps)
}

pub type Compared(a) {
  Changed(changed: a)
  Unchanged
}

pub fn compare_deps(
  prev_deps: HookDependencies,
  deps: HookDependencies,
) -> Compared(HookDependencies) {
  // zip deps together and compare each one with the previous to see if they are equal
  case list.strict_zip(prev_deps, deps) {
    Error(list.LengthMismatch) ->
      // Dependency lists are different sizes, so they must have changed
      // this should never occur and means that a hook's deps list was dynamically changed
      throw_on_unexpected_deps_mismatch(#("compare_deps", prev_deps, deps))

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
        True -> Unchanged
        _ -> Changed(deps)
      }
    }
  }
}

fn throw_on_unexpected_hook_result(meta: any) {
  logger.error(
    "
    An unexpected hook result was encountered. This means that a hook was dynamically added
    after the initial render. This is not supported and will result in undefined behavior.
    ",
  )

  io.debug(meta)

  // TODO: we probably want to try and handle this more gracefully in production configurations
  panic
}

fn throw_on_unexpected_deps_mismatch(meta: any) {
  logger.error(
    "
    An unexpected change in hook dependencies was encountered. This means that the list of hook
    dependencies dynamically changed after the initial render. This is not supported and will 
    result in undefined behavior.
    ",
  )

  io.debug(meta)

  // TODO: we probably want to try and handle this more gracefully in production configurations
  panic
}
