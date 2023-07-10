import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import sprocket/html/attribute.{Attribute, Event}
import sprocket/element.{
  AbstractFunctionalComponent, Component, Debug, Element, Keyed, Raw, SafeHtml,
}
import sprocket/socket.{ComponentHooks, ComponentWip, Socket}
import sprocket/utils/unique
import sprocket/utils/ordered_map
import sprocket/logger

pub type Renderer(result) {
  Renderer(render: fn(RenderedElement) -> result)
}

pub type RenderedAttribute {
  RenderedAttribute(name: String, value: String)
  RenderedEventHandler(kind: String, id: String)
}

pub type RenderedElement {
  RenderedElement(
    tag: String,
    key: Option(String),
    attrs: List(RenderedAttribute),
    children: List(RenderedElement),
  )
  RenderedComponent(
    fc: AbstractFunctionalComponent,
    key: Option(String),
    props: Dynamic,
    hooks: ComponentHooks,
    children: List(RenderedElement),
  )
  RenderedText(text: String)
}

pub type RenderResult(a) {
  RenderResult(socket: Socket, rendered: a)
}

// Renders the given element using the provided renderer as a stateless element.
//
// Internally this function uses live_render with a placeholder socket to render the tree,
// but then discards the socket and returns the result.
pub fn render(el: Element, renderer: Renderer(r)) -> r {
  let RenderResult(rendered: rendered, ..) =
    live_render(socket.new(None), el, None, None)

  renderer.render(rendered)
}

