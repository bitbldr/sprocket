import gleam/dynamic
import sprocket/context.{Context, Element}
import sprocket/hooks
import sprocket/internal/utils/unique
import sprocket/internal/exceptions.{throw_on_unexpected_hook_result}

pub fn state(
  ctx: Context,
  initial: a,
  cb: fn(Context, a, fn(a) -> Nil) -> #(Context, List(Element)),
) -> #(Context, List(Element)) {
  let Context(render_update: render_update, update_hook: update_hook, ..) = ctx

  let init_state = fn() {
    hooks.State(unique.cuid(ctx.cuid_channel), dynamic.from(initial))
  }

  let assert #(ctx, hooks.State(hook_id, value), _index) =
    context.fetch_or_init_hook(ctx, init_state)

  // create a dispatch function for updating the reducer's state and triggering a render update
  let setter = fn(value) -> Nil {
    update_hook(
      hook_id,
      fn(hook) {
        case hook {
          hooks.State(id, _) if id == hook_id ->
            hooks.State(id, dynamic.from(value))
          _ -> {
            // this should never happen and could be an indication that a hook is being
            // used incorrectly
            throw_on_unexpected_hook_result(hook)
          }
        }
      },
    )

    render_update()
  }

  cb(ctx, dynamic.unsafe_coerce(value), setter)
}
