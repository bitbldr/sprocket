import gleam/option.{None}
import sprocket/context.{Context, Element}
import sprocket/hooks.{Effect, EffectCleanup, HookTrigger}
import sprocket/internal/utils/unique

pub fn effect(
  ctx: Context,
  effect_fn: fn() -> EffectCleanup,
  trigger: HookTrigger,
  cb: fn(Context) -> #(Context, List(Element)),
) -> #(Context, List(Element)) {
  // define the initial effect function that will only run on the first render
  let init = fn() {
    Effect(unique.cuid(ctx.cuid_channel), effect_fn, trigger, None)
  }

  // get the previous effect result, if one exists
  let #(ctx, Effect(id, _effect_fn, _trigger, prev), index) =
    context.fetch_or_init_hook(ctx, init)

  // update the effect hook, combining with the previous result
  let ctx =
    context.update_hook(ctx, Effect(id, effect_fn, trigger, prev), index)

  cb(ctx)
}
