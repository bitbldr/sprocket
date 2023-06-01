import gleam/list
import gleam/string
import sprocket/component.{Component, ComponentContext, Element, RawHtml}
import sprocket/html/attribute.{Attribute, Event, Key}
import gleam/dynamic
import sprocket/socket.{Socket}

pub fn render(el: Element, socket: Socket) -> String {
  // TODO: render_count > SOME_THRESHOLD then panic("Possible infinite rerender loop")

  let rendered = case el {
    Element(tag, attrs, children) -> element(tag, attrs, children, socket)
    Component(c) -> component(c, socket)
    RawHtml(raw_html) -> raw_html
  }

  rendered
}

fn element(
  tag: String,
  attrs: List(Attribute),
  children: List(Element),
  socket: Socket,
) {
  let rendered_attrs =
    list.fold(
      attrs,
      "",
      fn(acc, a) {
        case a {
          Attribute(name, value) -> {
            let assert Ok(value) = dynamic.string(value)
            string.concat([acc, " ", name, "=\"", value, "\""])
          }

          Key(k) -> string.concat([acc, " key=\"", k, "\""])

          Event(name, handler) -> {
            let id = socket.push_event_handler(handler)
            string.concat([acc, " data-event=\"", name, "=", id, "\""])
          }
        }
      },
    )

  let inner_html =
    children
    |> list.map(fn(child) { render(child, socket) })
    |> string.concat

  ["<", tag, rendered_attrs, ">", inner_html, "</", tag, ">"]
  |> string.concat()
}

fn component(fc: fn(ComponentContext) -> List(Element), socket: Socket) {
  fc(ComponentContext(
    fetch_or_create_reducer: socket.fetch_or_create_reducer,
    request_live_update: socket.request_live_update,
    push_hook: socket.push_hook,
  ))
  |> list.map(fn(child) { render(child, socket) })
  |> string.concat
}
