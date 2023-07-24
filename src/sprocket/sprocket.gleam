import gleam/list
import gleam/map.{Map}
import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/option.{None, Option, Some}
import sprocket/internal/logger
import sprocket/element.{Element}
import sprocket/context.{
  ComponentHooks, Context, EventHandler, Updater, WebSocket,
}
import sprocket/hooks.{
  Callback, Changed, Effect, EffectCleanup, EffectResult, Hook, HookDependencies,
  HookTrigger, OnMount, OnUpdate, Reducer, Unchanged, WithDeps, compare_deps,
}
import sprocket/render.{
  RenderResult, RenderedComponent, RenderedElement, live_render,
}
import sprocket/internal/patch.{Patch}
import sprocket/internal/utils/ordered_map.{KeyedItem, OrderedMapIter}
import sprocket/internal/utils/unique.{Unique}
import sprocket/internal/exceptions.{throw_on_unexpected_hook_result}

pub type Sprocket =
  Subject(Message)

type State {
  State(
    ctx: Context,
    view: Option(Element),
    updater: Option(Updater(Patch)),
    rendered: Option(RenderedElement),
  )
}

pub type Message {
  Shutdown
  GetRendered(reply_with: Subject(Option(RenderedElement)))
  HasWebSocket(reply_with: Subject(Bool), websocket: WebSocket)
  SetRenderUpdate(fn() -> Nil)
  Render(reply_with: Subject(RenderedElement))
  RenderUpdate
  SetUpdateHook(fn(Unique, fn(Hook) -> Hook) -> Nil)
  UpdateHook(Unique, fn(Hook) -> Hook)
  GetEventHandler(reply_with: Subject(Result(EventHandler, Nil)), id: Unique)
}

