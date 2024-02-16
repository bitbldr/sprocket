import gleam/io
import gleam/list
import gleam/map
import gleam/result
import gleam/option.{type Option, None, Some}
import gleam/dynamic.{type Dynamic}
import sprocket/context.{
  type AbstractFunctionalComponent, type Attribute, type Context, type Element,
  Attribute, ClientHook, Component, ComponentWip, Context, Debug, Element, Event,
  Fragment, IgnoreUpdate, Keyed, Provider, Raw, SafeHtml,
}
import sprocket/internal/reconcile.{
  type ReconciledResult, type RenderedAttribute, type RenderedElement, IgnoreAll,
  ReconciledResult, RenderedAttribute, RenderedClientHook, RenderedComponent,
  RenderedElement, RenderedEventHandler, RenderedFragment, RenderedIgnoreUpdate,
  RenderedText,
}
import sprocket/internal/utils/unique
import sprocket/internal/utils/ordered_map
import sprocket/internal/logger

// Reconciles the given element into a RenderedElement tree against the previous rendered element.
// Returns the updated ctx and a stateful RenderedElement tree.
pub fn reconcile(
  ctx: Context,
  el: Element,
  key: Option(String),
  prev: Option(RenderedElement),
) -> ReconciledResult(RenderedElement) {
  // TODO: detect infinite render loop - render_count > SOME_THRESHOLD then panic "Possible infinite rerender loop"

  case el {
    Element(tag, attrs, children) ->
      element(ctx, tag, key, attrs, children, prev)
    Component(fc, props) -> component(ctx, fc, key, props, prev)
    Fragment(children) -> fragment(ctx, key, children, prev)
    Debug(id, meta, el) -> {
      // unwrap debug element, print details and continue with rendering
      io.debug(#(id, meta))
      io.debug(reconcile(ctx, el, key, prev))
    }
    Keyed(key, el) -> reconcile(ctx, el, Some(key), prev)
    IgnoreUpdate(el) -> {
      case prev {
        Some(prev) -> {
          // since we're ignoring updates, no need to rerender children
          // just return the previous rendered element as ignored
          ReconciledResult(ctx, RenderedIgnoreUpdate(IgnoreAll, prev))
        }
        None -> {
          // render the element on first render, ignore on subsequent renders
          let ReconciledResult(ctx, rendered) = reconcile(ctx, el, key, prev)

          ReconciledResult(ctx, RenderedIgnoreUpdate(IgnoreAll, rendered))
        }
      }
    }
    Provider(provider_key, value, el) -> {
      let ctx =
        Context(
          ..ctx,
          providers: map.insert(ctx.providers, provider_key, value),
        )

      reconcile(ctx, el, key, prev)
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
) -> ReconciledResult(RenderedElement) {
  let ReconciledResult(ctx, rendered_attrs) =
    list.fold(
      attrs,
      ReconciledResult(ctx, []),
      fn(acc, current) {
        let ReconciledResult(ctx, rendered_attrs) = acc

        case current {
          Attribute(name, value) -> {
            let assert Ok(value) =
              dynamic.string(value)
              |> result.map_error(fn(error) {
                logger.error(
                  "render.element: failed to convert attribute value to string",
                )
                error
              })

            ReconciledResult(
              ctx,
              [RenderedAttribute(name, value), ..rendered_attrs],
            )
          }
          Event(kind, identifiable_cb) -> {
            let #(ctx, id) = context.push_event_handler(ctx, identifiable_cb)
            ReconciledResult(
              ctx,
              [
                RenderedEventHandler(kind, unique.to_string(id)),
                ..rendered_attrs
              ],
            )
          }
          ClientHook(id, name) -> {
            ReconciledResult(
              ctx,
              [RenderedClientHook(name, unique.to_string(id)), ..rendered_attrs],
            )
          }
        }
      },
    )

  let ReconciledResult(ctx, children) =
    children
    |> list.index_fold(
      ReconciledResult(ctx, []),
      fn(acc, child, i) {
        let ReconciledResult(ctx, rendered) = acc

        let prev_child = find_prev_child(prev, child, i)

        let ReconciledResult(ctx, rendered_child) =
          reconcile(ctx, child, None, prev_child)
        ReconciledResult(ctx, [rendered_child, ..rendered])
      },
    )

  ReconciledResult(
    ctx,
    RenderedElement(
      tag,
      key,
      list.reverse(rendered_attrs),
      list.reverse(children),
    ),
  )
}

fn fragment(
  ctx: Context,
  key: Option(String),
  children: List(Element),
  prev: Option(RenderedElement),
) -> ReconciledResult(RenderedElement) {
  let ReconciledResult(ctx, children) =
    children
    |> list.index_fold(
      ReconciledResult(ctx, []),
      fn(acc, child, i) {
        let ReconciledResult(ctx, rendered) = acc

        let prev_child = find_prev_child(prev, child, i)

        let ReconciledResult(ctx, rendered_child) =
          reconcile(ctx, child, None, prev_child)
        ReconciledResult(ctx, [rendered_child, ..rendered])
      },
    )

  ReconciledResult(ctx, RenderedFragment(key, list.reverse(children)))
}

fn component(
  ctx: Context,
  fc: AbstractFunctionalComponent,
  key: Option(String),
  props: Dynamic,
  prev: Option(RenderedElement),
) -> ReconciledResult(RenderedElement) {
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
  let #(ctx, el) = fc(ctx, props)

  // capture hook results
  let hooks = ctx.wip.hooks

  let prev_el = case prev {
    Some(RenderedComponent(_, _, _, _, el)) -> Some(el)
    _ -> None
  }

  let ReconciledResult(ctx, rendered_el) = reconcile(ctx, el, None, prev_el)

  ReconciledResult(ctx, RenderedComponent(fc, key, props, hooks, rendered_el))
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
    get_prev_matching_child_by_key(prev, child_key),
    get_prev_matching_child_by_index(prev, child, index),
  )
}

fn get_prev_matching_child_by_key(
  prev: Option(RenderedElement),
  key: Option(String),
) -> Option(RenderedElement) {
  case prev, key {
    Some(RenderedElement(_, _, _, children)), Some(key) -> {
      find_by_key(children, key)
    }
    Some(RenderedFragment(_, children)), Some(key) -> {
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
        RenderedFragment(Some(child_key), _) -> child_key == key
        _ -> False
      }
    },
  )
  |> option.from_result()
}

fn get_prev_matching_child_by_index(
  prev: Option(RenderedElement),
  child: Element,
  index: Int,
) -> Option(RenderedElement) {
  case prev {
    Some(RenderedElement(_, _, _, children)) -> {
      case list.at(children, index) {
        Ok(prev_child) -> {
          maybe_matching_el(prev_child, child)
        }
        Error(Nil) -> None
      }
    }
    Some(RenderedFragment(_, children)) -> {
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
  let child_key = get_key(child)

  case prev_child, child {
    RenderedElement(prev_tag, prev_key, _, _), Element(tag, ..) -> {
      case prev_tag == tag && prev_key == child_key {
        True -> Some(prev_child)
        False -> None
      }
    }
    RenderedComponent(prev_fc, prev_key, _, _, _), Component(fc, ..) -> {
      case prev_fc == fc && prev_key == child_key {
        True -> Some(prev_child)
        False -> None
      }
    }
    RenderedFragment(prev_key, _), Fragment(..) -> {
      case prev_key == child_key {
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

fn safe_html(ctx: Context, html: String) -> ReconciledResult(RenderedElement) {
  ReconciledResult(ctx, RenderedText(html))
}

fn raw(ctx: Context, text: String) -> ReconciledResult(RenderedElement) {
  ReconciledResult(ctx, RenderedText(text))
}

pub fn traverse(
  el: RenderedElement,
  updater: fn(RenderedElement) -> RenderedElement,
) -> RenderedElement {
  case updater(el) {
    RenderedComponent(fc, key, props, hooks, el) -> {
      RenderedComponent(fc, key, props, hooks, traverse(el, updater))
    }
    RenderedElement(tag, key, attrs, children) -> {
      RenderedElement(
        tag,
        key,
        attrs,
        list.map(children, fn(child) { traverse(child, updater) }),
      )
    }
    RenderedFragment(key, children) -> {
      RenderedFragment(
        key,
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
        RenderedComponent(_fc, _key, _props, _hooks, el) -> {
          find(el, matches)
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
        RenderedFragment(_key, children) -> {
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
    RenderedComponent(fc, key, props, hooks, el) -> {
      // we need to append the attribute to the component's element
      RenderedComponent(fc, key, props, hooks, append_attribute(el, attr))
    }
    RenderedElement(tag, key, attrs, children) -> {
      RenderedElement(tag, key, list.append(attrs, [attr]), children)
    }
    RenderedFragment(key, children) -> {
      // since a fragment is a list of elements, we need to append the attribute to the
      // element's children
      RenderedFragment(
        key,
        list.map(children, fn(child) { append_attribute(child, attr) }),
      )
    }
    _ -> el
  }
}