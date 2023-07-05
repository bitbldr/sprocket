import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import sprocket/logger
import sprocket/element.{Element}
import sprocket/socket.{EventHandler, Socket, Updater, WebSocket}
import sprocket/hooks.{
  Changed, Effect, EffectCleanup, EffectResult, Hook, HookDependencies,
  HookTrigger, OnUpdate, Unchanged, WithDeps, compare_deps,
}
import sprocket/render.{RenderResult, RenderedElement, live_render}
import sprocket/patch.{Patch}
import sprocket/ordered_map.{KeyedItem, OrderedMapIter}
import sprocket/exception.{throw_on_unexpected_hook_result}

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

    SetRenderUpdate(render_update) -> {
      actor.Continue(
        State(
          ..state,
          socket: Socket(..state.socket, render_update: render_update),
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

      // for now, only effects are processed during this phase
      let updated = case hook {
        Effect(effect_fn, trigger, prev) -> {
          let result = handle_effect(effect_fn, trigger, prev)

          Effect(effect_fn, trigger, Some(result))
        }
        other -> other
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
