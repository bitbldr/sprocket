import gleam/dynamic.{Dynamic}
import sprocket/html/attribute.{Attribute}
import gleam/option.{None}
import sprocket/socket.{Component, Element, Raw, RenderedResult, Socket}

pub type Renderer(r) {
  Renderer(
    element: fn(Socket, String, List(Attribute), List(Element)) ->
      RenderedResult(r),
    component: fn(
      Socket,
      fn(Socket, Dynamic) -> #(Socket, List(Element)),
      Dynamic,
    ) ->
      RenderedResult(r),
    raw: fn(Socket, String) -> RenderedResult(r),
  )
}

pub fn render(el: Element, renderer: Renderer(r)) -> r {
  let RenderedResult(rendered: rendered, ..) =
    live_render(socket.new(None), el, renderer)

  rendered
}

pub fn live_render(
  socket: Socket,
  el: Element,
  renderer: Renderer(r),
) -> RenderedResult(r) {
  // TODO: render_count > SOME_THRESHOLD then panic("Possible infinite rerender loop")

  case el {
    Element(tag, attrs, children) ->
      renderer.element(socket, tag, attrs, children)
    Component(fc, props) -> renderer.component(socket, fc, props)
    Raw(text) -> renderer.raw(socket, text)
  }
}
