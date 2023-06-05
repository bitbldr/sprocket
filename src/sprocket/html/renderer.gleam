import gleam/list
import gleam/string
import gleam/dynamic.{Dynamic}
import sprocket/html/attribute.{Attribute, Event, Key}
import sprocket/socket.{Element, RenderedResult, Socket}
import sprocket/render.{Renderer}

pub fn renderer() -> Renderer(String) {
  Renderer(element: element, component: component, raw: raw)
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
        let RenderedResult(socket, rendered) =
          render.live_render(acc.socket, child, renderer())
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
      let RenderedResult(socket, rendered) =
        render.live_render(acc.socket, child, renderer())
      RenderedResult(socket, string.concat([acc.rendered, rendered]))
    },
  )
}

fn raw(socket: Socket, text: String) -> RenderedResult(String) {
  RenderedResult(socket, text)
}
