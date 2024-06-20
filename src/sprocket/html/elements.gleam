import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/option.{type Option, None, Some}
import sprocket/context.{
  type Attribute, type Element, Custom, Debug, Element, Fragment, IgnoreUpdate,
  Keyed, Text,
}

pub fn el(tag: String, attrs: List(Attribute), children: List(Element)) {
  Element(tag, attrs, children)
}

pub fn raw(tag: String, html: String) {
  let data =
    [#("tag", json.string(tag)), #("innerHtml", json.string(html))]
    |> json.object()
    |> json.to_string()

  Custom("raw", data)
}

pub fn fragment(children: List(Element)) {
  Fragment(children)
}

pub fn text(text: String) -> Element {
  Text(text)
}

pub fn keyed(key: String, element: Element) {
  Keyed(key, element)
}

pub fn ignore(element: Element) {
  IgnoreUpdate(element)
}

pub fn ignore_while(expr: Bool, element: Element) {
  case expr {
    True -> IgnoreUpdate(element)
    False -> element
  }
}

pub fn debug(id: String, meta: Option(Dynamic), element: Element) {
  Debug(id, meta, element)
}

/// The [HTML `<html>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/html)
pub fn html(attrs: List(Attribute), children: List(Element)) {
  el("html", attrs, children)
}

/// The [HTML `<head>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/head)
pub fn head(attrs: List(Attribute), children: List(Element)) {
  el("head", attrs, children)
}

/// The [HTML `<body>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/body)
pub fn body(attrs: List(Attribute), children: List(Element)) {
  el("body", attrs, children)
}

/// The [HTML `<script>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script)
pub fn script(attrs: List(Attribute), body: Option(String)) {
  case body {
    Some(body) -> el("script", attrs, [text(body)])
    None -> el("script", attrs, [])
  }
}

/// The [HTML `<style>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/style)
pub fn style(attrs: List(Attribute), body: Option(String)) {
  case body {
    Some(body) -> el("style", attrs, [text(body)])
    None -> el("style", attrs, [])
  }
}

// Functions below are based on Nakai https://github.com/nakaixo/nakai
// If we could use Nakai directly that would be ideal, but it's not generic or compatible with the
// Sprocket Element type and wrapping in a hiher-level type would be too cumbersome to use.

/// The HTML [`<title>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/title) element
pub fn title(title: String) -> Element {
  el("title", [], [text(title)])
}

/// The [HTML `<a>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a)
pub fn a(attrs: List(Attribute), children: List(Element)) -> Element {
  el("a", attrs, children)
}

/// Shorthand for `html.a(attrs, children: [html.text(text)])`
pub fn a_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("a", attrs, [text(inner_text)])
}

/// The [HTML `<abbr>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/abbr)
pub fn abbr(attrs: List(Attribute), children: List(Element)) -> Element {
  el("abbr", attrs, children)
}

/// The [HTML `<address>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/address)
pub fn address(attrs: List(Attribute), children: List(Element)) -> Element {
  el("address", attrs, children)
}

/// The [HTML `<area />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/area)
pub fn area(attrs: List(Attribute)) -> Element {
  el("area", attrs, [])
}

/// The [HTML `<article>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/article)
pub fn article(attrs: List(Attribute), children: List(Element)) -> Element {
  el("article", attrs, children)
}

/// Shorthand for `html.article(attrs, children: [html.text(text)])`
pub fn article_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("article", attrs, [text(inner_text)])
}

/// The [HTML `<aside>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/aside)
pub fn aside(attrs: List(Attribute), children: List(Element)) -> Element {
  el("aside", attrs, children)
}

/// Shorthand for `html.aside(attrs, children: [html.text(text)])`
pub fn aside_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("aside", attrs, [text(inner_text)])
}

/// The [HTML `<audio>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/audio)
pub fn audio(attrs: List(Attribute), children: List(Element)) -> Element {
  el("audio", attrs, children)
}

/// Shorthand for `html.audio(attrs, children: [html.text(text)])`
pub fn audio_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("audio", attrs, [text(inner_text)])
}

/// The [HTML `<b>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/b)
pub fn b(attrs: List(Attribute), children: List(Element)) -> Element {
  el("b", attrs, children)
}

