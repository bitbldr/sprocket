import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/json.{type Json}
import sprocket/internal/reconcile.{
  type ReconciledAttribute, type ReconciledElement, ReconciledAttribute,
  ReconciledClientHook, ReconciledComponent, ReconciledElement,
  ReconciledEventHandler, ReconciledFragment, ReconciledIgnoreUpdate,
  ReconciledText,
}
import sprocket/render.{type Renderer, Renderer}

pub fn json_renderer() -> Renderer(Json) {
  Renderer(render: fn(el: ReconciledElement) { render(el) })
}

fn render(el: ReconciledElement) -> Json {
  case el {
    ReconciledElement(tag: tag, key: key, attrs: attrs, children: children) ->
      element(tag, key, attrs, children)
    ReconciledComponent(key: key, el: el, ..) -> component(key, el)
    ReconciledFragment(key, children: children) -> fragment(key, children)
    ReconciledIgnoreUpdate(el) -> render(el)
    ReconciledText(text: t) -> text(t)
  }
}

fn element(
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
        ReconciledEventHandler(kind, id) -> {
          #(
            attrs,
            [
              [#("kind", json.string(kind)), #("id", json.string(id))]
              |> json.object(),
              ..events
            ],
            hooks,
          )
        }
        ReconciledClientHook(name, id) -> {
          #(attrs, events, [
            [#("name", json.string(name)), #("id", json.string(id))]
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
