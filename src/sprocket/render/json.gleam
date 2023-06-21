import gleam/int
import gleam/list
import gleam/string
import gleam/json.{Json}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedKey, RenderedText, Renderer,
}
import sprocket/constants.{EventAttrPrefix, KeyAttr, c}

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
          #(string.concat([c(EventAttrPrefix), "-", kind]), json.string(id))
        }
        RenderedKey(k) -> {
          #(c(KeyAttr), json.string(k))
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
