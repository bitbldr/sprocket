import gleam/option.{None}
import sprocket/element.{Element}
import sprocket/socket.{Socket}
import sprocket/hooks.{Callback, HookTrigger}

pub fn callback(
  socket: Socket,
  callback_fn: fn() -> Nil,
  trigger: HookTrigger,
  cb: fn(Socket, fn() -> Nil) -> #(Socket, List(Element)),
) -> #(Socket, List(Element)) {
  let #(socket, Callback(_callback_fn, _trigger, prev), index) =
    socket.fetch_or_init_hook(
      socket,
      fn() { Callback(callback_fn, trigger, None) },
    )

  let socket =
    socket.update_hook(socket, Callback(callback_fn, trigger, prev), index)

  // TODO: this needs some work to take in from socket an async callback dispatcher
  // and generate an anonymous function that will call the dispatcher when the callback is triggered

  // TODO: The callback logic from process_hooks need to be moved over here so that it is executed during rendering

  cb(socket, fn() { callback_fn() })
}
