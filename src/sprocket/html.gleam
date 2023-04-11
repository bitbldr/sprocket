import sprocket/component.{Element, raw}
import sprocket/html/attrs.{HtmlAttr}

pub type Children =
  List(Element)

pub fn el(tag: String, attrs: List(HtmlAttr), children: Children) {
  Element(tag, attrs, children)
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

pub fn span(attrs: List(HtmlAttr), children: Children) {
  el("span", attrs, children)
}

pub fn button(attrs: List(HtmlAttr), children: Children) {
  el("button", attrs, children)
}

pub fn h1(attrs: List(HtmlAttr), children: Children) {
  el("h1", attrs, children)
}
