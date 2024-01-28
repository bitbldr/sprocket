import sprocket/internal/reconcile.{type RenderedElement}

pub type Renderer(result) {
  Renderer(render: fn(RenderedElement) -> result)
}
