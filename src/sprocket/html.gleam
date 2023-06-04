import sprocket/socket.{Element, Raw}
import sprocket/html/attribute.{Attribute}

pub type Children =
  List(Element)

pub fn el(tag: String, attrs: List(Attribute), children: Children) {
  Element(tag, attrs, children)
}

pub fn raw(html: String) {
  Raw(html)
}

pub fn text(text: String) -> Element {
  // TODO: should html escape text coming into this function
  raw(text)
}

pub type HtmlProps {
  HtmlProps
}

pub fn html(attrs: List(Attribute), children: Children) {
  el("html", attrs, children)
}

pub fn head(attrs: List(Attribute), children: Children) {
  el("head", attrs, children)
}

pub fn link(attrs: List(Attribute)) {
  el("link", attrs, [])
}

pub fn script(attrs: List(Attribute), children: Children) {
  el("script", attrs, children)
}

pub fn body(attrs: List(Attribute), children: Children) {
  el("body", attrs, children)
}

pub fn div(attrs: List(Attribute), children: Children) {
  el("div", attrs, children)
}

pub fn span(attrs: List(Attribute), children: Children) {
  el("span", attrs, children)
}

pub fn button(attrs: List(Attribute), children: Children) {
  el("button", attrs, children)
}

pub fn h1(attrs: List(Attribute), children: Children) {
  el("h1", attrs, children)
}
