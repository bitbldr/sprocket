import gleam/io
import gleam/list
import gleam/map.{type Map}
import gleam/function.{identity}
import gleam/otp/actor.{type StartError, Spec}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import ids/cuid
import sprocket/internal/logger
import sprocket/internal/constants.{call_timeout}
import sprocket/context.{
  type ComponentHooks, type Context, type Dispatcher, type EffectCleanup,
  type EffectResult, type Element, type Hook, type HookDependencies,
  type HookTrigger, type IdentifiableHandler, type Updater, Callback, Changed,
  Context, Effect, EffectResult, Handler, IdentifiableHandler, Memo, OnMount,
  OnUpdate, Reducer, Unchanged, WithDeps, compare_deps,
}
import sprocket/render.{
  type RenderedElement, RenderResult, RenderedComponent, RenderedElement,
  RenderedFragment, live_render,
}
import sprocket/internal/patch.{type Patch}
import sprocket/internal/utils/ordered_map.{
  type KeyedItem, type OrderedMapIter, KeyedItem,
}
import sprocket/internal/utils/unique.{type Unique}
import sprocket/internal/exceptions.{throw_on_unexpected_hook_result}
import sprocket/internal/utils/timer.{interval}

pub type Runtime =
  Subject(Message)

type State {
  State(
    id: Unique,
    self: Runtime,
    cancel_shutdown: Option(fn() -> Nil),
    ctx: Context,
    updater: Option(Updater(Patch)),
    rendered: Option(RenderedElement),
  )
}

pub type Message {
  Shutdown
  BeginSelfDestruct(Int)
  CancelSelfDestruct
  GetRendered(reply_with: Subject(Option(RenderedElement)))
  GetId(reply_with: Subject(Unique))
  Render(reply_with: Subject(RenderedElement))
  RenderUpdate
  UpdateHook(Unique, fn(Hook) -> Hook)
  GetEventHandler(
    reply_with: Subject(Result(IdentifiableHandler, Nil)),
    id: Unique,
  )
  GetClientHook(reply_with: Subject(Result(Hook, Nil)), id: Unique)
}

fn handle_message(message: Message, state: State) -> actor.Next(Message, State) {
  case message {
    Shutdown -> {
      case state.rendered {
        Some(rendered) -> {
          cleanup_hooks(rendered)
          Nil
        }
        _ -> Nil
      }

      actor.Stop(process.Normal)
    }

    BeginSelfDestruct(timeout) -> {
      let cancel = interval(timeout, fn() { actor.send(state.self, Shutdown) })

      actor.continue(State(..state, cancel_shutdown: Some(cancel)))
    }

    CancelSelfDestruct -> {
      case state.cancel_shutdown {
        Some(cancel) -> {
          cancel()
          actor.continue(State(..state, cancel_shutdown: None))
        }
        _ -> actor.continue(state)
      }

      actor.continue(state)
    }

    GetRendered(reply_with) -> {
      actor.send(reply_with, state.rendered)

      actor.continue(state)
    }

    GetId(reply_with) -> {
      actor.send(reply_with, state.id)

      actor.continue(state)
    }

    Render(reply_with) -> {
      let state = case state {
        State(ctx: Context(view: view, ..) as ctx, rendered: prev_rendered, ..) -> {
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
          logger.error("No view found! A view must be provided to render.")
          state
        }
      }

      actor.continue(state)
    }

    RenderUpdate -> {
      case state {
        State(
          ctx: Context(view: view, ..) as ctx,
          updater: Some(updater),
          rendered: Some(prev_rendered),
          ..,
        ) -> {
          let state =
            timer.timed_operation(
              "RenderUpdate",
              fn() {
                let RenderResult(ctx, rendered) =
                  ctx
                  |> context.reset_for_render
                  |> live_render(view, None, Some(prev_rendered))

                let update = patch.create(prev_rendered, rendered)

                // send the rendered update using updater
                case updater.send(update) {
                  Ok(_) -> Nil
                  Error(_) -> {
                    logger.error("Failed to send patch update!")
                    Nil
                  }
                }

                cleanup_disposed_hooks(prev_rendered, rendered)

                // hooks might contain effects that will trigger a rerender. That is okay because any
                // RenderUpdate messages sent during this operation will be placed into this actor's mailbox
                // and will be processed in order after this current render is complete
                run_effects(State(..state, ctx: ctx, rendered: Some(rendered)))
              },
            )

          actor.continue(state)
        }

        State(updater: None, ..) -> {
          logger.error(
            "No updater found! An updater must be provided to send updates to the client.",
          )

          actor.continue(state)
        }

        State(rendered: None, ..) -> {
          logger.error(
            "No previous render found! View must be rendered at least once before updates can be sent.",
          )

          actor.continue(state)
        }
        _ -> {
          logger.error("No view found! A view must be provided to render.")
          actor.continue(state)
        }
      }
    }

    UpdateHook(id, updater) -> {
      actor.continue(update_hook_state(state, id, updater))
    }

    GetEventHandler(reply_with, id) -> {
      let handler =
        list.find(
          state.ctx.handlers,
          fn(h) {
            let IdentifiableHandler(i, _) = h
            i == id
          },
        )

      process.send(reply_with, handler)

      actor.continue(state)
    }

    GetClientHook(reply_with, id) -> {
      case state.rendered {
        Some(rendered) -> {
          let hook =
            find_rendered_hook(
              rendered,
              fn(hook) {
                case hook {
                  context.Client(i, _, _) -> unique.equals(i, id)
                  _ -> False
                }
              },
            )

          process.send(reply_with, option.to_result(hook, Nil))
        }
        None -> {
          process.send(reply_with, Error(Nil))
        }
      }

      actor.continue(state)
    }
  }
}

