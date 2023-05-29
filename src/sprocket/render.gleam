import gleam/list
import gleam/string
import gleam/option.{Option}
import sprocket/component.{Component,
  ComponentContext, Effect, Element, RawHtml}
import sprocket/html/attribute.{Attribute, Event, Key}
import gleam/dynamic.{Dynamic}

pub type RenderContext {
  RenderContext(
    fetch_or_create_reducer: fn(fn() -> Dynamic) -> Dynamic,
    push_event_handler: fn(fn() -> Nil) -> String,
    render_update: fn() -> Nil,
    get_or_create_effect: fn(Effect) -> Effect,
    update_effect: fn(Effect) -> Nil,
  )
}

pub fn render(el: Element, ctx: RenderContext) -> String {
  case el {
    Element(tag, attrs, children) -> element(tag, attrs, children, ctx)
    Component(c) -> component(c, ctx)
    RawHtml(raw_html) -> raw_html
  }
}

fn element(
  tag: String,
  attrs: List(Attribute),
  children: List(Element),
  ctx: RenderContext,
) {
  let rendered_attrs =
    list.fold(
      attrs,
      "",
      fn(acc, a) {
        case a {
          Attribute(name, value) -> {
            let assert Ok(value) = dynamic.string(value)
            string.concat([acc, " ", name, "=\"", value, "\""])
          }

          Key(k) -> string.concat([acc, " key=\"", k, "\""])

          Event(name, handler) -> {
            let id = ctx.push_event_handler(handler)
            string.concat([acc, " data-event=\"", name, "=", id, "\""])
          }
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

fn component(fc: fn(ComponentContext) -> List(Element), ctx: RenderContext) {
  fc(ComponentContext(
    fetch_or_create_reducer: ctx.fetch_or_create_reducer,
    render_update: ctx.render_update,
    get_or_create_effect: ctx.get_or_create_effect,
    update_effect: ctx.update_effect,
  ))
  |> list.map(fn(child) { render(child, ctx) })
  |> string.concat
}
