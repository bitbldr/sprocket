import sprocket/render.{RenderedElement, Renderer}

pub fn renderer() -> Renderer(RenderedElement) {
  Renderer(render: fn(el) { el })
}
