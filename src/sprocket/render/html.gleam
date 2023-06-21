import gleam/list
import gleam/string_builder.{StringBuilder}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedKey, RenderedText, Renderer,
}
import sprocket/constants.{EventAttrPrefix, KeyAttr, c}

pub fn renderer() -> Renderer(String) {
  Renderer(render: fn(el) { string_builder.to_string(render(el)) })
}

fn render(el: RenderedElement) -> StringBuilder {
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
) -> StringBuilder {
  let rendered_attrs =
    attrs
    |> list.fold(
      string_builder.new(),
      fn(acc, attr) {
        case attr {
          RenderedAttribute(name, value) -> {
            string_builder.append_builder(
              acc,
              string_builder.from_strings([" ", name, "=\"", value, "\""]),
            )
          }
          RenderedEventHandler(kind, id) -> {
            string_builder.append_builder(
              acc,
              string_builder.from_strings([
                " ",
                c(EventAttrPrefix),
                "-",
                kind,
                "=\"",
                id,
                "\"",
              ]),
            )
          }
          RenderedKey(k) -> {
            string_builder.append_builder(
              acc,
              string_builder.from_strings([" ", c(KeyAttr), "=\"", k, "\""]),
            )
          }
        }
      },
    )

  let inner_html =
    children
    |> list.fold(
      string_builder.new(),
      fn(acc, child) { string_builder.append_builder(acc, render(child)) },
    )

  string_builder.concat([
    string_builder.from_string("<"),
    string_builder.from_string(tag),
    rendered_attrs,
    string_builder.from_string(">"),
    inner_html,
    string_builder.from_string("</"),
    string_builder.from_string(tag),
    string_builder.from_string(">"),
  ])
}

fn component(children: List(RenderedElement)) {
  children
  |> list.fold(
    string_builder.new(),
    fn(acc, child) { string_builder.append_builder(acc, render(child)) },
  )
}

fn text(t: String) -> StringBuilder {
  string_builder.from_string(t)
}
