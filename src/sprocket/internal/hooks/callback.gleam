import gleam/option.{None, Option, Some}
import sprocket/internal/element.{Element}
import sprocket/internal/identifiable_callback.{CallbackFn,
  IdentifiableCallback}
import sprocket/internal/socket.{Socket}
import sprocket/internal/hooks.{
  Callback, CallbackResult, Changed, HookDependencies, HookTrigger, OnMount,
  OnUpdate, Unchanged, WithDeps, compare_deps,
}
import sprocket/internal/exception.{throw_on_unexpected_hook_result}
import sprocket/internal/utils/unique

pub fn callback(
  socket: Socket,
  callback_fn: CallbackFn,
  trigger: HookTrigger,
  cb: fn(Socket, IdentifiableCallback) -> #(Socket, List(Element)),
) -> #(Socket, List(Element)) {
  let init_callback = fn() {
    Callback(unique.new(), callback_fn, trigger, None)
  }

  let #(socket, Callback(id, _callback_fn, _trigger, prev), index) =
    socket.fetch_or_init_hook(socket, init_callback)

  let result = maybe_update_callback(callback_fn, trigger, prev)

  let socket =
    socket.update_hook(
      socket,
      Callback(id, result.callback, trigger, Some(result)),
      index,
    )

  // TODO: this needs some work to take in from socket an async callback dispatcher
  // and generate an anonymous function that will call the dispatcher when the callback is triggered

  cb(socket, IdentifiableCallback(id, result.callback))
}

fn maybe_update_callback(
  callback_fn: CallbackFn,
  trigger: HookTrigger,
  prev: Option(CallbackResult),
) -> CallbackResult {
  case trigger {
    // Only compute callback on the first render. This is a convience for WithDeps([]).
    OnMount -> {
      replace_callback(callback_fn, Some([]))
    }

    // Recompute callback on every update
    OnUpdate -> {
      replace_callback(callback_fn, None)
    }

    // Only compute callback on the first render and when the dependencies change
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
  callback_fn: CallbackFn,
  deps: Option(HookDependencies),
) -> CallbackResult {
  CallbackResult(callback_fn, deps)
}