/// Shorthand for `html.b(attrs, children: [html.text(text)])`
pub fn b_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("b", attrs, [text(inner_text)])
}

/// The [HTML `<base />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base)
pub fn base(attrs: List(Attribute)) -> Element {
  el("base", attrs, [])
}

/// The [HTML `<bdi>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/bdi)
pub fn bdi(attrs: List(Attribute), children: List(Element)) -> Element {
  el("bdi", attrs, children)
}

/// Shorthand for `html.bdi(attrs, children: [html.text(text)])`
pub fn bdi_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("bdi", attrs, [text(inner_text)])
}

/// The [HTML `<bdo>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/bdo)
pub fn bdo(attrs: List(Attribute), children: List(Element)) -> Element {
  el("bdo", attrs, children)
}

/// Shorthand for `html.bdo(attrs, children: [html.text(text)])`
pub fn bdo_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("bdo", attrs, [text(inner_text)])
}

/// The [HTML `<blockquote>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/blockquote)
pub fn blockquote(attrs: List(Attribute), children: List(Element)) -> Element {
  el("blockquote", attrs, children)
}

/// Shorthand for `html.blockquote(attrs, children: [html.text(text)])`
pub fn blockquote_text(
  attrs: List(Attribute),
  text inner_text: String,
) -> Element {
  el("blockquote", attrs, [text(inner_text)])
}

/// The [HTML `<br />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/br)
pub fn br(attrs: List(Attribute)) -> Element {
  el("br", attrs, [])
}

/// The [HTML `<button>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button)
pub fn button(attrs: List(Attribute), children: List(Element)) -> Element {
  el("button", attrs, children)
}

/// Shorthand for `html.button(attrs, children: [html.text(text)])`
pub fn button_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("button", attrs, [text(inner_text)])
}

/// The [HTML `<canvas>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/canvas)
pub fn canvas(attrs: List(Attribute), children: List(Element)) -> Element {
  el("canvas", attrs, children)
}

/// Shorthand for `html.canvas(attrs, children: [html.text(text)])`
pub fn canvas_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("canvas", attrs, [text(inner_text)])
}

/// The [HTML `<caption>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/caption)
pub fn caption(attrs: List(Attribute), children: List(Element)) -> Element {
  el("caption", attrs, children)
}

/// Shorthand for `html.caption(attrs, children: [html.text(text)])`
pub fn caption_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("caption", attrs, [text(inner_text)])
}

/// The [HTML `<cite>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/cite)
pub fn cite(attrs: List(Attribute), children: List(Element)) -> Element {
  el("cite", attrs, children)
}

/// Shorthand for `html.cite(attrs, children: [html.text(text)])`
pub fn cite_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("cite", attrs, [text(inner_text)])
}

/// The [HTML `<code>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/code)
pub fn code(attrs: List(Attribute), children: List(Element)) -> Element {
  el("code", attrs, children)
}

/// Shorthand for `html.code(attrs, children: [html.text(text)])`
pub fn code_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("code", attrs, [text(inner_text)])
}

/// The [HTML `<col>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/col)
pub fn col(attrs: List(Attribute), children: List(Element)) -> Element {
  el("col", attrs, children)
}

/// Shorthand for `html.col(attrs, children: [html.text(text)])`
pub fn col_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("col", attrs, [text(inner_text)])
}

/// The [HTML `<colgroup>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/colgroup)
pub fn colgroup(attrs: List(Attribute), children: List(Element)) -> Element {
  el("colgroup", attrs, children)
}

/// Shorthand for `html.colgroup(attrs, children: [html.text(text)])`
pub fn colgroup_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("colgroup", attrs, [text(inner_text)])
}

/// The [HTML `<data>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/data)
pub fn data(attrs: List(Attribute), children: List(Element)) -> Element {
  el("data", attrs, children)
}

/// Shorthand for `html.data(attrs, children: [html.text(text)])`
pub fn data_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("data", attrs, [text(inner_text)])
}

/// The [HTML `<datalist>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/datalist)
pub fn datalist(attrs: List(Attribute), children: List(Element)) -> Element {
  el("datalist", attrs, children)
}