fn handle_message(message: Message, state: State) -> actor.Next(State) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    GetRendered(reply_with) -> {
      actor.send(reply_with, state.rendered)

      actor.Continue(state)
    }

    HasWebSocket(reply_with, websocket) -> {
      case state.ctx {
        Context(ws: Some(ws), ..) -> {
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
        State(..state, ctx: Context(..state.ctx, render_update: render_update)),
      )
    }

    Render(reply_with) -> {
      let state = case state {
        State(ctx: ctx, view: Some(view), rendered: prev_rendered, ..) -> {
          let RenderResult(ctx, rendered) =
            ctx
            |> context.reset_for_render
            |> live_render(view, None, prev_rendered)

          actor.send(reply_with, rendered)

          case prev_rendered {
            Some(prev_rendered) ->
              cleanup_disposed_hooks(prev_rendered, rendered)
            _ -> Nil
          }

          run_effects(State(..state, ctx: ctx, rendered: Some(rendered)))
        }
        _ -> {
          logger.error("No renderer found!")
          state
        }
      }

      actor.Continue(state)
    }

    RenderUpdate -> {
      case state {
        State(view: None, ..) -> {
          logger.error("No view found! A view must be provided to render.")

          actor.Continue(state)
        }

        State(updater: None, ..) -> {
          logger.error(
            "No updater found! An updater must be provided to send updates to the client.",
          )

          actor.Continue(state)
        }

        State(rendered: None, ..) -> {
          logger.error(
            "No previous render found! View must be rendered at least once before updates can be sent.",
          )

          actor.Continue(state)
        }

        State(
          ctx: ctx,
          view: Some(view),
          updater: Some(updater),
          rendered: Some(prev_rendered),
        ) -> {
          let RenderResult(ctx, rendered) =
            ctx
            |> context.reset_for_render
            |> live_render(view, None, Some(prev_rendered))

          let update = patch.create(prev_rendered, rendered)

          // send the rendered update using updater
          case updater.send(update) {
            Ok(_) -> Nil
            Error(_) -> {
              logger.error("Failed to send update patch!")
              Nil
            }
          }

          cleanup_disposed_hooks(prev_rendered, rendered)

          // hooks might contain effects that will trigger a rerender. That is okay because any
          // RenderUpdate messages sent during this operation will be placed into this actor's mailbox
          // and will be processed in order after this current render is complete
          let state =
            run_effects(State(..state, ctx: ctx, rendered: Some(rendered)))

          actor.Continue(state)
        }
      }
    }

    SetUpdateHook(update_hook) -> {
      actor.Continue(
        State(..state, ctx: Context(..state.ctx, update_hook: update_hook)),
      )
    }

    UpdateHook(id, updater) -> {
      actor.Continue(update_hook_state(state, id, updater))
    }

    GetEventHandler(reply_with, id) -> {
      let handler =
        list.find(
          state.ctx.handlers,
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

/// Start a new sprocket actor
pub fn start(
  ws: Option(WebSocket),
  view: Option(Element),
  updater: Option(Updater(Patch)),
) {
  let assert Ok(actor) =
    actor.start(
      State(ctx: context.new(ws), view: view, updater: updater, rendered: None),
      handle_message,
    )

  actor.send(actor, SetRenderUpdate(fn() { actor.send(actor, RenderUpdate) }))
  actor.send(
    actor,
    SetUpdateHook(fn(id, updater) { actor.send(actor, UpdateHook(id, updater)) }),
  )

  actor
}

/// Stop a sprocket actor
pub fn stop(actor) {
  actor.send(actor, Shutdown)
}

/// Returns true if the actor matches a given websocket connection
pub fn has_websocket(actor, websocket) -> Bool {
  actor.call(actor, HasWebSocket(_, websocket), 100)
}

/// Get the previously rendered view from the actor
pub fn get_rendered(actor) {
  actor.call(actor, GetRendered(_), 100)
}

/// Get the event handler for a given id
pub fn get_handler(actor, id: String) {
  actor.call(actor, GetEventHandler(_, unique.from_string(id)), 100)
}

/// Render the view
pub fn render(actor) -> RenderedElement {
  actor.call(actor, Render(_), 100)
}

/// Render the view and send an update Patch to the updater
pub fn render_update(actor) -> Nil {
  actor.send(actor, RenderUpdate)
}

fn cleanup_disposed_hooks(
  prev_rendered: RenderedElement,
  rendered: RenderedElement,
) {
  let prev_hooks = build_hooks_map(prev_rendered, map.new())
  let new_hooks = build_hooks_map(rendered, map.new())

  let removed_hooks =
    prev_hooks
    |> map.keys()
    |> list.filter(fn(id) { !map.has_key(new_hooks, id) })

  // cleanup removed hooks
  removed_hooks
  |> list.each(fn(id) {
    case map.get(prev_hooks, id) {
      Ok(Effect(_, _, _, prev)) -> {
        case prev {
          Some(EffectResult(Some(cleanup), _)) -> cleanup()
          _ -> Nil
        }
      }

      Ok(Reducer(_, _, cleanup)) -> cleanup()

      _ -> Nil
    }
  })
}

fn build_hooks_map(
  node: RenderedElement,
  acc: Map(Unique, Hook),
) -> Map(Unique, Hook) {
  case node {
    RenderedComponent(_fc, _key, _props, hooks, children) -> {
      // add hooks from this node
      let acc =
        ordered_map.fold(
          hooks,
          acc,
          fn(acc, hook) {
            let KeyedItem(_, hook) = hook
            case hook {
              Callback(id, _, _, _) -> {
                map.insert(acc, id, hook)
              }
              Effect(id, _, _, _) -> {
                map.insert(acc, id, hook)
              }
              Reducer(id, _, _) -> {
                map.insert(acc, id, hook)
              }
              hooks.State(id, _) -> {
                map.insert(acc, id, hook)
              }
            }
          },
        )

      // add hooks from children
      list.fold(
        children,
        acc,
        fn(acc, child) { map.merge(acc, build_hooks_map(child, acc)) },
      )
    }
    RenderedElement(_tag, _key, _hooks, children) -> {
      // add hooks from children
      list.fold(
        children,
        acc,
        fn(acc, child) { map.merge(acc, build_hooks_map(child, acc)) },
      )
    }
    _ -> acc
  }
}

fn run_effects(state: State) {
  process_state_hooks(
    state,
    fn(hook) {
      case hook {
        Effect(id, effect_fn, trigger, prev) -> {
          let result = run_effect(effect_fn, trigger, prev)

          Effect(id, effect_fn, trigger, Some(result))
        }
        other -> other
      }
    },
  )
}

fn run_effect(
  effect_fn: fn() -> EffectCleanup,
  trigger: HookTrigger,
  prev: Option(EffectResult),
) -> EffectResult {
  case trigger {
    // Only compute callback on the first render. This is a convience that is equivalent to WithDeps([]).
    OnMount -> {
      case prev {
        Some(prev_effect_result) -> {
          prev_effect_result
        }

        None -> EffectResult(effect_fn(), Some([]))

        _ -> {
          // this should never occur and means that a hook was dynamically added
          throw_on_unexpected_hook_result(#("handle_effect", prev))
        }
      }
    }

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

type HookProcessor =
  fn(Hook) -> Hook

// traverse the rendered tree and process all hooks using the given function
fn process_state_hooks(state: State, process_hook: HookProcessor) -> State {
  let rendered =
    option.map(
      state.rendered,
      fn(node) { traverse_rendered_hooks(node, process_hook) },
    )

  State(..state, rendered: rendered)
}

fn traverse_rendered_hooks(node: RenderedElement, process_hook: HookProcessor) {
  case node {
    RenderedComponent(fc, key, props, hooks, children) -> {
      let processed_hooks = process_hooks(hooks, process_hook)

      let r_children =
        list.fold(
          children,
          [],
          fn(acc, child) {
            [traverse_rendered_hooks(child, process_hook), ..acc]
          },
        )

      RenderedComponent(
        fc,
        key,
        props,
        processed_hooks,
        list.reverse(r_children),
      )
    }
    RenderedElement(tag, key, hooks, children) -> {
      let r_children =
        list.fold(
          children,
          [],
          fn(acc, child) {
            [traverse_rendered_hooks(child, process_hook), ..acc]
          },
        )

      RenderedElement(tag, key, hooks, list.reverse(r_children))
    }
    _ -> node
  }
}

fn process_hooks(
  hooks: ComponentHooks,
  process_hook: HookProcessor,
) -> ComponentHooks {
  let #(r_ordered, by_index, size) =
    hooks
    |> ordered_map.iter()
    |> process_next_hook(#([], map.new(), 0), process_hook)

  ordered_map.from(list.reverse(r_ordered), by_index, size)
}

fn process_next_hook(
  iter: OrderedMapIter(Int, Hook),
  acc: #(List(KeyedItem(Int, Hook)), Map(Int, Hook), Int),
  process_hook: HookProcessor,
) -> #(List(KeyedItem(Int, Hook)), Map(Int, Hook), Int) {
  case ordered_map.next(iter) {
    Ok(#(iter, KeyedItem(index, hook))) -> {
      let #(ordered, by_index, size) = acc

      // for now, only effects are processed during this phase
      let updated = process_hook(hook)

      process_next_hook(
        iter,
        #(
          [KeyedItem(index, updated), ..ordered],
          map.insert(by_index, index, updated),
          size + 1,
        ),
        process_hook,
      )
    }
    Error(_) -> acc
  }
}

fn update_hook_state(
  state: State,
  hook_id: Unique,
  update: fn(Hook) -> Hook,
) -> State {
  let rendered =
    option.map(
      state.rendered,
      fn(node) {
        traverse_rendered_hooks(
          node,
          fn(hook) {
            case hook {
              // this operation is only applicable to State hooks
              hooks.State(id, _) -> {
                case id == hook_id {
                  True -> update(hook)
                  False -> hook
                }
              }
              _ -> hook
            }
          },
        )
      },
    )

  State(..state, rendered: rendered)
}
