import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option, None, Some}
import gleam/result
import sprocket/internal/context.{
  type Attribute, type ClientHookDispatcher, type ClientHookEventHandler,
  type Context, type EffectCleanup, type Element, type HookDependencies,
  type HookDependency, Callback, CallbackResult, Changed, Client, ClientHook,
  Context, Effect, Provider, Unchanged, compare_deps,
}
import sprocket/internal/exceptions.{throw_on_unexpected_hook_result}
import sprocket/internal/logger
import sprocket/internal/reducer
import sprocket/internal/utils/unique
import sprocket/internal/utils/unsafe_coerce.{unsafe_coerce}

pub type Dispatcher(msg) =
  reducer.Dispatcher(msg)

pub type Initializer(model, msg) =
  reducer.Initializer(model, msg)

pub type Updater(model, msg) =
  reducer.Updater(model, msg)

/// Callback Hook
/// -------------
/// Creates a callback hook that will return a cached version of a given callback
/// function and only recompute the callback when specified dependencies change.
/// 
/// This hook is useful for when a component needs to use a callback function that
/// is referenced as a dependency by another hook, such as an effect hook.
pub fn callback(
  ctx: Context,
  callback_fn: fn() -> Nil,
  deps: HookDependencies,
  cb: fn(Context, fn() -> Nil) -> #(ctx, Element),
) -> #(ctx, Element) {
  let assert #(ctx, Callback(id, current_callback_fn, prev), index) =
    context.fetch_or_init_hook(ctx, fn() {
      Callback(unique.cuid(ctx.cuid_channel), callback_fn, None)
    })

  let #(callback_fn, deps) =
    maybe_trigger_update(
      deps,
      prev
        |> option.then(fn(prev) { prev.deps }),
      current_callback_fn,
      fn() { callback_fn },
    )

  let ctx =
    context.update_hook(
      ctx,
      Callback(id, callback_fn, Some(CallbackResult(deps))),
      index,
    )

  cb(ctx, callback_fn)
}

fn maybe_trigger_update(
  deps: HookDependencies,
  prev: Option(HookDependencies),
  value: a,
  updater: fn() -> a,
) -> #(a, Option(HookDependencies)) {
  case prev {
    Some(prev_deps) -> {
      case compare_deps(prev_deps, deps) {
        Changed(new_deps) -> #(updater(), Some(new_deps))
        Unchanged -> #(value, prev)
      }
    }

    // initial render
    None -> #(updater(), Some(deps))
  }
}

/// Client Hook
/// -----------
/// Creates a client hook that can be used to facilitate communication with a client
/// (such as a web browser). The client hook functionality is defined by the client
/// and is typically used to send or receive messages to/from the client.
pub fn client(
  ctx: Context,
  name: String,
  handle_event: Option(ClientHookEventHandler),
  cb: fn(Context, fn() -> Attribute, ClientHookDispatcher) ->
    #(Context, Element),
) -> #(Context, Element) {
  // define the client hook initializer
  let init = fn() { Client(unique.cuid(ctx.cuid_channel), name, handle_event) }

  // get the existing client hook or initialize it
  let assert #(ctx, Client(id, _name, _handle_event), index) =
    context.fetch_or_init_hook(ctx, init)

  // update the effect hook, combining with the previous result
  let ctx = context.update_hook(ctx, Client(id, name, handle_event), index)

  let bind_hook_attr = fn() { ClientHook(id, name) }

  // callback to dispatch an event to the client
  let dispatch_event = fn(kind: String, payload: Option(Dynamic)) {
    context.dispatch_client_hook_event(ctx, id, kind, payload)
  }

  cb(ctx, bind_hook_attr, dispatch_event)
}

/// Creates a hook dependency from some value
pub fn dep(dependency: a) -> HookDependency {
  dynamic.from(dependency)
}

/// Effect Hook
/// -----------
/// Creates an effect hook that will run the given effect function when the deps change. The effect
/// function is memoized and recomputed when the deps change. The effect function can return a cleanup
/// function that will be called when the effect is removed.
pub fn effect(
  ctx: Context,
  effect_fn: fn() -> EffectCleanup,
  deps: HookDependencies,
  cb: fn(Context) -> #(Context, Element),
) -> #(Context, Element) {
  // define the initial effect function that will only run when the hook is first created
  let init = fn() {
    Effect(unique.cuid(ctx.cuid_channel), effect_fn, deps, None)
  }

  // get the previous effect result, if one exists
  let assert #(ctx, Effect(id, _effect_fn, _deps, prev), index) =
    context.fetch_or_init_hook(ctx, init)

  // update the effect hook, combining with the previous result
  let ctx = context.update_hook(ctx, Effect(id, effect_fn, deps, prev), index)

  cb(ctx)
}

