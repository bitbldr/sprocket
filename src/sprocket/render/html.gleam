import gleam/list
import gleam/option.{None, Option, Some}
import gleam/string_builder.{StringBuilder}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedText, Renderer, traverse,
}
import sprocket/constants.{EventAttrPrefix, KeyAttr, constant}
import sprocket/cassette.{Preflight}

pub fn renderer() -> Renderer(String) {
  Renderer(render: fn(el) { string_builder.to_string(render(el)) })
}

pub fn renderer_with_preflight(preflight: Preflight) -> Renderer(String) {
  Renderer(render: fn(el) {
    el
    |> inject_meta(Meta(name: "spkt-preflight-id", content: preflight.id))
    |> render()
    |> string_builder.to_string()
  })
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
                constant(EventAttrPrefix),
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
        string_builder.from_strings([" ", constant(KeyAttr), "=\"", k, "\""]),
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

type Meta {
  Meta(name: String, content: String)
}

fn inject_meta(root: RenderedElement, meta: Meta) -> RenderedElement {
  traverse(
    root,
    fn(el) {
      case el {
        RenderedElement(tag: "head", key: key, attrs: attrs, children: children) -> {
          let meta =
            RenderedElement(
              tag: "meta",
              key: None,
              attrs: [
                RenderedAttribute("name", meta.name),
                RenderedAttribute("content", meta.content),
              ],
              children: [],
            )

          RenderedElement(
            tag: "head",
            key: key,
            attrs: attrs,
            children: list.append(children, [meta]),
          )
        }
        _ -> el
      }
    },
  )
}
