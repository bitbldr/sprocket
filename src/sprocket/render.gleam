import gleam/list
import gleam/string
import gleam/dynamic.{Dynamic}
import sprocket/html/attribute.{Attribute, Event, Key}
import gleam/option.{None}
import sprocket/socket.{Component, Element, Raw, RenderedResult, Socket}

pub fn render(el: Element) -> String {
  let RenderedResult(rendered: rendered, ..) = live_render(socket.new(None), el)

  rendered
}

pub fn live_render(socket: Socket, el: Element) -> RenderedResult(String) {
  // TODO: render_count > SOME_THRESHOLD then panic("Possible infinite rerender loop")

  case el {
    Element(tag, attrs, children) -> element(socket, tag, attrs, children)
    Component(fc, props) -> component(socket, fc, props)
    Raw(text) -> RenderedResult(socket, text)
  }
}

fn element(
  socket: Socket,
  tag: String,
  attrs: List(Attribute),
  children: List(Element),
) -> RenderedResult(String) {
  let RenderedResult(socket, rendered_attrs) =
    list.fold(
      attrs,
      RenderedResult(socket, ""),
      fn(acc, current) {
        let RenderedResult(socket, acc) = acc

        case current {
          Attribute(name, value) -> {
            let assert Ok(value) = dynamic.string(value)
            let rendered = string.concat([acc, " ", name, "=\"", value, "\""])
            RenderedResult(socket, rendered)
          }

          Key(k) -> {
            let rendered = string.concat([acc, " key=\"", k, "\""])
            RenderedResult(socket, rendered)
          }

          Event(name, handler) -> {
            let #(socket, id) = socket.push_event_handler(socket, handler)
            let rendered =
              string.concat([acc, " data-event=\"", name, "=", id, "\""])

            RenderedResult(socket, rendered)
          }
        }
      },
    )

  let RenderedResult(socket, inner_html) =
    children
    |> list.fold(
      RenderedResult(socket, ""),
      fn(acc, child) {
        let RenderedResult(socket, rendered) = live_render(acc.socket, child)
        RenderedResult(socket, string.concat([acc.rendered, rendered]))
      },
    )

  let rendered =
    string.concat(["<", tag, rendered_attrs, ">", inner_html, "</", tag, ">"])

  RenderedResult(socket, rendered)
}

fn component(
  socket: Socket,
  fc: fn(Socket, Dynamic) -> #(Socket, List(Element)),
  props: Dynamic,
) {
  let #(socket, children) = fc(socket, props)

  children
  |> list.fold(
    RenderedResult(socket, ""),
    fn(acc, child) {
      let RenderedResult(socket, rendered) = live_render(acc.socket, child)
      RenderedResult(socket, string.concat([acc.rendered, rendered]))
    },
  )
}
