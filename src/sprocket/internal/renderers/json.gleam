import gleam/int
import gleam/list
import gleam/string
import gleam/option.{type Option, None, Some}
import gleam/json.{type Json}
import sprocket/internal/reconcile.{
  type IgnoreRule, type ReconciledAttribute, type ReconciledElement, IgnoreAll,
  ReconciledAttribute, ReconciledClientHook, ReconciledComponent,
  ReconciledElement, ReconciledEventHandler, ReconciledFragment,
  ReconciledIgnoreUpdate, ReconciledText,
}
import sprocket/internal/render.{type Renderer, Renderer}
import sprocket/internal/constants

pub fn json_renderer() -> Renderer(Json) {
  Renderer(render: fn(el: ReconciledElement) { render(el, None) })
}

fn render(el: ReconciledElement, ignore: Option(IgnoreRule)) -> Json {
  case el {
    ReconciledElement(tag: tag, key: key, attrs: attrs, children: children) ->
      element(tag, key, ignore, attrs, children)
    ReconciledComponent(key: key, el: el, ..) -> component(key, ignore, el)
    ReconciledFragment(key, children: children) ->
      fragment(key, ignore, children)
    ReconciledIgnoreUpdate(rule, el) -> render(el, Some(rule))
    ReconciledText(text: t) -> text(t)
  }
}

fn element(
  tag: String,
  key: Option(String),
  ignore: Option(IgnoreRule),
  attrs: List(ReconciledAttribute),
  children: List(ReconciledElement),
) -> Json {
  let attrs =
    attrs
    |> list.flat_map(fn(attr) {
      case attr {
        ReconciledAttribute(name, value) -> {
          [#(name, json.string(value))]
        }
        ReconciledEventHandler(kind, id) -> {
          [
            #(
              string.concat([constants.event_attr_prefix, "-", kind]),
              json.string(id),
            ),
          ]
        }
        ReconciledClientHook(name, id) -> {
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
    |> list.index_map(fn(child, i) { #(int.to_string(i), render(child, None)) })

  [
    #("type", json.string("element")),
    #("tag", json.string(tag)),
    #("attrs", json.object(attrs)),
  ]
  |> maybe_append_string("key", key)
  |> maybe_append_string(
    "ignore",
    option.map(ignore, fn(rule) {
      case rule {
        IgnoreAll -> "all"
      }
    }),
  )
  |> list.append(children)
  |> json.object()
}

fn component(
  key: Option(String),
  ignore: Option(IgnoreRule),
  el: ReconciledElement,
) -> Json {
  [#("type", json.string("component"))]
  |> maybe_append_string("key", key)
  |> list.append([#("0", render(el, ignore))])
  |> json.object()
}

fn fragment(
  key: Option(String),
  ignore: Option(IgnoreRule),
  children: List(ReconciledElement),
) -> Json {
  let children =
    children
    |> list.index_map(fn(child, i) {
      #(int.to_string(i), render(child, ignore))
    })

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
