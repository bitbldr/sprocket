import sprocket/internal/reconcile.{type RenderedElement}
import sprocket/internal/render.{type Renderer, Renderer}

pub fn renderer() -> Renderer(RenderedElement) {
  Renderer(render: fn(el) { el })
}
