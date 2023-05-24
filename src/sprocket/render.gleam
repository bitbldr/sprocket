import gleam/list
import gleam/string
import sprocket/component.{Component, ComponentContext, Element, RawHtml}
import sprocket/html/attrs.{HtmlAttr, Key}
import gleam/dynamic.{Dynamic}

pub type RenderContext {
  RenderContext(fetch_or_create_reducer: fn(fn() -> Dynamic) -> Dynamic)
}

pub fn render(el: Element, rcx: RenderContext) -> String {
  case el {
    Element(tag, attrs, children) -> element(tag, attrs, children, rcx)
    Component(c) -> component(c, rcx)
    RawHtml(raw_html) -> raw_html
  }
}

fn element(
  tag: String,
  attrs: List(HtmlAttr),
  children: List(Element),
  rcx: RenderContext,
) {
  let rendered_attrs =
    list.fold(
      attrs,
      "",
      fn(acc, a) {
        case a {
          HtmlAttr(name, value) ->
            string.concat([acc, " ", name, "=\"", value, "\""])

          Key(k) -> string.concat([acc, " key=\"", k, "\""])
        }
      },
    )

  let inner_html =
    children
    |> list.map(fn(child) { render(child, rcx) })
    |> string.concat

  ["<", tag, rendered_attrs, ">", inner_html, "</", tag, ">"]
  |> string.concat()
}

fn component(fc: fn(ComponentContext) -> List(Element), rcx: RenderContext) {
  fc(ComponentContext(fetch_or_create_reducer: rcx.fetch_or_create_reducer))
  |> list.map(fn(child) { render(child, rcx) })
  |> string.concat
}
