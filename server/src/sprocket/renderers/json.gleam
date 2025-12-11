import gleam/json.{type Json}
import gleam/list
import sprocket/internal/reconcile.{
  type ReconciledAttribute, type ReconciledElement, ReconciledAttribute,
  ReconciledClientHook, ReconciledComponent, ReconciledCustom, ReconciledElement,
  ReconciledEventHandler, ReconciledFragment, ReconciledIgnoreUpdate,
  ReconciledText,
}
import sprocket/internal/utils/unique
import sprocket/render.{type Renderer, Renderer}
import sprocket_shared/vdom

/// Returns a JSON renderer used to render reconciled elements.
pub fn json_renderer() -> Renderer(Json) {
  Renderer(render: fn(el: ReconciledElement) { render(el) })
}

fn render(el: ReconciledElement) -> Json {
  el
  |> to_shared_vdom()
  |> vdom.encode()
}

fn to_shared_vdom(el: ReconciledElement) -> vdom.Node {
  case el {
    ReconciledElement(id, tag, key, attrs, children) -> {
      let #(v_attrs, v_events, v_hooks) = map_attrs(attrs)

      vdom.Element(
        unique.to_string(id),
        tag,
        key,
        v_attrs,
        v_events,
        v_hooks,
        children |> list.map(to_shared_vdom),
      )
    }
    ReconciledComponent(_fc, key, _props, _hooks, el) ->
      vdom.Component(key, to_shared_vdom(el))
    ReconciledFragment(key, children) ->
      vdom.Fragment(key, children |> list.map(to_shared_vdom))
    ReconciledIgnoreUpdate(el) -> to_shared_vdom(el)
    ReconciledText(text) -> vdom.Text(text)
    ReconciledCustom(kind, data) -> vdom.Custom(kind, data)
  }
}

fn map_attrs(
  attrs: List(ReconciledAttribute),
) -> #(List(vdom.Attribute), List(vdom.Event), List(vdom.ClientHook)) {
  attrs
  |> list.fold(#([], [], []), fn(acc, attr) {
    let #(v_attrs, v_events, v_hooks) = acc

    case attr {
      ReconciledAttribute(name, value) ->
        #([vdom.Attribute(name, value), ..v_attrs], v_events, v_hooks)
      ReconciledEventHandler(element_id, kind) ->
        #(
          v_attrs,
          [vdom.Event(kind, unique.to_string(element_id)), ..v_events],
          v_hooks,
        )
      ReconciledClientHook(name) ->
        #(v_attrs, v_events, [vdom.ClientHook(name), ..v_hooks])
    }
  })
}
