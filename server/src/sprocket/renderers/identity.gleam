import sprocket/internal/reconcile.{type ReconciledElement}
import sprocket/render.{type Renderer, Renderer}

/// Returns an identity renderer used to render reconciled elements. This renderer
/// simply returns the reconciled element as-is.
pub fn identity_renderer() -> Renderer(ReconciledElement) {
  Renderer(render: fn(el: ReconciledElement) { el })
}
