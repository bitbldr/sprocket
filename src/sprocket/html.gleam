import gleam/list
import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import gleam/string
import gleam/string_builder
import sprocket/internal/element.{Debug, Element, Keyed, Raw, SafeHtml}
import sprocket/html/attribute.{Attribute}

pub type Children =
  List(Element)

pub fn el(tag: String, attrs: List(Attribute), children: Children) {
  Element(tag, attrs, children)
}

pub fn dangerous_raw_html(html: String) {
  Raw(html)
}

fn safe_replace_char(key: String) -> String {
  case key {
    "&" -> "&amp;"
    "<" -> "&lt;"
    ">" -> "&gt;"
    "\"" -> "&quot;"
    "'" -> "&#39;"
    "/" -> "&#x2F;"
    "`" -> "&#x60;"
    "=" -> "&#x3D;"
    _ -> key
  }
}

fn escape_html(unsafe: String) {
  string.to_graphemes(unsafe)
  |> list.fold(
    string_builder.new(),
    fn(sb, grapheme) { string_builder.append(sb, safe_replace_char(grapheme)) },
  )
  |> string_builder.to_string
  |> SafeHtml
}

pub fn text(text: String) -> Element {
  // safely escape any html text
  escape_html(text)
}

pub fn keyed(key: String, element: Element) {
  Keyed(key, element)
}

pub fn debug(id: String, meta: Option(Dynamic), element: Element) {
  Debug(id, meta, element)
}

pub fn html(attrs: List(Attribute), children: Children) {
  el("html", attrs, children)
}

pub fn head(attrs: List(Attribute), children: Children) {
  el("head", attrs, children)
}

pub fn meta(attrs: List(Attribute)) {
  el("meta", attrs, [])
}

pub fn link(attrs: List(Attribute)) {
  el("link", attrs, [])
}

pub fn script(attrs: List(Attribute), body: Option(String)) {
  case body {
    Some(body) -> el("script", attrs, [text(body)])
    None -> el("script", attrs, [])
  }
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

pub fn i(attrs: List(Attribute), children: Children) {
  el("i", attrs, children)
}

pub fn button(attrs: List(Attribute), children: Children) {
  el("button", attrs, children)
}

pub fn h1(attrs: List(Attribute), children: Children) {
  el("h1", attrs, children)
}

pub fn p(attrs: List(Attribute), children: Children) {
  el("p", attrs, children)
}

pub fn a(attrs: List(Attribute), children: Children) {
  el("a", attrs, children)
}

pub fn input(attrs: List(Attribute)) {
  el("input", attrs, [])
}

pub fn aside(attrs: List(Attribute), children: Children) {
  el("aside", attrs, children)
}