/// Shorthand for `html.datalist(attrs, children: [html.text(text)])`
pub fn datalist_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("datalist", attrs, [text(inner_text)])
}

/// The [HTML `<dd>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dd)
pub fn dd(attrs: List(Attribute), children: List(Element)) -> Element {
  el("dd", attrs, children)
}

/// Shorthand for `html.dd(attrs, children: [html.text(text)])`
pub fn dd_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("dd", attrs, [text(inner_text)])
}

/// The [HTML `<del>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/del)
pub fn del(attrs: List(Attribute), children: List(Element)) -> Element {
  el("del", attrs, children)
}

/// Shorthand for `html.del(attrs, children: [html.text(text)])`
pub fn del_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("del", attrs, [text(inner_text)])
}

/// The [HTML `<details>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details)
pub fn details(attrs: List(Attribute), children: List(Element)) -> Element {
  el("details", attrs, children)
}

/// Shorthand for `html.details(attrs, children: [html.text(text)])`
pub fn details_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("details", attrs, [text(inner_text)])
}

/// The [HTML `<dfn>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dfn)
pub fn dfn(attrs: List(Attribute), children: List(Element)) -> Element {
  el("dfn", attrs, children)
}

/// Shorthand for `html.dfn(attrs, children: [html.text(text)])`
pub fn dfn_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("dfn", attrs, [text(inner_text)])
}

/// The [HTML `<dialog>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog)
pub fn dialog(attrs: List(Attribute), children: List(Element)) -> Element {
  el("dialog", attrs, children)
}

/// Shorthand for `html.dialog(attrs, children: [html.text(text)])`
pub fn dialog_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("dialog", attrs, [text(inner_text)])
}

/// The [HTML `<div>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/div)
pub fn div(attrs: List(Attribute), children: List(Element)) -> Element {
  el("div", attrs, children)
}

/// Shorthand for `html.div(attrs, children: [html.text(text)])`
pub fn div_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("div", attrs, [text(inner_text)])
}

/// The [HTML `<dl>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dl)
pub fn dl(attrs: List(Attribute), children: List(Element)) -> Element {
  el("dl", attrs, children)
}

/// Shorthand for `html.dl(attrs, children: [html.text(text)])`
pub fn dl_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("dl", attrs, [text(inner_text)])
}

/// The [HTML `<dt>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dt)
pub fn dt(attrs: List(Attribute), children: List(Element)) -> Element {
  el("dt", attrs, children)
}

/// Shorthand for `html.dt(attrs, children: [html.text(text)])`
pub fn dt_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("dt", attrs, [text(inner_text)])
}

/// The [HTML `<em>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/em)
pub fn em(attrs: List(Attribute), children: List(Element)) -> Element {
  el("em", attrs, children)
}

/// Shorthand for `html.em(attrs, children: [html.text(text)])`
pub fn em_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("em", attrs, [text(inner_text)])
}

/// The [HTML `<embed>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/embed)
pub fn embed(attrs: List(Attribute), children: List(Element)) -> Element {
  el("embed", attrs, children)
}

/// Shorthand for `html.embed(attrs, children: [html.text(text)])`
pub fn embed_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("embed", attrs, [text(inner_text)])
}

/// The [HTML `<fieldset>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fieldset)
pub fn fieldset(attrs: List(Attribute), children: List(Element)) -> Element {
  el("fieldset", attrs, children)
}

/// Shorthand for `html.fieldset(attrs, children: [html.text(text)])`
pub fn fieldset_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("fieldset", attrs, [text(inner_text)])
}

/// The [HTML `<figcaption>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/figcaption)
pub fn figcaption(attrs: List(Attribute), children: List(Element)) -> Element {
  el("figcaption", attrs, children)
}

/// Shorthand for `html.figcaption(attrs, children: [html.text(text)])`
pub fn figcaption_text(
  attrs: List(Attribute),
  text inner_text: String,
) -> Element {
  el("figcaption", attrs, [text(inner_text)])
}

/// The [HTML `<figure>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/figure)
pub fn figure(attrs: List(Attribute), children: List(Element)) -> Element {
  el("figure", attrs, children)
}

