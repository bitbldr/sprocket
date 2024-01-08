import gleam/io
import gleam/list
import gleam/map
import gleam/option.{type Option, None, Some}
import gleam/dynamic.{type Dynamic}
import ids/cuid
import sprocket/context.{
  type AbstractFunctionalComponent, type Attribute, type ComponentHooks,
  type Context, type Element, Attribute, ClientHook, Component, ComponentWip,
  Context, Debug, Element, Event, IgnoreUpdate, Keyed, Provider, Raw, SafeHtml,
}
import sprocket/internal/utils/unique
import sprocket/internal/utils/ordered_map
import sprocket/internal/logger
import sprocket/internal/constants

pub type RenderedAttribute {
  RenderedAttribute(name: String, value: String)
  RenderedEventHandler(kind: String, id: String)
  RenderedClientHook(name: String, id: String)
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

pub type Renderer(result) {
  Renderer(render: fn(RenderedElement) -> result)
}

pub type RenderResult(a) {
  RenderResult(ctx: Context, rendered: a)
}

// Renders the given element using the provided renderer as a stateless element.
//
// Internally this function uses live_render with a placeholder ctx to render the tree,
// but then discards the ctx and returns the result.
pub fn render(el: Element, renderer: Renderer(r)) -> r {
  let assert Ok(cuid_channel) = cuid.start()

  let RenderResult(rendered: rendered, ..) =
    live_render(context.new(el, cuid_channel, None), el, None, None)

  renderer.render(rendered)
}

// Renders the given element into a RenderedElement tree.
// Returns the ctx and a stateful RenderedElement tree using the given ctx.
pub fn live_render(
  ctx: Context,
  el: Element,
  key: Option(String),
  prev: Option(RenderedElement),
) -> RenderResult(RenderedElement) {
  // TODO: detect infinite render loop - render_count > SOME_THRESHOLD then panic "Possible infinite rerender loop"

  case el {
    Element(tag, attrs, children) ->
      element(ctx, tag, key, attrs, children, prev)
    Component(fc, props) -> component(ctx, fc, key, props, prev)
    Debug(id, meta, el) -> {
      // unwrap debug element, print details and continue with rendering
      io.debug(#(id, meta))
      io.debug(live_render(ctx, el, key, prev))
    }
    Keyed(key, el) -> live_render(ctx, el, Some(key), prev)
    IgnoreUpdate(el) -> {
      case prev {
        Some(prev) -> {
          // since we're ignoring updates, no need to rerender children
          // just return the previous rendered element with the ignore attribute
          prev
          |> append_attribute(RenderedAttribute(
            constants.ignore_update_attr,
            "true",
          ))
          |> RenderResult(ctx, _)
        }
        None -> {
          // render the element and add the ignore attribute
          let RenderResult(ctx, rendered) = live_render(ctx, el, key, prev)

          rendered
          |> append_attribute(RenderedAttribute(
            constants.ignore_update_attr,
            "true",
          ))
          |> RenderResult(ctx, _)
        }
      }
    }
    Provider(provider_key, value, el) -> {
      let ctx =
        Context(
          ..ctx,
          providers: map.insert(ctx.providers, provider_key, value),
        )

      live_render(ctx, el, key, prev)
    }
    SafeHtml(html) -> safe_html(ctx, html)
    Raw(text) -> raw(ctx, text)
  }
}

fn element(
  ctx: Context,
  tag: String,
  key: Option(String),
  attrs: List(Attribute),
  children: List(Element),
  prev: Option(RenderedElement),
) -> RenderResult(RenderedElement) {
  let RenderResult(ctx, rendered_attrs) =
    list.fold(
      attrs,
      RenderResult(ctx, []),
      fn(acc, current) {
        let RenderResult(ctx, rendered_attrs) = acc

        case current {
          Attribute(name, value) -> {
            let assert Ok(value) = dynamic.string(value)
            RenderResult(
              ctx,
              [RenderedAttribute(name, value), ..rendered_attrs],
            )
          }
          Event(kind, identifiable_cb) -> {
            let #(ctx, id) = context.push_event_handler(ctx, identifiable_cb)
            RenderResult(
              ctx,
              [
                RenderedEventHandler(kind, unique.to_string(id)),
                ..rendered_attrs
              ],
            )
          }
          ClientHook(id, name) -> {
            RenderResult(
              ctx,
              [RenderedClientHook(name, unique.to_string(id)), ..rendered_attrs],
            )
          }
        }
      },
    )

  let RenderResult(ctx, children) =
    children
    |> list.index_fold(
      RenderResult(ctx, []),
      fn(acc, child, i) {
        let RenderResult(ctx, rendered) = acc

        let prev_child = find_prev_child(prev, child, i)

        let RenderResult(ctx, rendered_child) =
          live_render(ctx, child, None, prev_child)
        RenderResult(ctx, [rendered_child, ..rendered])
      },
    )

  RenderResult(
    ctx,
    RenderedElement(
      tag,
      key,
      list.reverse(rendered_attrs),
      list.reverse(children),
    ),
  )
}

fn component(
  ctx: Context,
  fc: AbstractFunctionalComponent,
  key: Option(String),
  props: Dynamic,
  prev: Option(RenderedElement),
) -> RenderResult(RenderedElement) {
  // Prepare ctx wip (work in progress) for component render
  let ctx = case prev {
    None ->
      // There is no previous rendered element, so this is the first render
      Context(..ctx, wip: ComponentWip(ordered_map.new(), 0, True))
    Some(RenderedComponent(_, _, _, hooks, _)) ->
      // There is a previous rendered element, so use the previously rendered hooks
      Context(..ctx, wip: ComponentWip(hooks, 0, False))
    Some(_) -> {
      // This should never happen
      logger.error("Invalid previous element")
      panic
    }
  }

  // render the component
  let #(ctx, children) = fc(ctx, props)

  // capture hook results
  let hooks = ctx.wip.hooks

  // process children
  let RenderResult(ctx, children) =
    children
    |> list.index_fold(
      RenderResult(ctx, []),
      fn(acc, child, i) {
        let RenderResult(ctx, rendered) = acc

        let prev_child = find_prev_child(prev, child, i)

        let RenderResult(ctx, rendered_child) =
          live_render(ctx, child, None, prev_child)

        RenderResult(ctx, [rendered_child, ..rendered])
      },
    )

  RenderResult(
    ctx,
    RenderedComponent(fc, key, props, hooks, list.reverse(children)),
  )
}

fn get_key(el: Element) -> Option(String) {
  case el {
    Keyed(key, _) -> Some(key)
    Debug(_, _, el) -> get_key(el)
    IgnoreUpdate(el) -> get_key(el)
    Provider(_, _, el) -> get_key(el)
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
    _, Keyed(_, el) -> maybe_matching_el(prev_child, el)
    _, IgnoreUpdate(el) -> maybe_matching_el(prev_child, el)
    _, Provider(_, _, el) -> maybe_matching_el(prev_child, el)
    _, _ -> None
  }
}

fn safe_html(ctx: Context, html: String) -> RenderResult(RenderedElement) {
  RenderResult(ctx, RenderedText(html))
}

fn raw(ctx: Context, text: String) -> RenderResult(RenderedElement) {
  RenderResult(ctx, RenderedText(text))
}

pub fn traverse(
  el: RenderedElement,
  updater: fn(RenderedElement) -> RenderedElement,
) -> RenderedElement {
  case updater(el) {
    RenderedComponent(fc, key, props, hooks, children) -> {
      RenderedComponent(
        fc,
        key,
        props,
        hooks,
        list.map(children, fn(child) { traverse(child, updater) }),
      )
    }
    RenderedElement(tag, key, attrs, children) -> {
      RenderedElement(
        tag,
        key,
        attrs,
        list.map(children, fn(child) { traverse(child, updater) }),
      )
    }
    _ -> el
  }
}

pub fn find(
  el: RenderedElement,
  matches: fn(RenderedElement) -> Bool,
) -> Result(RenderedElement, Nil) {
  case matches(el) {
    True -> Ok(el)
    False -> {
      case el {
        RenderedComponent(_fc, _key, _props, _hooks, children) -> {
          list.find(
            children,
            fn(child) {
              case find(child, matches) {
                Ok(_child) -> True
                Error(_) -> False
              }
            },
          )
        }
        RenderedElement(_tag, _key, _attrs, children) -> {
          list.find(
            children,
            fn(child) {
              case find(child, matches) {
                Ok(_child) -> True
                Error(_) -> False
              }
            },
          )
        }
        _ -> Error(Nil)
      }
    }
  }
}

pub fn append_attribute(
  el: RenderedElement,
  attr: RenderedAttribute,
) -> RenderedElement {
  case el {
    RenderedElement(tag, key, attrs, children) -> {
      RenderedElement(tag, key, list.append(attrs, [attr]), children)
    }
    RenderedComponent(fc, key, props, hooks, children) -> {
      // since components are rendered as list of elements, we need to append the attribute to the
      // element's children
      RenderedComponent(
        fc,
        key,
        props,
        hooks,
        list.map(children, fn(child) { append_attribute(child, attr) }),
      )
    }
    _ -> el
  }
}
