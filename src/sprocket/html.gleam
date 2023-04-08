import gleam/list
import gleam/string
import sprocket/component.{Component, Element, raw}
import sprocket/render.{render}
import sprocket/html/attrs.{HtmlAttr, Key}

pub type Children =
  List(Element)

pub fn el(tag: String, attrs: List(HtmlAttr), children: Children) {
  Component(fn(ctx) {
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

    [
      ["<", tag, rendered_attrs, ">", inner_html, "</", tag, ">"]
      |> string.concat()
      |> raw(),
    ]
  })
}

pub fn text(text: String) -> Element {
  // TODO: should html escape text coming into this function
  raw(text)
}

pub type HtmlProps {
  HtmlProps
}

pub fn html(attrs: List(HtmlAttr), children: Children) {
  el("html", attrs, children)
}

pub fn body(attrs: List(HtmlAttr), children: Children) {
  el("body", attrs, children)
}

pub fn div(attrs: List(HtmlAttr), children: Children) {
  el("div", attrs, children)
}

pub fn h1(attrs: List(HtmlAttr), children: Children) {
  el("h1", attrs, children)
}
