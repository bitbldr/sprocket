import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option.{type Option, None, Some}
import sprocket/context.{
  type Attribute, type ClientDispatcher, type ClientEventHandler, type Context,
  type Dispatcher, type EffectCleanup, type Element, type HandlerFn,
  type HookDependencies, type IdentifiableHandler, Callback, CallbackResult,
  Changed, Client, ClientHook, Context, Effect, Handler, IdentifiableHandler,
  Unchanged, compare_deps,
}
import sprocket/internal/exceptions.{throw_on_unexpected_hook_result}
import sprocket/internal/utils/unique.{type Unique}
import sprocket/internal/utils/unsafe_coerce.{unsafe_coerce}

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

/// Client hook attribute that can be used to reference a client hook by its id.
pub fn client_hook(id: Unique, name: String) -> Attribute {
  ClientHook(id, name)
}

/// Client Hook
/// -----------
/// Creates a client hook that can be used to facilitate communication with a client
/// (such as a web browser). The client hook functionality is defined by the client
/// and is typically used to send or receive messages to/from the client.
pub fn client(
  ctx: Context,
  name: String,
  handle_event: Option(ClientEventHandler),
  cb: fn(Context, fn() -> Attribute, ClientDispatcher) -> #(Context, Element),
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
  let emit_event = fn(name: String, payload: Option(String)) {
    context.emit_event(ctx, id, name, payload)
  }

  cb(ctx, bind_hook_attr, emit_event)
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

/// Handler Hook
/// -------------
/// Creates a handler callback that can be triggered from DOM event attributes. The callback
/// function will be called with the event payload. This hook ensures that the handler
/// identifier remains stable preventing unnecessary id changes across renders.
pub fn handler(
  ctx: Context,
  handler_fn: HandlerFn,
  cb: fn(Context, IdentifiableHandler) -> #(ctx, Element),
) -> #(ctx, Element) {
  let assert #(ctx, Handler(id, _handler_fn), index) =
    context.fetch_or_init_hook(ctx, fn() {
      Handler(unique.cuid(ctx.cuid_channel), handler_fn)
    })

  let ctx = context.update_hook(ctx, Handler(id, handler_fn), index)

  cb(ctx, IdentifiableHandler(id, handler_fn))
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
/// The provider hook will return the current value provided from an ancestor with the given key. The
/// ancestor provides the value by using the `provider` element from the `sprocket/context` module.
/// 
/// This hook is conceptually the same as the `useContext` hook in React.
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

pub type Cmd(msg) =
  fn(Dispatcher(msg)) -> Nil

type ReducerUpdate(model, msg) =
  fn(model, msg) -> #(model, List(Cmd(msg)))

fn dynamic_cmds_from(cmds: List(Cmd(msg))) -> List(Cmd(Dynamic)) {
  cmds
  |> list.map(fn(cmd) {
    fn(dispatch) { cmd(fn(msg) { dispatch(dynamic.from(msg)) }) }
  })
}

/// Reducer Hook
/// ------------
/// Creates a reducer hook that can be used to manage more complex state. The reducer hook will
/// return the current model of the reducer and a dispatch function that can be used
/// to update the reducer's model. Dispatching a message to the reducer will result
/// in a re-render of the component.
pub fn reducer(
  ctx: Context,
  initial: #(model, List(Cmd(msg))),
  update: ReducerUpdate(model, msg),
  cb: fn(Context, model, fn(msg) -> Nil) -> #(Context, Element),
) -> #(Context, Element) {
  // let Context(dispatcher: dispatcher, render_update: render_update ..) = ctx

  let init_state = fn() {
    let initial_model = initial.0
    let initial_cmds = initial.1

    context.Reducer(
      unique.cuid(ctx.cuid_channel),
      dynamic.from(initial_model),
      fn(model: Dynamic, msg: Dynamic) {
        let #(updated_model, cmds) =
          update(unsafe_coerce(model), unsafe_coerce(msg))

        #(dynamic.from(updated_model), dynamic_cmds_from(cmds))
      },
      dynamic_cmds_from(initial_cmds),
    )
  }

  let assert #(
    ctx,
    context.Reducer(hook_id, model, _update, _pending_cmds),
    _index,
  ) = context.fetch_or_init_hook(ctx, init_state)

  // create a dispatch function for updating the reducer's state and triggering a render update
  let dispatch = fn(msg: msg) -> Nil {
    ctx.dispatch(hook_id, dynamic.from(msg))
    // render_update()
  }

  cb(ctx, unsafe_coerce(model), dispatch)
}

