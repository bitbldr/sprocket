import gleam/list
import gleam/string
import sprocket/component.{Component, ComponentContext, Element, RawHtml}
import sprocket/html/attrs.{HtmlAttr, Key}

pub fn render(el: Element, ctx: ComponentContext) -> String {
  case el {
    Element(tag, attrs, children) -> render_element(tag, attrs, children, ctx)
    Component(c) -> render_component(c, ctx)
    RawHtml(raw_html) -> raw_html
  }
}

fn render_element(
  tag: String,
  attrs: List(HtmlAttr),
  children: List(Element),
  ctx: ComponentContext,
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
    |> list.map(fn(child) { render(child, ctx) })
    |> string.concat

  ["<", tag, rendered_attrs, ">", inner_html, "</", tag, ">"]
  |> string.concat()
}

fn render_component(
  fc: fn(ComponentContext) -> List(Element),
  ctx: ComponentContext,
) {
  fc(ComponentContext(..ctx, h_index: 0))
  |> list.map(fn(child) { render(child, ctx) })
  |> string.concat
}
