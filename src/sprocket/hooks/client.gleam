import gleam/option.{Option}
import sprocket/context.{Context, Element}
import sprocket/hooks.{Client, ClientDispatcher, ClientEventHandler}
import sprocket/html/attributes.{Attribute, client_hook}
import sprocket/internal/utils/unique

pub fn client(
  ctx: Context,
  name: String,
  handle_event: Option(ClientEventHandler),
  cb: fn(Context, fn() -> Attribute, ClientDispatcher) ->
    #(Context, List(Element)),
) -> #(Context, List(Element)) {
  // define the client hook initializer
  let init = fn() { Client(unique.cuid(ctx.cuid_channel), name, handle_event) }

  // get the existing client hook or initialize it
  let #(ctx, Client(id, _name, _handle_event), index) =
    context.fetch_or_init_hook(ctx, init)

  // update the effect hook, combining with the previous result
  let ctx = context.update_hook(ctx, Client(id, name, handle_event), index)

  let bind_hook_attr = fn() { client_hook(id, name) }

  // callback to dispatch an event to the client
  let dispatch_event = fn(name: String, payload: Option(String)) {
    context.dispatch_event(ctx, id, name, payload)
  }

  cb(ctx, bind_hook_attr, dispatch_event)
}
