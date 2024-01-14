import gleam/int
import gleam/list
import gleam/string
import gleam/option.{type Option, None, Some}
import gleam/json.{type Json}
import sprocket/render.{
  type RenderedAttribute, type RenderedElement, type Renderer, RenderedAttribute,
  RenderedClientHook, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedFragment, RenderedText, Renderer,
}
import sprocket/internal/constants

pub fn renderer() -> Renderer(Json) {
  Renderer(render: fn(el) { render(el) })
}

fn render(el: RenderedElement) -> Json {
  case el {
    RenderedElement(tag: tag, key: key, attrs: attrs, children: children) ->
      element(tag, key, attrs, children)
    RenderedComponent(key: key, el: el, ..) -> component(key, el)
    RenderedFragment(key, children: children) -> fragment(key, children)
    RenderedText(text: t) -> text(t)
  }
}

fn element(
  tag: String,
  key: Option(String),
  attrs: List(RenderedAttribute),
  children: List(RenderedElement),
) -> Json {
  let attrs =
    attrs
    |> list.flat_map(fn(attr) {
      case attr {
        RenderedAttribute(name, value) -> {
          [#(name, json.string(value))]
        }
        RenderedEventHandler(kind, id) -> {
          [
            #(
              string.concat([constants.event_attr_prefix, "-", kind]),
              json.string(id),
            ),
          ]
        }
        RenderedClientHook(name, id) -> {
          [
            #(
              string.concat([constants.client_hook_attr_prefix]),
              json.string(name),
            ),
            #(
              string.concat([constants.client_hook_attr_prefix, "-id"]),
              json.string(id),
            ),
          ]
        }
      }
    })

  let children =
    children
    |> list.index_map(fn(i, child) { #(int.to_string(i), render(child)) })

  [
    #("type", json.string("element")),
    #("tag", json.string(tag)),
    #("attrs", json.object(attrs)),
  ]
  |> maybe_append_string("key", key)
  |> list.append(children)
  |> json.object()
}

fn component(key: Option(String), el: RenderedElement) -> Json {
  [#("type", json.string("component"))]
  |> maybe_append_string("key", key)
  |> list.append([#("el", render(el))])
  |> json.object()
}

fn fragment(key: Option(String), children: List(RenderedElement)) -> Json {
  let children =
    children
    |> list.index_map(fn(i, child) { #(int.to_string(i), render(child)) })

  [#("type", json.string("fragment"))]
  |> maybe_append_string("key", key)
  |> list.append(children)
  |> json.object()
}

fn text(t: String) -> Json {
  json.string(t)
}

// appends a string property to a json object if the value is present
fn maybe_append_string(
  json_object_builder: List(#(String, Json)),
  key: String,
  value: Option(String),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> list.append(json_object_builder, [#(key, json.string(v))])
    None -> json_object_builder
  }
}
