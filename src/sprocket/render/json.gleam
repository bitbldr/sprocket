import gleam/int
import gleam/list
import gleam/string
import gleam/json.{Json}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedKey, RenderedText, Renderer,
}

pub fn renderer() -> Renderer(Json) {
  Renderer(render: fn(el) { render(el) })
}

fn render(el: RenderedElement) -> Json {
  case el {
    RenderedElement(tag: tag, key: _key, attrs: attrs, children: children) ->
      element(tag, attrs, children)
    RenderedComponent(children: children, ..) -> component(children)
    RenderedText(text: t) -> text(t)
  }
}

fn element(
  tag: String,
  attrs: List(RenderedAttribute),
  children: List(RenderedElement),
) -> Json {
  let attrs =
    attrs
    |> list.map(fn(attr) {
      case attr {
        RenderedAttribute(name, value) -> {
          #(name, json.string(value))
        }
        RenderedEventHandler(kind, id) -> {
          #("live-event", json.string(string.concat([kind, "=", id])))
        }
        RenderedKey(k) -> {
          #("live-key", json.string(k))
        }
      }
    })

  let children =
    children
    |> list.index_map(fn(i, child) { #(int.to_string(i), render(child)) })

  [#("type", json.string(tag)), #("attrs", json.object(attrs))]
  |> list.append(children)
  |> json.object()
}

fn component(children: List(RenderedElement)) -> Json {
  let children =
    children
    |> list.index_map(fn(i, child) { #(int.to_string(i), render(child)) })

  [#("type", json.string("component"))]
  |> list.append(children)
  |> json.object()
}

fn text(t: String) -> Json {
  json.string(t)
}
// /////////////

// import gleam/list
// import gleam/map.{Map}
// import gleam/string
// import gleam/string_builder
// import gleam/dynamic.{Dynamic}
// import sprocket/html/attribute.{Attribute, Event, Key}
// import sprocket/socket.{Element, RenderedResult, Socket}
// import sprocket/render.{Renderer}
// import sprocket/diff.{DiffElement}

// fn to_update_json(el: HtmlSafeElement) -> String {
//   case el {
//     HtmlSafeElement(tag, attrs) -> {
//       let children = list.map(attrs, fn(attr) {
//         let (key, value) = attr
//         object([
//           ("key", string(key)),
//           ("value", string(value)),
//         ])
//       })
//       object([
//         #("type", string("Pac-Man")),
//         #("score", int(3333360)),
//       ])
//     }
//     HtmlSafeText(s) -> {
//       string.concat(["{t:", s, "}"])
//     }
//   }
// }

// fn safe_replace_char(key: String) -> String {
//   case key {
//     "&" -> "&amp;"
//     "<" -> "&lt;"
//     ">" -> "&gt;"
//     "\"" -> "&quot;"
//     "'" -> "&#39;"
//     "/" -> "&#x2F;"
//     "`" -> "&#x60;"
//     "=" -> "&#x3D;"
//     _ -> key
//   }
// }

// // TODO: use to safely esacpe all html strings
// fn escape_html(unsafe: String) -> String {
//   string.to_graphemes(unsafe)
//   |> list.fold(
//     string_builder.new(),
//     fn(grapheme, sb) { string_builder.append(sb, safe_replace_char(grapheme)) },
//   )
//   |> list.map(safe_replace_char)
// }
