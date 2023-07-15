import gleam/list
import gleam/option.{None, Option, Some}
import gleam/string_builder.{StringBuilder}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedText, Renderer, render_element, traverse,
}
import sprocket/constants.{
  ClientScript, EventAttrPrefix, KeyAttr, MetaPreflightId, constant,
}
import sprocket/cassette.{Preflight}
import sprocket/html.{meta, script}
import sprocket/html/attribute.{content, name, src}

pub fn renderer() -> Renderer(String) {
  Renderer(render: fn(el) { string_builder.to_string(render(el)) })
}

pub fn renderer_with_preflight(preflight: Preflight) -> Renderer(String) {
  let preflight_meta =
    meta([name(constant(MetaPreflightId)), content(preflight.id)])
    |> render_element()

  let sprocket_client =
    script([src(constant(ClientScript))], None)
    |> render_element()

  Renderer(render: fn(el) {
    el
    |> inject_element("head", preflight_meta, Append)
    |> inject_element("body", sprocket_client, Append)
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

type InjectElementOperation {
  Append
  Prepend
}

fn inject_element(
  root: RenderedElement,
  target_tag: String,
  inject_element: RenderedElement,
  insert_op: InjectElementOperation,
) -> RenderedElement {
  // TODO: implement and use a more efficient traverse_util that can stop
  // traversing once it finds the element it's looking for.
  traverse(
    root,
    fn(el) {
      case el {
        RenderedElement(tag: tag, key: key, attrs: attrs, children: children) if tag == target_tag -> {
          RenderedElement(
            tag: target_tag,
            key: key,
            attrs: attrs,
            children: case insert_op {
              Append -> list.append(children, [inject_element])
              Prepend -> [inject_element, ..children]
            },
          )
        }
        _ -> el
      }
    },
  )
}