/// Shorthand for `html.figure(attrs, children: [html.text(text)])`
pub fn figure_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("figure", attrs, [text(inner_text)])
}

/// The [HTML `<footer>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/footer)
pub fn footer(attrs: List(Attribute), children: List(Element)) -> Element {
  el("footer", attrs, children)
}

/// Shorthand for `html.footer(attrs, children: [html.text(text)])`
pub fn footer_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("footer", attrs, [text(inner_text)])
}

/// The [HTML `<form>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form)
pub fn form(attrs: List(Attribute), children: List(Element)) -> Element {
  el("form", attrs, children)
}

/// Shorthand for `html.form(attrs, children: [html.text(text)])`
pub fn form_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("form", attrs, [text(inner_text)])
}

/// The [HTML `<h1>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h1)
pub fn h1(attrs: List(Attribute), children: List(Element)) -> Element {
  el("h1", attrs, children)
}

/// Shorthand for `html.h1(attrs, children: [html.text(text)])`
pub fn h1_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("h1", attrs, [text(inner_text)])
}

/// The [HTML `<h2>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h2)
pub fn h2(attrs: List(Attribute), children: List(Element)) -> Element {
  el("h2", attrs, children)
}

/// Shorthand for `html.h2(attrs, children: [html.text(text)])`
pub fn h2_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("h2", attrs, [text(inner_text)])
}

/// The [HTML `<h3>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h3)
pub fn h3(attrs: List(Attribute), children: List(Element)) -> Element {
  el("h3", attrs, children)
}

/// Shorthand for `html.h3(attrs, children: [html.text(text)])`
pub fn h3_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("h3", attrs, [text(inner_text)])
}

/// The [HTML `<h4>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h4)
pub fn h4(attrs: List(Attribute), children: List(Element)) -> Element {
  el("h4", attrs, children)
}

/// Shorthand for `html.h4(attrs, children: [html.text(text)])`
pub fn h4_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("h4", attrs, [text(inner_text)])
}

/// The [HTML `<h5>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h5)
pub fn h5(attrs: List(Attribute), children: List(Element)) -> Element {
  el("h5", attrs, children)
}

/// Shorthand for `html.h5(attrs, children: [html.text(text)])`
pub fn h5_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("h5", attrs, [text(inner_text)])
}

/// The [HTML `<h6>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h6)
pub fn h6(attrs: List(Attribute), children: List(Element)) -> Element {
  el("h6", attrs, children)
}

/// Shorthand for `html.h6(attrs, children: [html.text(text)])`
pub fn h6_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("h6", attrs, [text(inner_text)])
}

/// The [HTML `<header>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/header)
pub fn header(attrs: List(Attribute), children: List(Element)) -> Element {
  el("header", attrs, children)
}

/// Shorthand for `html.header(attrs, children: [html.text(text)])`
pub fn header_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("header", attrs, [text(inner_text)])
}

/// The [HTML `<hr />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/hr)
pub fn hr(attrs: List(Attribute)) -> Element {
  el("hr", attrs, [])
}

/// The [HTML `<i>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/i)
pub fn i(attrs: List(Attribute), children: List(Element)) -> Element {
  el("i", attrs, children)
}

/// Shorthand for `html.i(attrs, children: [html.text(text)])`
pub fn i_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("i", attrs, [text(inner_text)])
}

/// The [HTML `<iframe>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe)
pub fn iframe(attrs: List(Attribute), children: List(Element)) -> Element {
  el("iframe", attrs, children)
}

/// Shorthand for `html.iframe(attrs, children: [html.text(text)])`
pub fn iframe_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("iframe", attrs, [text(inner_text)])
}

/// The [HTML `<img />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img)
pub fn img(attrs: List(Attribute)) -> Element {
  el("img", attrs, [])
}

/// The [HTML `<input />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input)
pub fn input(attrs: List(Attribute)) -> Element {
  el("input", attrs, [])
}

/// The [HTML `<ins>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ins)
pub fn ins(attrs: List(Attribute), children: List(Element)) -> Element {
  el("ins", attrs, children)
}

