import sprocket/internal/reconcile.{type ReconciledElement}

pub type Renderer(result) {
  Renderer(render: fn(ReconciledElement) -> result)
}

pub fn renderer(
  r: Renderer(result),
  cb: fn(fn(ReconciledElement) -> result) -> a,
) -> a {
  cb(r.render)
}