/// Start a new runtime actor
pub fn start(
  id: Unique,
  view: Element,
  cuid_channel: Subject(cuid.Message),
  updater: Option(Updater(Patch)),
  dispatcher: Option(Dispatcher),
) -> Result(Runtime, StartError) {
  let init = fn() {
    let self = process.new_subject()
    let render_update = fn() { actor.send(self, RenderUpdate) }
    let update_hook = fn(id, updater) {
      actor.send(self, UpdateHook(id, updater))
    }

    let state =
      State(
        id: id,
        self: self,
        cancel_shutdown: None,
        ctx: context.new(
          view,
          cuid_channel,
          dispatcher,
          render_update,
          update_hook,
        ),
        updater: updater,
        rendered: None,
      )

    let selector = process.selecting(process.new_selector(), self, identity)

    actor.Ready(state, selector)
  }

  actor.start_spec(Spec(init, call_timeout, handle_message))
}

/// Stop a runtime actor
pub fn stop(actor) {
  actor.send(actor, Shutdown)
}

/// Returns true if the actor matches a given websocket connection
pub fn get_id(actor) -> Unique {
  case process.try_call(actor, GetId(_), call_timeout) {
    Ok(id) -> id
    Error(err) -> {
      logger.error("Error getting id from runtime actor")
      io.debug(err)
      panic
    }
  }
}

/// Get the previously rendered view from the actor. This is useful for testing.
pub fn get_rendered(actor) {
  case process.try_call(actor, GetRendered(_), call_timeout) {
    Ok(rendered) -> rendered
    Error(err) -> {
      logger.error("Error getting rendered view from runtime actor")
      io.debug(err)
      panic
    }
  }
}

/// Get the event handler for a given id
pub fn get_handler(actor, id: String) {
  case
    process.try_call(
      actor,
      GetEventHandler(_, unique.from_string(id)),
      call_timeout,
    )
  {
    Ok(handler) -> handler
    Error(err) -> {
      logger.error("Error getting handler from runtime actor")
      io.debug(err)
      panic
    }
  }
}