/// Shorthand for `html.ins(attrs, children: [html.text(text)])`
pub fn ins_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("ins", attrs, [text(inner_text)])
}

/// The [HTML `<kbd>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/kbd)
pub fn kbd(attrs: List(Attribute), children: List(Element)) -> Element {
  el("kbd", attrs, children)
}

/// Shorthand for `html.kbd(attrs, children: [html.text(text)])`
pub fn kbd_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("kbd", attrs, [text(inner_text)])
}

/// The [HTML `<label>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/label)
pub fn label(attrs: List(Attribute), children: List(Element)) -> Element {
  el("label", attrs, children)
}

/// Shorthand for `html.label(attrs, children: [html.text(text)])`
pub fn label_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("label", attrs, [text(inner_text)])
}

/// The [HTML `<legend>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/legend)
pub fn legend(attrs: List(Attribute), children: List(Element)) -> Element {
  el("legend", attrs, children)
}

/// Shorthand for `html.legend(attrs, children: [html.text(text)])`
pub fn legend_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("legend", attrs, [text(inner_text)])
}

/// The [HTML `<li>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/li)
pub fn li(attrs: List(Attribute), children: List(Element)) -> Element {
  el("li", attrs, children)
}

/// Shorthand for `html.li(attrs, children: [html.text(text)])`
pub fn li_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("li", attrs, [text(inner_text)])
}

/// The [HTML `<link />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/link)
pub fn link(attrs: List(Attribute)) -> Element {
  el("link", attrs, [])
}

/// The [HTML `<main>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/main)
pub fn main(attrs: List(Attribute), children: List(Element)) -> Element {
  el("main", attrs, children)
}

/// Shorthand for `html.main(attrs, children: [html.text(text)])`
pub fn main_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("main", attrs, [text(inner_text)])
}

/// The [HTML `<map>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/map)
pub fn map(attrs: List(Attribute), children: List(Element)) -> Element {
  el("map", attrs, children)
}

/// Shorthand for `html.map(attrs, children: [html.text(text)])`
pub fn map_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("map", attrs, [text(inner_text)])
}

/// The [HTML `<mark>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/mark)
pub fn mark(attrs: List(Attribute), children: List(Element)) -> Element {
  el("mark", attrs, children)
}

/// Shorthand for `html.mark(attrs, children: [html.text(text)])`
pub fn mark_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("mark", attrs, [text(inner_text)])
}

/// The [HTML `<math>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/math)
pub fn math(attrs: List(Attribute), children: List(Element)) -> Element {
  el("math", attrs, children)
}

/// Shorthand for `html.math(attrs, children: [html.text(text)])`
pub fn math_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("math", attrs, [text(inner_text)])
}

/// The [HTML `<menu>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/menu)
pub fn menu(attrs: List(Attribute), children: List(Element)) -> Element {
  el("menu", attrs, children)
}

/// Shorthand for `html.menu(attrs, children: [html.text(text)])`
pub fn menu_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("menu", attrs, [text(inner_text)])
}

/// The [HTML `<menuitem>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/menuitem)
pub fn menuitem(attrs: List(Attribute), children: List(Element)) -> Element {
  el("menuitem", attrs, children)
}

/// Shorthand for `html.menuitem(attrs, children: [html.text(text)])`
pub fn menuitem_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("menuitem", attrs, [text(inner_text)])
}

/// The [HTML `<meta />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta)
pub fn meta(attrs: List(Attribute)) -> Element {
  el("meta", attrs, [])
}

/// The [HTML `<meter>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meter)
pub fn meter(attrs: List(Attribute), children: List(Element)) -> Element {
  el("meter", attrs, children)
}

/// Shorthand for `html.meter(attrs, children: [html.text(text)])`
pub fn meter_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("meter", attrs, [text(inner_text)])
}

/// The [HTML `<nav>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/nav)
pub fn nav(attrs: List(Attribute), children: List(Element)) -> Element {
  el("nav", attrs, children)
}

/// Shorthand for `html.nav(attrs, children: [html.text(text)])`
pub fn nav_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("nav", attrs, [text(inner_text)])
}

/// The [HTML `<noscript>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/noscript)
pub fn noscript(attrs: List(Attribute), children: List(Element)) -> Element {
  el("noscript", attrs, children)
}

