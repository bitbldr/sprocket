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
import sprocket/internal/reconcile.{
  type RenderedElement, ReconciledResult, RenderedComponent, RenderedElement,
  RenderedFragment,
}
import sprocket/internal/reconcilers/recursive
import sprocket/internal/patch.{type Patch}
import sprocket/internal/utils/ordered_map.{
  type KeyedItem, type OrderedMapIter, KeyedItem,
}
import sprocket/internal/utils/unique.{type Unique}
import sprocket/internal/exceptions.{throw_on_unexpected_hook_result}
import sprocket/internal/utils/timer.{interval}

pub type Runtime =
  Subject(Message)

pub opaque type State {
  State(
    id: Unique,
    self: Runtime,
    cancel_shutdown: Option(fn() -> Nil),
    ctx: Context,
    updater: Option(Updater(Patch)),
    rendered: Option(RenderedElement),
  )
}

// TODO: figure out how to make this private
pub opaque type Message {
  Shutdown
  BeginSelfDestruct(Int)
  CancelSelfDestruct
  GetState(reply_with: Subject(State))
  SetState(fn(State) -> State)
  GetRendered(reply_with: Subject(Option(RenderedElement)))
  GetId(reply_with: Subject(Unique))
  GetContext(reply_with: Subject(Context))
  GetView(reply_with: Subject(Element))
  GetUpdater(reply_with: Subject(Option(Updater(Patch))))
  GetHandler(reply_with: Subject(Result(IdentifiableHandler, Nil)), String)
  GetClientHook(reply_with: Subject(Result(Hook, Nil)), String)
  UpdateHookState(Unique, fn(Hook) -> Hook)
  RenderUpdate
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

    GetState(reply_with) -> {
      actor.send(reply_with, state)

      actor.continue(state)
    }

    SetState(update_fn) -> {
      actor.continue(update_fn(state))
    }

    GetRendered(reply_with) -> {
      actor.send(reply_with, state.rendered)

      actor.continue(state)
    }

    GetId(reply_with) -> {
      actor.send(reply_with, state.id)

      actor.continue(state)
    }

    GetContext(reply_with) -> {
      actor.send(reply_with, state.ctx)

      actor.continue(state)
    }

    GetView(reply_with) -> {
      actor.send(reply_with, state.ctx.view)

      actor.continue(state)
    }

    GetUpdater(reply_with) -> {
      actor.send(reply_with, state.updater)

      actor.continue(state)
    }

    GetHandler(reply_with, id) -> {
      let handler =
        list.find(
          state.ctx.handlers,
          fn(h) {
            let IdentifiableHandler(i, _) = h
            unique.to_string(i) == id
          },
        )

      actor.send(reply_with, handler)

      actor.continue(state)
    }

    GetClientHook(reply_with, id) -> {
      let rendered = state.rendered

      let result = case rendered {
        Some(rendered) -> {
          let hook =
            find_rendered_hook(
              rendered,
              fn(hook) {
                case hook {
                  context.Client(i, _, _) -> unique.to_string(i) == id
                  _ -> False
                }
              },
            )

          option.to_result(hook, Nil)
        }
        None -> {
          Error(Nil)
        }
      }

      actor.send(reply_with, result)

      actor.continue(state)
    }

    UpdateHookState(hook_id, update_fn) -> {
      let rendered = state.rendered

      let updated =
        option.map(
          rendered,
          fn(node) {
            traverse_rendered_hooks(
              node,
              fn(hook) {
                case hook {
                  // this operation is only applicable to State hooks
                  context.State(id, _) -> {
                    case id == hook_id {
                      True -> {
                        update_fn(hook)
                      }
                      False -> hook
                    }
                  }
                  _ -> hook
                }
              },
            )
          },
        )

      actor.continue(State(..state, rendered: updated))
    }

    RenderUpdate -> {
      let prev_rendered = state.rendered
      let maybe_updater = state.updater
      let view = state.ctx.view

      let #(ctx, rendered) = reconcile(state.ctx, view, prev_rendered)

      case prev_rendered {
        Some(prev_rendered) -> {
          case maybe_updater {
            Some(updater) -> {
              let update = patch.create(prev_rendered, rendered)

              // send the rendered update using updater
              case updater.send(update) {
                Ok(_) -> Nil
                Error(_) -> {
                  logger.error("Failed to send update patch!")
                  Nil
                }
              }
            }

            _ -> Nil
          }

          run_cleanup_for_disposed_hooks(prev_rendered, rendered)
        }

        _ -> Nil
      }

      actor.continue(State(..state, ctx: ctx, rendered: Some(rendered)))
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
    let update_hook = fn(id, updater) { update_hook_state(self, id, updater) }

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
  case process.try_call(actor, GetHandler(_, id), call_timeout) {
    Ok(rendered) -> rendered
    Error(err) -> {
      logger.error(
        "Error getting handler for id " <> id <> " from runtime actor",
      )
      io.debug(err)
      Error(Nil)
    }
  }
}

/// Get the client hook for a given id
pub fn get_client_hook(actor, id: String) {
  case process.try_call(actor, GetClientHook(_, id), call_timeout) {
    Ok(rendered) -> rendered
    Error(err) -> {
      logger.error(
        "Error getting client hook for id " <> id <> " from runtime actor",
      )
      io.debug(err)
      Error(Nil)
    }
  }
}

fn update_hook_state(actor: Runtime, hook_id: Unique, updater: fn(Hook) -> Hook) {
  actor.send(actor, UpdateHookState(hook_id, updater))
}

// TODO: remove this if possible
fn update_state(actor, update_fn: fn(State) -> State) {
  actor.send(actor, SetState(update_fn))
}

fn get_state(actor) -> State {
  case process.try_call(actor, GetState(_), call_timeout) {
    Ok(state) -> state
    Error(err) -> {
      logger.error("Error getting state from runtime actor")
      io.debug(err)
      panic
    }
  }
}

/// Render the view - should only be used for testing purposes
pub fn render(actor) -> RenderedElement {
  let State(ctx: ctx, rendered: rendered, ..) = get_state(actor)

  let #(ctx, rendered) = reconcile(ctx, ctx.view, rendered)

  update_state(
    actor,
    fn(state) { State(..state, ctx: ctx, rendered: Some(rendered)) },
  )

  rendered
}

fn reconcile(
  ctx: Context,
  view: Element,
  prev: Option(RenderedElement),
) -> #(Context, RenderedElement) {
  timer.timed_operation(
    "runtime.reconcile",
    fn() {
      let ReconciledResult(ctx, reconciled) =
        ctx
        |> context.reset_for_render
        |> recursive.reconcile(view, None, prev)

      option.map(
        prev,
        fn(prev) { run_cleanup_for_disposed_hooks(prev, reconciled) },
      )

      // hooks might contain effects that will trigger a rerender. That is okay because any
      // RenderUpdate messages sent during this operation will be placed into this actor's mailbox
      // and will be processed in order after this current render is complete
      let reconciled = run_effects(reconciled)

      #(ctx, reconciled)
    },
  )
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

fn run_cleanup_for_disposed_hooks(
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

fn run_effects(rendered: RenderedElement) -> RenderedElement {
  process_state_hooks(
    rendered,
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
fn process_state_hooks(
  rendered: RenderedElement,
  process_hook: HookProcessor,
) -> RenderedElement {
  traverse_rendered_hooks(rendered, process_hook)
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