// /// Reducer Hook
// /// ------------
// /// Creates a reducer hook that can be used to manage state. The reducer hook will
// /// return the current state of the reducer and a dispatch function that can be used
// /// to update the reducer's state. Dispatching a message to the reducer will result
// /// in a re-render of the component.
// pub fn reducer(
//   ctx: Context,
//   initial: #(model, List(Cmd(msg))),
//   reducer: Reducer(model, msg),
//   cb: fn(Context, model, fn(msg) -> Nil) -> #(Context, Element),
// ) -> #(Context, Element) {
//   let Context(render_update: render_update, ..) = ctx

//   // create a dispatch function for updating the reducer's state and triggering a render update
//   let dispatch = fn(msg, a) -> Nil {
//     // this will update the reducer's state and trigger a re-render. To ensure we re-render
//     // with the latest state, this message must be processed before the next render cycle. However,
//     // because we also use a process.call to the same reducer actor to get the current state, we should
//     // be guaranteed to have this message processed before that call during the next render cycle.
//     actor.send(a, ReducerDispatch(r: reducer, m: msg))

//     render_update()
//   }

//   // Creates an actor process for a reducer that handles two types of messages:
//   //  1. GetState msg, which simply returns the state of the reducer
//   //  2. ReducerDispatch msg, which will update the reducer state when a dispatch is triggered
//   let reducer_init = fn() {
//     // Create the reducer actor initializer
//     let reducer_actor_init = fn() {
//       let self = process.new_subject()
//       let selector = process.selecting(process.new_selector(), self, identity)

//       let initial_model = initial.0
//       let initial_cmds = initial.1

//       // Process the initial commands
//       list.each(initial_cmds, fn(cmd) { cmd(dispatch(_, self)) })

//       actor.Ready(#(self, initial_model), selector)
//     }

//     // Define the message handler for the reducer actor. There are two levels of state being
//     // addressed here: the actor state and the reducer state. The actor state is a tuple of
//     // the actor's subject and the reducer's state. The reducer state is the current state of
//     // the reducer's model.
//     let reducer_actor_handle_message = fn(
//       message: ReducerMsg(model, msg),
//       state,
//     ) -> actor.Next(
//       ReducerMsg(model, msg),
//       #(Subject(ReducerMsg(model, msg)), model),
//     ) {
//       case message {
//         Shutdown -> actor.Stop(process.Normal)

//         GetState(reply_with) -> {
//           let #(_self, model) = state

//           process.send(reply_with, model)
//           actor.continue(state)
//         }

//         ReducerDispatch(r, m) -> {
//           let #(self, model) = state

//           // This is the main logic for updating the reducer's state. The reducer function will
//           // return the updated model and a list of zero or more commands to execute. The commands
//           // are functions that will be called with the dispatcher function which may trigger
//           // additional messages to the reducer.
//           let #(updated_model, cmds) = r(model, m)

//           list.each(cmds, fn(cmd) { cmd(dispatch(_, self)) })

//           actor.continue(#(self, updated_model))
//         }
//       }
//     }

//     // Finally, start the actor process
//     let assert Ok(reducer_actor) =
//       actor.start_spec(actor.Spec(
//         reducer_actor_init,
//         call_timeout,
//         reducer_actor_handle_message,
//       ))
//       |> result.map_error(fn(error) {
//         logger.error("hooks.reducer: failed to start reducer actor")
//         error
//       })

//     context.Reducer(
//       unique.cuid(ctx.cuid_channel),
//       dynamic.from(reducer_actor),
//       fn() { process.send(reducer_actor, Shutdown) },
//     )
//   }

//   let assert #(ctx, context.Reducer(_id, dyn_reducer_actor, _cleanup), _index) =
//     context.fetch_or_init_hook(ctx, reducer_init)

//   // we dont know what types of reducer messages a component will implement so the best we can do is
//   // store the actors as dynamic and coerce them back when updating
//   let reducer_actor = unsafe_coerce(dyn_reducer_actor)

//   // get the current state of the reducer
//   let state = process.call(reducer_actor, GetState(_), call_timeout)

//   cb(ctx, state, dispatch(_, reducer_actor))
// }

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
  let Context(render_update: render_update, update_hook: update_hook, ..) = ctx

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

    render_update()
  }

  cb(ctx, unsafe_coerce(value), setter)
}