/// Shorthand for `html.noscript(attrs, children: [html.text(text)])`
pub fn noscript_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("noscript", attrs, [text(inner_text)])
}

/// The [HTML `<object>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object)
pub fn object(attrs: List(Attribute), children: List(Element)) -> Element {
  el("object", attrs, children)
}

/// Shorthand for `html.object(attrs, children: [html.text(text)])`
pub fn object_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("object", attrs, [text(inner_text)])
}

/// The [HTML `<ol>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ol)
pub fn ol(attrs: List(Attribute), children: List(Element)) -> Element {
  el("ol", attrs, children)
}

/// Shorthand for `html.ol(attrs, children: [html.text(text)])`
pub fn ol_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("ol", attrs, [text(inner_text)])
}

/// The [HTML `<optgroup>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/optgroup)
pub fn optgroup(attrs: List(Attribute), children: List(Element)) -> Element {
  el("optgroup", attrs, children)
}

/// Shorthand for `html.optgroup(attrs, children: [html.text(text)])`
pub fn optgroup_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("optgroup", attrs, [text(inner_text)])
}

/// The [HTML `<option>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/option)
pub fn option(attrs: List(Attribute), children: List(Element)) -> Element {
  el("option", attrs, children)
}

/// Shorthand for `html.option(attrs, children: [html.text(text)])`
pub fn option_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("option", attrs, [text(inner_text)])
}

/// The [HTML `<output>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/output)
pub fn output(attrs: List(Attribute), children: List(Element)) -> Element {
  el("output", attrs, children)
}

/// Shorthand for `html.output(attrs, children: [html.text(text)])`
pub fn output_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("output", attrs, [text(inner_text)])
}

/// The [HTML `<p>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/p)
pub fn p(attrs: List(Attribute), children: List(Element)) -> Element {
  el("p", attrs, children)
}

/// Shorthand for `html.p(attrs, children: [html.text(text)])`
pub fn p_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("p", attrs, [text(inner_text)])
}

/// The [HTML `<param>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/param)
pub fn param(attrs: List(Attribute), children: List(Element)) -> Element {
  el("param", attrs, children)
}

/// Shorthand for `html.param(attrs, children: [html.text(text)])`
pub fn param_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("param", attrs, [text(inner_text)])
}

/// The [HTML `<picture>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture)
pub fn picture(attrs: List(Attribute), children: List(Element)) -> Element {
  el("picture", attrs, children)
}

/// Shorthand for `html.picture(attrs, children: [html.text(text)])`
pub fn picture_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("picture", attrs, [text(inner_text)])
}

/// The [HTML `<pre>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/pre)
pub fn pre(attrs: List(Attribute), children: List(Element)) -> Element {
  el("pre", attrs, children)
}

/// Shorthand for `html.pre(attrs, children: [html.text(text)])`
pub fn pre_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("pre", attrs, [text(inner_text)])
}

/// The [HTML `<progress>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/progress)
pub fn progress(attrs: List(Attribute), children: List(Element)) -> Element {
  el("progress", attrs, children)
}

/// Shorthand for `html.progress(attrs, children: [html.text(text)])`
pub fn progress_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("progress", attrs, [text(inner_text)])
}

/// The [HTML `<q>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/q)
pub fn q(attrs: List(Attribute), children: List(Element)) -> Element {
  el("q", attrs, children)
}

/// Shorthand for `html.q(attrs, children: [html.text(text)])`
pub fn q_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("q", attrs, [text(inner_text)])
}

/// The [HTML `<rp>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/rp)
pub fn rp(attrs: List(Attribute), children: List(Element)) -> Element {
  el("rp", attrs, children)
}

/// Shorthand for `html.rp(attrs, children: [html.text(text)])`
pub fn rp_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("rp", attrs, [text(inner_text)])
}

/// The [HTML `<rt>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/rt)
pub fn rt(attrs: List(Attribute), children: List(Element)) -> Element {
  el("rt", attrs, children)
}

/// Shorthand for `html.rt(attrs, children: [html.text(text)])`
pub fn rt_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("rt", attrs, [text(inner_text)])
}

