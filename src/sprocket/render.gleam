import gleam/list
import gleam/string
import sprocket/component.{
  Component, ComponentContext, Element, Hook, RawHtml, StateValue,
}
import sprocket/html/attrs.{HtmlAttr, Key}

pub type RenderContext {
  RenderContext(
    push_hook: fn(Hook) -> Hook,
    fetch_hook: fn(Int) -> Result(Hook, Nil),
    pop_hook_index: fn() -> Int,
    state_updater: fn(Int) -> fn(StateValue) -> StateValue,
  )
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
  fc(ComponentContext(
    push_hook: rcx.push_hook,
    fetch_hook: rcx.fetch_hook,
    pop_hook_index: rcx.pop_hook_index,
    state_updater: rcx.state_updater,
  ))
  |> list.map(fn(child) { render(child, rcx) })
  |> string.concat
}
