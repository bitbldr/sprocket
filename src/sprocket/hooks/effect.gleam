import gleam/dynamic
import gleam/otp/actor
import gleam/erlang/process.{Subject}
import sprocket/socket.{Socket}
import sprocket/element.{Element}
import sprocket/hooks.{Effect, Hook, HookCleanup, HookTrigger}

pub fn effect(
  socket: Socket,
  effect_fn: fn() -> HookCleanup,
  trigger: HookTrigger,
  cb: fn(Socket) -> #(Socket, List(Element)),
) -> #(Socket, List(Element)) {
  let socket = socket.push_hook(socket, Effect(effect_fn, trigger))

  cb(socket)
}