/// The [HTML `<ruby>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ruby)
pub fn ruby(attrs: List(Attribute), children: List(Element)) -> Element {
  el("ruby", attrs, children)
}

/// Shorthand for `html.ruby(attrs, children: [html.text(text)])`
pub fn ruby_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("ruby", attrs, [text(inner_text)])
}

/// The [HTML `<s>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/s)
pub fn s(attrs: List(Attribute), children: List(Element)) -> Element {
  el("s", attrs, children)
}

/// Shorthand for `html.s(attrs, children: [html.text(text)])`
pub fn s_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("s", attrs, [text(inner_text)])
}

/// The [HTML `<samp>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/samp)
pub fn samp(attrs: List(Attribute), children: List(Element)) -> Element {
  el("samp", attrs, children)
}

/// Shorthand for `html.samp(attrs, children: [html.text(text)])`
pub fn samp_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("samp", attrs, [text(inner_text)])
}

/// The [HTML `<section>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/section)
pub fn section(attrs: List(Attribute), children: List(Element)) -> Element {
  el("section", attrs, children)
}

/// Shorthand for `html.section(attrs, children: [html.text(text)])`
pub fn section_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("section", attrs, [text(inner_text)])
}

/// The [HTML `<select>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select)
pub fn select(attrs: List(Attribute), children: List(Element)) -> Element {
  el("select", attrs, children)
}

/// Shorthand for `html.select(attrs, children: [html.text(text)])`
pub fn select_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("select", attrs, [text(inner_text)])
}

/// The [HTML `<small>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/small)
pub fn small(attrs: List(Attribute), children: List(Element)) -> Element {
  el("small", attrs, children)
}

/// Shorthand for `html.small(attrs, children: [html.text(text)])`
pub fn small_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("small", attrs, [text(inner_text)])
}

/// The [HTML `<source />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/source)
pub fn source(attrs: List(Attribute)) -> Element {
  el("source", attrs, [])
}

/// The [HTML `<span>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/span)
pub fn span(attrs: List(Attribute), children: List(Element)) -> Element {
  el("span", attrs, children)
}

/// Shorthand for `html.span(attrs, children: [html.text(text)])`
pub fn span_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("span", attrs, [text(inner_text)])
}

/// The [HTML `<strong>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/strong)
pub fn strong(attrs: List(Attribute), children: List(Element)) -> Element {
  el("strong", attrs, children)
}

/// Shorthand for `html.strong(attrs, children: [html.text(text)])`
pub fn strong_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("strong", attrs, [text(inner_text)])
}

/// The [HTML `<sub>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/sub)
pub fn sub(attrs: List(Attribute), children: List(Element)) -> Element {
  el("sub", attrs, children)
}

/// Shorthand for `html.sub(attrs, children: [html.text(text)])`
pub fn sub_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("sub", attrs, [text(inner_text)])
}

/// The [HTML `<summary>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/summary)
pub fn summary(attrs: List(Attribute), children: List(Element)) -> Element {
  el("summary", attrs, children)
}

/// Shorthand for `html.summary(attrs, children: [html.text(text)])`
pub fn summary_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("summary", attrs, [text(inner_text)])
}

/// The [HTML `<sup>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/sup)
pub fn sup(attrs: List(Attribute), children: List(Element)) -> Element {
  el("sup", attrs, children)
}

/// Shorthand for `html.sup(attrs, children: [html.text(text)])`
pub fn sup_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("sup", attrs, [text(inner_text)])
}

/// The [HTML `<svg>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/svg)
pub fn svg(attrs: List(Attribute), children: List(Element)) -> Element {
  el("svg", attrs, children)
}

/// Shorthand for `html.svg(attrs, children: [html.text(text)])`
pub fn svg_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("svg", attrs, [text(inner_text)])
}

/// The [HTML `<table>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/table)
pub fn table(attrs: List(Attribute), children: List(Element)) -> Element {
  el("table", attrs, children)
}

/// Shorthand for `html.table(attrs, children: [html.text(text)])`
pub fn table_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("table", attrs, [text(inner_text)])
}

