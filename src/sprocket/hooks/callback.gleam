import sprocket/element.{Element}
import sprocket/socket.{Socket}
import sprocket/hooks.{Callback, HookTrigger}

pub fn callback(
  socket: Socket,
  callback_fn: fn() -> Nil,
  trigger: HookTrigger,
  cb: fn(Socket) -> #(Socket, List(Element)),
) -> #(Socket, List(Element)) {
  let socket = socket.push_hook(socket, Callback(callback_fn, trigger))

  cb(socket)
}
