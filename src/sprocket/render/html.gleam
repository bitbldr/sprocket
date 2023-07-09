import gleam/list
import gleam/option.{None, Option, Some}
import gleam/string_builder.{StringBuilder}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedText, Renderer,
}
import sprocket/constants.{EventAttrPrefix, KeyAttr, const_str}

pub fn renderer() -> Renderer(String) {
  Renderer(render: fn(el) { string_builder.to_string(render(el)) })
}

fn render(el: RenderedElement) -> StringBuilder {
  case el {
    RenderedElement(tag: tag, key: key, attrs: attrs, children: children) ->
      element(tag, key, attrs, children)
    RenderedComponent(children: children, ..) -> component(children)
    RenderedText(text: t) -> text(t)
  }
}

fn element(
  tag: String,
  key: Option(String),
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
                const_str(EventAttrPrefix),
                "-",
                kind,
                "=\"",
                id,
                "\"",
              ]),
            )
          }
        }
      },
    )

  let rendered_attrs = case key {
    Some(k) ->
      string_builder.append_builder(
        rendered_attrs,
        string_builder.from_strings([" ", const_str(KeyAttr), "=\"", k, "\""]),
      )
    None -> rendered_attrs
  }

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