/// The [HTML `<tbody>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tbody)
pub fn tbody(attrs: List(Attribute), children: List(Element)) -> Element {
  el("tbody", attrs, children)
}

/// Shorthand for `html.tbody(attrs, children: [html.text(text)])`
pub fn tbody_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("tbody", attrs, [text(inner_text)])
}

/// The [HTML `<td>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/td)
pub fn td(attrs: List(Attribute), children: List(Element)) -> Element {
  el("td", attrs, children)
}

/// Shorthand for `html.td(attrs, children: [html.text(text)])`
pub fn td_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("td", attrs, [text(inner_text)])
}

/// The [HTML `<textarea>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea)
pub fn textarea(attrs: List(Attribute), children: List(Element)) -> Element {
  el("textarea", attrs, children)
}

/// Shorthand for `html.textarea(attrs, children: [html.text(text)])`
pub fn textarea_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("textarea", attrs, [text(inner_text)])
}

/// The [HTML `<tfoot>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tfoot)
pub fn tfoot(attrs: List(Attribute), children: List(Element)) -> Element {
  el("tfoot", attrs, children)
}

/// Shorthand for `html.tfoot(attrs, children: [html.text(text)])`
pub fn tfoot_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("tfoot", attrs, [text(inner_text)])
}

/// The [HTML `<th>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/th)
pub fn th(attrs: List(Attribute), children: List(Element)) -> Element {
  el("th", attrs, children)
}

/// Shorthand for `html.th(attrs, children: [html.text(text)])`
pub fn th_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("th", attrs, [text(inner_text)])
}

/// The [HTML `<thead>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/thead)
pub fn thead(attrs: List(Attribute), children: List(Element)) -> Element {
  el("thead", attrs, children)
}

/// Shorthand for `html.thead(attrs, children: [html.text(text)])`
pub fn thead_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("thead", attrs, [text(inner_text)])
}

/// The [HTML `<time>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/time)
pub fn time(attrs: List(Attribute), children: List(Element)) -> Element {
  el("time", attrs, children)
}

/// Shorthand for `html.time(attrs, children: [html.text(text)])`
pub fn time_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("time", attrs, [text(inner_text)])
}

/// The [HTML `<tr>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/tr)
pub fn tr(attrs: List(Attribute), children: List(Element)) -> Element {
  el("tr", attrs, children)
}

/// Shorthand for `html.tr(attrs, children: [html.text(text)])`
pub fn tr_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("tr", attrs, [text(inner_text)])
}

/// The [HTML `<track />` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/track)
pub fn track(attrs: List(Attribute)) -> Element {
  el("track", attrs, [])
}

/// The [HTML `<u>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/u)
pub fn u(attrs: List(Attribute), children: List(Element)) -> Element {
  el("u", attrs, children)
}

/// Shorthand for `html.u(attrs, children: [html.text(text)])`
pub fn u_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("u", attrs, [text(inner_text)])
}

/// The [HTML `<ul>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ul)
pub fn ul(attrs: List(Attribute), children: List(Element)) -> Element {
  el("ul", attrs, children)
}

/// Shorthand for `html.ul(attrs, children: [html.text(text)])`
pub fn ul_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("ul", attrs, [text(inner_text)])
}

/// The [HTML `<var>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/var)
pub fn var(attrs: List(Attribute), children: List(Element)) -> Element {
  el("var", attrs, children)
}

/// Shorthand for `html.var(attrs, children: [html.text(text)])`
pub fn var_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("var", attrs, [text(inner_text)])
}

/// The [HTML `<video>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video)
pub fn video(attrs: List(Attribute), children: List(Element)) -> Element {
  el("video", attrs, children)
}

/// Shorthand for `html.video(attrs, children: [html.text(text)])`
pub fn video_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("video", attrs, [text(inner_text)])
}

/// The [HTML `<wbr>` element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/wbr)
pub fn wbr(attrs: List(Attribute), children: List(Element)) -> Element {
  el("wbr", attrs, children)
}

/// Shorthand for `html.wbr(attrs, children: [html.text(text)])`
pub fn wbr_text(attrs: List(Attribute), text inner_text: String) -> Element {
  el("wbr", attrs, [text(inner_text)])
}
