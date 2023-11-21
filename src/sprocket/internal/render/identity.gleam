import sprocket/render.{type RenderedElement, type Renderer, Renderer}

pub fn renderer() -> Renderer(RenderedElement) {
  Renderer(render: fn(el) { el })
}