// Renders the given element into a RenderedElement tree.
// Returns the socket and a stateful RenderedElement tree using the given socket.
pub fn live_render(
  socket: Socket,
  el: Element,
  key: Option(String),
  prev: Option(RenderedElement),
) -> RenderResult(RenderedElement) {
  // TODO: detect infinite render loop - render_count > SOME_THRESHOLD then panic "Possible infinite rerender loop"

  case el {
    Element(tag, attrs, children) ->
      element(socket, tag, key, attrs, children, prev)
    Component(fc, props) -> component(socket, fc, key, props, prev)
    Debug(id, meta, el) -> {
      // unwrap debug element, print details and continue with rendering
      io.debug(#(id, meta))
      io.debug(live_render(socket, el, key, prev))
    }
    Keyed(key, el) -> live_render(socket, el, Some(key), prev)
    SafeHtml(html) -> safe_html(socket, html)
    Raw(text) -> raw(socket, text)
  }
}

fn element(
  socket: Socket,
  tag: String,
  key: Option(String),
  attrs: List(Attribute),
  children: List(Element),
  prev: Option(RenderedElement),
) -> RenderResult(RenderedElement) {
  let RenderResult(socket, rendered_attrs) =
    list.fold(
      attrs,
      RenderResult(socket, []),
      fn(acc, current) {
        let RenderResult(socket, rendered_attrs) = acc

        case current {
          Attribute(name, value) -> {
            let assert Ok(value) = dynamic.string(value)
            RenderResult(
              socket,
              [RenderedAttribute(name, value), ..rendered_attrs],
            )
          }
          Event(kind, identifiable_cb) -> {
            let #(socket, id) =
              socket.push_event_handler(socket, identifiable_cb)
            RenderResult(
              socket,
              [
                RenderedEventHandler(kind, unique.to_string(id)),
                ..rendered_attrs
              ],
            )
          }
        }
      },
    )

  let RenderResult(socket, children) =
    children
    |> list.index_fold(
      RenderResult(socket, []),
      fn(acc, child, i) {
        let RenderResult(socket, rendered) = acc

        let prev_child = find_prev_child(prev, child, i)

        let RenderResult(socket, rendered_child) =
          live_render(socket, child, None, prev_child)
        RenderResult(socket, [rendered_child, ..rendered])
      },
    )

  RenderResult(
    socket,
    RenderedElement(
      tag,
      key,
      list.reverse(rendered_attrs),
      list.reverse(children),
    ),
  )
}

fn component(
  socket: Socket,
  fc: AbstractFunctionalComponent,
  key: Option(String),
  props: Dynamic,
  prev: Option(RenderedElement),
) -> RenderResult(RenderedElement) {
  // Prepare socket wip (work in progress) for component render
  let socket = case prev {
    None ->
      // There is no previous rendered element, so this is the first render
      Socket(..socket, wip: ComponentWip(ordered_map.new(), 0))
    Some(RenderedComponent(_, _, _, hooks, _)) ->
      // There is a previous rendered element, so use the previously rendered hooks
      Socket(..socket, wip: ComponentWip(hooks, 0))
    Some(_) -> {
      // This should never happen
      logger.error("Invalid previous element")
      panic
    }
  }

  // render the component
  let #(socket, children) = fc(socket, props)

  // capture hook results
  let hooks = socket.wip.hooks

  // process children
  let RenderResult(socket, children) =
    children
    |> list.index_fold(
      RenderResult(socket, []),
      fn(acc, child, i) {
        let RenderResult(socket, rendered) = acc

        let prev_child = find_prev_child(prev, child, i)

        let RenderResult(socket, rendered_child) =
          live_render(socket, child, None, prev_child)

        RenderResult(socket, [rendered_child, ..rendered])
      },
    )

  RenderResult(
    socket,
    RenderedComponent(fc, key, props, hooks, list.reverse(children)),
  )
}

fn get_key(el: Element) -> Option(String) {
  case el {
    Keyed(key, _) -> Some(key)
    _ -> None
  }
}

// Attempts to find a previous child by key, otherwise by matching function component at given index.
// If no previous child is found, returns None
fn find_prev_child(prev: Option(RenderedElement), child: Element, index: Int) {
  let child_key = get_key(child)
  option.or(
    get_child_by_key(prev, child_key),
    get_matching_prev_child_by_index(prev, child, index),
  )
}

fn get_child_by_key(
  prev: Option(RenderedElement),
  key: Option(String),
) -> Option(RenderedElement) {
  case prev, key {
    Some(RenderedComponent(_, _, _, _, children)), Some(key) -> {
      find_by_key(children, key)
    }
    Some(RenderedElement(_, _, _, children)), Some(key) -> {
      find_by_key(children, key)
    }
    _, _ -> None
  }
}

fn find_by_key(children, key) {
  // find a child by given key
  list.find(
    children,
    fn(child) {
      case child {
        RenderedComponent(_, Some(child_key), _, _, _) -> child_key == key
        RenderedElement(_, Some(child_key), _, _) -> child_key == key
        _ -> False
      }
    },
  )
  |> option.from_result()
}

fn get_matching_prev_child_by_index(
  prev: Option(RenderedElement),
  child: Element,
  index: Int,
) -> Option(RenderedElement) {
  case prev {
    Some(RenderedComponent(_, _, _, _, children)) -> {
      case list.at(children, index) {
        Ok(prev_child) -> {
          maybe_matching_el(prev_child, child)
        }
        Error(Nil) -> None
      }
    }
    Some(RenderedElement(_, _, _, children)) -> {
      case list.at(children, index) {
        Ok(prev_child) -> {
          maybe_matching_el(prev_child, child)
        }
        Error(Nil) -> None
      }
    }
    _ -> None
  }
}

fn maybe_matching_el(
  prev_child: RenderedElement,
  child: Element,
) -> Option(RenderedElement) {
  case prev_child, child {
    RenderedComponent(prev_fc, _, _, _, _), Component(fc, ..) -> {
      case prev_fc == fc {
        True -> Some(prev_child)
        False -> None
      }
    }
    RenderedElement(prev_tag, _, _, _), Element(tag, ..) -> {
      case prev_tag == tag {
        True -> Some(prev_child)
        False -> None
      }
    }
    _, Debug(_, _, el) -> maybe_matching_el(prev_child, el)
    _, _ -> None
  }
}

fn safe_html(socket: Socket, html: String) -> RenderResult(RenderedElement) {
  RenderResult(socket, RenderedText(html))
}

fn raw(socket: Socket, text: String) -> RenderResult(RenderedElement) {
  RenderResult(socket, RenderedText(text))
}
