import gleam/option.{None}
import gleam/result
import ids/cuid
import sprocket/internal/context.{type Element}
import sprocket/internal/logger
import sprocket/internal/reconcile.{type ReconciledElement, ReconciledResult}
import sprocket/internal/reconcilers/recursive.{reconcile}

pub type Renderer(result) {
  Renderer(render: fn(ReconciledElement) -> result)
}

pub fn renderer(
  r: Renderer(result),
  cb: fn(fn(ReconciledElement) -> result) -> a,
) -> a {
  cb(r.render)
}

/// Renders the given element as a stateless element using a given renderer.
pub fn render_element(el: Element, r: Renderer(a)) -> a {
  use render <- renderer(r)

  // Internally this function uses the reconciler with an empty previous element
  // and a placeholder ctx but then discards the ctx and returns the result.
  let assert Ok(cuid_channel) =
    cuid.start()
    |> result.map_error(fn(error) {
      logger.error("render.render: Failed to start a cuid channel")
      error
    })

  let dispatch_client_hook_event = fn(_id, _kind, _payload) { Nil }
  let trigger_reconciliation = fn() { Nil }
  let update_hook = fn(_index, _updater) { Nil }

  let ctx =
    context.new(
      el,
      cuid_channel,
      dispatch_client_hook_event,
      trigger_reconciliation,
      update_hook,
    )

  let ReconciledResult(reconciled: reconciled, ..) =
    reconcile(ctx, el, None, None)

  render(reconciled)
}
