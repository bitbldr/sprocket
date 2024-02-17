import sprocket/internal/reconcile.{type ReconciledElement}

pub type Renderer(result) {
  Renderer(render: fn(ReconciledElement) -> result)
}