/// Get the client hook for a given id
pub fn get_client_hook(actor, id: String) {
  case
    process.try_call(
      actor,
      GetClientHook(_, unique.from_string(id)),
      call_timeout,
    )
  {
    Ok(hook) -> hook
    Error(err) -> {
      logger.error("Error getting client hook from runtime actor")
      io.debug(err)
      panic
    }
  }
}

/// Render the view
pub fn render(actor) -> RenderedElement {
  case process.try_call(actor, Render(_), call_timeout) {
    Ok(rendered) -> rendered
    Error(err) -> {
      logger.error("Error rendering view from runtime actor")
      io.debug(err)
      panic
    }
  }
}

/// Render the view and send an update Patch to the updater
pub fn render_update(actor) -> Nil {
  actor.send(actor, RenderUpdate)
}

fn cleanup_hooks(rendered: RenderedElement) {
  // cleanup hooks
  build_hooks_map(rendered, map.new())
  |> map.values()
  |> list.each(fn(hook) {
    case hook {
      Effect(_, _, _, prev) -> {
        case prev {
          Some(EffectResult(Some(cleanup), _)) -> cleanup()
          _ -> Nil
        }
      }

      Reducer(_, _, cleanup) -> cleanup()

      _ -> Nil
    }
  })
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
    RenderedComponent(_fc, _key, _props, hooks, el) -> {
      // add hooks from this node
      let acc =
        ordered_map.fold(
          hooks,
          acc,
          fn(acc, hook) {
            let KeyedItem(_, hook) = hook
            case hook {
              Callback(id, _, _) -> {
                map.insert(acc, id, hook)
              }
              Memo(id, _, _) -> {
                map.insert(acc, id, hook)
              }
              Handler(id, _) -> {
                map.insert(acc, id, hook)
              }
              Effect(id, _, _, _) -> {
                map.insert(acc, id, hook)
              }
              Reducer(id, _, _) -> {
                map.insert(acc, id, hook)
              }
              context.State(id, _) -> {
                map.insert(acc, id, hook)
              }
              context.Client(id, _, _) -> {
                map.insert(acc, id, hook)
              }
            }
          },
        )

      // add hooks from child element
      build_hooks_map(el, acc)
    }
    RenderedElement(_tag, _key, _hooks, children) -> {
      // add hooks from children
      list.fold(
        children,
        acc,
        fn(acc, child) { map.merge(acc, build_hooks_map(child, acc)) },
      )
    }
    RenderedFragment(_key, children) -> {
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

fn find_rendered_hook(
  node: RenderedElement,
  find_by: fn(Hook) -> Bool,
) -> Option(Hook) {
  case node {
    RenderedComponent(_fc, _key, _props, hooks, el) -> {
      case
        ordered_map.find(hooks, fn(keyed_item) { find_by(keyed_item.value) })
      {
        Ok(KeyedItem(_, hook)) -> Some(hook)
        _ -> {
          find_rendered_hook(el, find_by)
        }
      }
    }
    RenderedElement(_tag, _key, _hooks, children) -> {
      list.fold(
        children,
        None,
        fn(acc, child) {
          case acc {
            Some(_) -> acc
            _ -> find_rendered_hook(child, find_by)
          }
        },
      )
    }
    RenderedFragment(_key, children) -> {
      list.fold(
        children,
        None,
        fn(acc, child) {
          case acc {
            Some(_) -> acc
            _ -> find_rendered_hook(child, find_by)
          }
        },
      )
    }
    _ -> None
  }
}

fn traverse_rendered_hooks(node: RenderedElement, process_hook: HookProcessor) {
  case node {
    RenderedComponent(fc, key, props, hooks, el) -> {
      let processed_hooks = process_hooks(hooks, process_hook)

      RenderedComponent(
        fc,
        key,
        props,
        processed_hooks,
        traverse_rendered_hooks(el, process_hook),
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
    RenderedFragment(key, children) -> {
      let r_children =
        list.fold(
          children,
          [],
          fn(acc, child) {
            [traverse_rendered_hooks(child, process_hook), ..acc]
          },
        )

      RenderedFragment(key, list.reverse(r_children))
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
              context.State(id, _) -> {
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