/// Memo Hook
/// ---------
/// Creates a memo hook that can be used to memoize the result of a function. The memo
/// hook will return the result of the function and will only recompute the result when
/// the dependencies change.
/// 
/// This hook is useful for optimizing performance by memoizing the result of an
/// expensive function between renders.
pub fn memo(
  ctx: Context,
  memo_fn: fn() -> a,
  deps: HookDependencies,
  cb: fn(Context, a) -> #(Context, Element),
) -> #(Context, Element) {
  let assert #(ctx, context.Memo(id, current_memoized, prev), index) =
    context.fetch_or_init_hook(ctx, fn() {
      context.Memo(unique.cuid(ctx.cuid_channel), dynamic.from(memo_fn()), None)
    })

  let #(memoized, deps) =
    maybe_trigger_update(
      deps,
      prev
        |> option.then(fn(prev) { prev.deps }),
      current_memoized,
      fn() { dynamic.from(memo_fn()) },
    )

  let ctx =
    context.update_hook(
      ctx,
      context.Memo(id, memoized, Some(context.MemoResult(deps))),
      index,
    )

  cb(ctx, unsafe_coerce(memoized))
}

/// Provider Hook
/// ------------
/// Creates a provider hook that allows a component to access data from a parent or ancestor component.
/// The provider hook will return an optional containing the current value provided from an ancestor using
/// a given provider function. If the provider hook is called from a context that does not have a matching
/// provider, the hook will return `None`.
/// 
/// The ancestor provides the value by using a custom provider that is unique to the provider hook. This
/// custom provider is created using `provider` function in the `sprocket/internal/context` module.
/// 
/// This hook is conceptually similar to the `useContext` hook in React.
pub fn provider(
  ctx: Context,
  key: String,
  cb: fn(Context, Option(a)) -> #(Context, Element),
) -> #(Context, Element) {
  let value =
    ctx.providers
    |> dict.get(key)
    |> option.from_result()
    |> option.map(fn(v) { unsafe_coerce(v) })

  cb(ctx, value)
}

/// Creates a new provider element with the given key and value.
pub fn provide(key: String, value: a, element: Element) -> Element {
  Provider(key, dynamic.from(value), element)
}

/// Reducer Hook
/// ------------
/// Creates a reducer hook that can be used to manage state. The reducer hook will
/// return the current state of the reducer and a dispatch function that can be used
/// to update the reducer's state. Dispatching a message to the reducer will result
/// in a re-render of the component.
pub fn reducer(
  ctx: Context,
  initialize: Initializer(model, msg),
  update: Updater(model, msg),
  cb: fn(Context, model, fn(msg) -> Nil) -> #(Context, Element),
) -> #(Context, Element) {
  let Context(trigger_reconciliation: trigger_reconciliation, ..) = ctx

  // Creates a reducer actor process that handles state management and updates
  let reducer_init = fn() {
    // Start the actor process
    let assert Ok(reducer_actor) =
      reducer.start(initialize, update, fn(_) { trigger_reconciliation() })
      |> result.map_error(fn(error) {
        logger.error("hooks.reducer: failed to start reducer actor")
        error
      })

    context.Reducer(
      unique.cuid(ctx.cuid_channel),
      dynamic.from(reducer_actor),
      fn() { reducer.shutdown(reducer_actor) },
    )
  }

  let assert #(ctx, context.Reducer(_id, dyn_reducer_actor, _cleanup), _index) =
    context.fetch_or_init_hook(ctx, reducer_init)

  // we dont know what types of reducer messages a component will implement so the best we can do is
  // store the actors as dynamic and coerce them back when updating
  let reducer_actor = unsafe_coerce(dyn_reducer_actor)

  // get the current model of the reducer
  let model = reducer.get_model(reducer_actor)

  cb(ctx, model, reducer.dispatch(reducer_actor, _))
}

/// State Hook
/// ----------
/// Creates a state hook that can be used to manage state. The state hook will return
/// the current state and a setter function that can be used to update the state. Setting
/// the state will result in a re-render of the component.
pub fn state(
  ctx: Context,
  initial: a,
  cb: fn(Context, a, fn(a) -> Nil) -> #(Context, Element),
) -> #(Context, Element) {
  let Context(
    trigger_reconciliation: trigger_reconciliation,
    update_hook: update_hook,
    ..,
  ) = ctx

  let init_state = fn() {
    context.State(unique.cuid(ctx.cuid_channel), dynamic.from(initial))
  }

  let assert #(ctx, context.State(hook_id, value), _index) =
    context.fetch_or_init_hook(ctx, init_state)

  // create a setter function for updating the state and triggering a render update
  let setter = fn(value) -> Nil {
    update_hook(hook_id, fn(hook) {
      case hook {
        context.State(id, _) if id == hook_id ->
          context.State(id, dynamic.from(value))
        _ -> {
          // this should never happen and could be an indication that a hook is being
          // used incorrectly
          throw_on_unexpected_hook_result(hook)
        }
      }
    })

    trigger_reconciliation()
  }

  cb(ctx, unsafe_coerce(value), setter)
}
