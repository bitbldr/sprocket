import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import sprocket/context.{type ElementId}
import sprocket/internal/reconcile.{
  type ReconciledAttribute, type ReconciledElement, ReconciledAttribute,
  ReconciledClientHook, ReconciledComponent, ReconciledCustom, ReconciledElement,
  ReconciledEventHandler, ReconciledFragment, ReconciledIgnoreUpdate,
  ReconciledText,
}
import sprocket/internal/utils/unique.{type Unique}
import sprocket/render.{type Renderer, Renderer}

/// Returns a JSON renderer used to render reconciled elements.
pub fn json_renderer() -> Renderer(Json) {
  Renderer(render: fn(el: ReconciledElement) { render(el) })
}

fn render(el: ReconciledElement) -> Json {
  case el {
    ReconciledElement(
      id: id,
      tag: tag,
      key: key,
      attrs: attrs,
      children: children,
    ) -> element(id, tag, key, attrs, children)
    ReconciledComponent(key: key, el: el, ..) -> component(key, el)
    ReconciledFragment(key, children: children) -> fragment(key, children)
    ReconciledIgnoreUpdate(el) -> render(el)
    ReconciledText(text: t) -> text(t)
    ReconciledCustom(kind: kind, data: data) -> custom(kind, data)
  }
}

fn element(
  id: Unique(ElementId),
  tag: String,
  key: Option(String),
  attrs: List(ReconciledAttribute),
  children: List(ReconciledElement),
) -> Json {
  let #(attrs, events, hooks) =
    attrs
    |> list.fold(#([], [], []), fn(acc, attr) {
      let #(attrs, events, hooks) = acc

      case attr {
        ReconciledAttribute(name, value) -> {
          #([#(name, json.string(value)), ..attrs], events, hooks)
        }
        ReconciledEventHandler(element_id, kind) -> {
          #(
            attrs,
            [
              [
                #("kind", json.string(kind)),
                #("id", element_id |> unique.to_string() |> json.string()),
              ]
                |> json.object(),
              ..events
            ],
            hooks,
          )
        }
        ReconciledClientHook(name) -> {
          #(attrs, events, [
            [#("name", json.string(name))]
              |> json.object(),
            ..hooks
          ])
        }
      }
    })

  let children =
    children
    |> list.index_map(fn(child, i) { #(int.to_string(i), render(child)) })

  [
    #("type", json.string("element")),
    #("id", unique.to_string(id) |> json.string),
    #("tag", json.string(tag)),
    #("attrs", json.object(attrs)),
    #("events", json.preprocessed_array(events)),
    #("hooks", json.preprocessed_array(hooks)),
  ]
  |> maybe_append_string("key", key)
  |> list.append(children)
  |> json.object()
}

fn component(key: Option(String), el: ReconciledElement) -> Json {
  [#("type", json.string("component"))]
  |> maybe_append_string("key", key)
  |> list.append([#("0", render(el))])
  |> json.object()
}

fn fragment(key: Option(String), children: List(ReconciledElement)) -> Json {
  let children =
    children
    |> list.index_map(fn(child, i) { #(int.to_string(i), render(child)) })

  [#("type", json.string("fragment"))]
  |> maybe_append_string("key", key)
  |> list.append(children)
  |> json.object()
}

fn text(t: String) -> Json {
  json.string(t)
}

fn custom(kind: String, data: String) -> Json {
  [
    #("type", json.string("custom")),
    #("kind", json.string(kind)),
    #("data", json.string(data)),
  ]
  |> json.object()
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
