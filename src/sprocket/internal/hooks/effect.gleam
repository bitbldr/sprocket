import gleam/option.{None}
import sprocket/internal/socket.{Socket}
import sprocket/element.{Element}
import sprocket/internal/hooks.{Effect, EffectCleanup, HookTrigger}
import sprocket/internal/utils/unique

pub fn effect(
  socket: Socket,
  effect_fn: fn() -> EffectCleanup,
  trigger: HookTrigger,
  cb: fn(Socket) -> #(Socket, List(Element)),
) -> #(Socket, List(Element)) {
  // define the initial effect function that will only run on the first render
  let init = fn() { Effect(unique.new(), effect_fn, trigger, None) }

  // get the previous effect result, if one exists
  let #(socket, Effect(id, _effect_fn, _trigger, prev), index) =
    socket.fetch_or_init_hook(socket, init)

  // update the effect hook, combining with the previous result
  let socket =
    socket.update_hook(socket, Effect(id, effect_fn, trigger, prev), index)

  cb(socket)
}
