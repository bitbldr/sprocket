import gleam/list
import gleam/option.{None, Option}
import gleam/dynamic.{Dynamic}
import sprocket/html/attribute.{Attribute, Event, Key}
import sprocket/element.{
  AbstractFunctionalComponent, Component, Element, Raw, SafeHtml,
}
import sprocket/socket.{Socket}

pub type Renderer(result) {
  Renderer(render: fn(RenderedElement) -> result)
}

pub type RenderedAttribute {
  RenderedAttribute(name: String, value: String)
  RenderedKey(key: String)
  RenderedEventHandler(kind: String, id: String)
}

pub type RenderedElement {
  RenderedElement(
    tag: String,
    key: Option(String),
    attrs: List(RenderedAttribute),
    children: List(RenderedElement),
  )
  RenderedComponent(
    fc: AbstractFunctionalComponent,
    props: Dynamic,
    children: List(RenderedElement),
  )
  RenderedText(text: String)
}

pub type RenderResult(a) {
  RenderResult(socket: Socket, rendered: a)
}

// Renders the given element using the provided renderer as a stateless element.
//
// Internally this function uses live_render with a placeholder socket to render the tree,
// but then discards the socket and returns the result.
pub fn render(el: Element, renderer: Renderer(r)) -> r {
  let RenderResult(rendered: rendered, ..) = live_render(socket.new(None), el)

  renderer.render(rendered)
}

// Renders the given element into a RenderedElement tree.
// Returns the socket and a stateful RenderedElement tree using the given socket.
pub fn live_render(socket: Socket, el: Element) -> RenderResult(RenderedElement) {
  // TODO: render_count > SOME_THRESHOLD then panic("Possible infinite rerender loop")

  case el {
    Element(tag, attrs, children) -> element(socket, tag, attrs, children)
    Component(fc, props) -> component(socket, fc, props)
    SafeHtml(html) -> safe_html(socket, html)
    Raw(text) -> raw(socket, text)
  }
}

fn element(
  socket: Socket,
  tag: String,
  attrs: List(Attribute),
  children: List(Element),
) -> RenderResult(RenderedElement) {
  let RenderResult(socket, rendered_attrs) =
    list.fold(
      attrs,
      RenderResult(socket, []),
      fn(acc, current) {
        let RenderResult(socket, rendered_attrs) = acc

        case current {
          Attribute(name, value) -> {
            let assert Ok(value) = dynamic.string(value)
            RenderResult(
              socket,
              [RenderedAttribute(name, value), ..rendered_attrs],
            )
          }

          Key(key) -> {
            RenderResult(socket, [RenderedKey(key), ..rendered_attrs])
          }

          Event(kind, identifiable_cb) -> {
            let #(socket, id) =
              socket.push_event_handler(socket, identifiable_cb)
            RenderResult(
              socket,
              [RenderedEventHandler(kind, id), ..rendered_attrs],
            )
          }
        }
      },
    )

  let RenderResult(socket, children) =
    children
    |> list.fold(
      RenderResult(socket, []),
      fn(acc, child) {
        let RenderResult(socket, rendered) = acc

        let RenderResult(socket, rendered_child) = live_render(socket, child)
        RenderResult(socket, [rendered_child, ..rendered])
      },
    )

  let maybe_key =
    list.find_map(
      rendered_attrs,
      fn(attr) {
        case attr {
          RenderedKey(key) -> Ok(key)
          _ -> Error(Nil)
        }
      },
    )
    |> option.from_result()

  RenderResult(
    socket,
    RenderedElement(
      tag,
      maybe_key,
      list.reverse(rendered_attrs),
      list.reverse(children),
    ),
  )
}

fn component(
  socket: Socket,
  fc: AbstractFunctionalComponent,
  props: Dynamic,
) -> RenderResult(RenderedElement) {
  let #(socket, children) = fc(socket, props)

  let RenderResult(socket, children) =
    children
    |> list.fold(
      RenderResult(socket, []),
      fn(acc, child) {
        let RenderResult(socket, rendered) = acc

        let RenderResult(socket, rendered_child) = live_render(socket, child)
        RenderResult(socket, [rendered_child, ..rendered])
      },
    )

  RenderResult(socket, RenderedComponent(fc, props, list.reverse(children)))
}

fn safe_html(socket: Socket, html: String) -> RenderResult(RenderedElement) {
  RenderResult(socket, RenderedText(html))
}

fn raw(socket: Socket, text: String) -> RenderResult(RenderedElement) {
  RenderResult(socket, RenderedText(text))
}
