import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string_builder.{type StringBuilder}
import sprocket/render.{
  type RenderedAttribute, type RenderedElement, type Renderer, RenderedAttribute,
  RenderedClientHook, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedText, Renderer, traverse,
}
import sprocket/internal/constants.{
  ClientHookAttrPrefix, EventAttrPrefix, KeyAttr, constant,
}

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
                constant(EventAttrPrefix),
                "-",
                kind,
                "=\"",
                id,
                "\"",
              ]),
            )
          }
          RenderedClientHook(name, id) -> {
            string_builder.append_builder(
              acc,
              string_builder.from_strings([
                " ",
                constant(ClientHookAttrPrefix),
                "=\"",
                name,
                "\" ",
                constant(ClientHookAttrPrefix),
                "-id=\"",
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
  // TODO: implement and use a more efficient traverse_until that can stop
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

fn inject_attribute(
  root: RenderedElement,
  target_tag: String,
  inject_attr: RenderedAttribute,
) -> RenderedElement {
  traverse(
    root,
    fn(el) {
      case el {
        RenderedElement(tag: _tag, key: key, attrs: attrs, children: children) -> {
          RenderedElement(
            tag: target_tag,
            key: key,
            attrs: attrs
            |> list.fold(
              [],
              fn(acc, attr) {
                case attr, inject_attr {
                  RenderedAttribute(name, ..), RenderedAttribute(
                    inject_attr_name,
                    ..,
                  ) if name == inject_attr_name -> {
                    list.append(acc, [inject_attr, attr])
                  }
                  _, _ -> list.append(acc, [attr])
                }
              },
            ),
            children: children,
          )
        }
        _ -> el
      }
    },
  )
}
