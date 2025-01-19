import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option.{type Option, None, Some}
import sprocket/context.{
  type Attribute, type Context, type DynamicStatefulComponent, type Element,
  Attribute, ClientHook, ClientHookId, Component, ComponentWip, Context, Custom,
  Debug, Element, Event, EventHandler, Fragment, IgnoreUpdate, Keyed, Provider,
  Text,
}
import sprocket/internal/logger
import sprocket/internal/reconcile.{
  type ReconciledAttribute, type ReconciledElement, type ReconciledResult,
  type Reconciler, ReconciledAttribute, ReconciledClientHook,
  ReconciledComponent, ReconciledCustom, ReconciledElement,
  ReconciledEventHandler, ReconciledFragment, ReconciledIgnoreUpdate,
  ReconciledResult, ReconciledText, Reconciler,
}
import sprocket/internal/utils/list.{element_at} as _list_utils
import sprocket/internal/utils/ordered_map
import sprocket/internal/utils/unique

pub fn recursive_reconciler() -> Reconciler {
  Reconciler(
    reconcile: fn(ctx: Context, el: Element, prev: Option(ReconciledElement)) {
      reconcile(ctx, el, None, prev)
    },
  )
}

// Reconciles the given element into a ReconciledElement tree against the previous rendered element.
// Returns the updated ctx and a stateful ReconciledElement tree.
pub fn reconcile(
  ctx: Context,
  el: Element,
  key: Option(String),
  prev: Option(ReconciledElement),
) -> ReconciledResult {
  // TODO: detect infinite render loop - render_count > SOME_THRESHOLD then panic "Possible infinite rerender loop"

  case el {
    Element(tag, attrs, children) ->
      element(ctx, tag, key, attrs, children, prev)
    Component(fc, props) -> component(ctx, fc, key, props, prev)
    Fragment(children) -> fragment(ctx, key, children, prev)
    Debug(id, meta, el) -> {
      // unwrap debug element, print details and continue with rendering
      logger.debug_meta("[DEBUG ELEMENT]", #(
        id,
        meta,
        reconcile(ctx, el, key, prev),
      ))
      logger.debug_meta("[DEBUG ELEMENT]", reconcile(ctx, el, key, prev))
    }
    Keyed(key, el) -> reconcile(ctx, el, Some(key), prev)
    IgnoreUpdate(el) -> {
      case prev {
        Some(prev) -> {
          // since we're ignoring all updates, no need to rerender children
          // just return the previous rendered element as ignored
          ReconciledResult(ctx, ReconciledIgnoreUpdate(prev))
        }
        _ -> {
          // always render the element on first render, ignore on subsequent renders.
          let ReconciledResult(ctx, rendered) = reconcile(ctx, el, key, prev)

          ReconciledResult(ctx, ReconciledIgnoreUpdate(rendered))
        }
      }
    }
    Provider(provider_key, value, el) -> {
      let ctx =
        Context(
          ..ctx,
          providers: dict.insert(ctx.providers, provider_key, value),
        )

      reconcile(ctx, el, key, prev)
    }
    Text(t) -> text(ctx, t)
    Custom(kind, data) -> custom(ctx, kind, data)
  }
}

fn prev_or_new_id(
  ctx: Context,
  tag: String,
  key: Option(String),
  prev: Option(ReconciledElement),
) {
  case prev {
    Some(ReconciledElement(prev_id, prev_tag, prev_key, _, _))
      if tag == prev_tag && key == prev_key
    -> {
      // if the previous element is the same element type and has the same key, use its id
      prev_id
    }
    _ -> {
      unique.cuid(ctx.cuid_channel)
    }
  }
}

fn element(
  ctx: Context,
  tag: String,
  key: Option(String),
  attrs: List(Attribute),
  children: List(Element),
  prev: Option(ReconciledElement),
) -> ReconciledResult {
  // We want to keep the same id for the same element across reconciliations
  let element_id = prev_or_new_id(ctx, tag, key, prev)

  let #(ctx, rendered_attrs) =
    list.fold(attrs, #(ctx, []), fn(acc, current) {
      let #(ctx, rendered_attrs) = acc

      case current {
        Attribute(name, value) -> {
          case dynamic.string(value) {
            Ok(value) -> {
              #(ctx, [ReconciledAttribute(name, value), ..rendered_attrs])
            }
            Error(_) -> {
              logger.error(
                "reconciler: failed to convert attribute value to string",
              )
              acc
            }
          }
        }
        Event(kind, handler) -> {
          let ctx =
            context.push_event_handler(
              ctx,
              EventHandler(element_id, kind, handler),
            )

          #(ctx, [ReconciledEventHandler(element_id, kind), ..rendered_attrs])
        }
        ClientHook(id, name) -> {
          let ctx =
            context.push_client_hook(ctx, ClientHookId(element_id, name, id))

          #(ctx, [ReconciledClientHook(name), ..rendered_attrs])
        }
      }
    })

  let #(ctx, children) =
    children
    |> list.index_fold(#(ctx, []), fn(acc, child, i) {
      let #(ctx, rendered) = acc

      let prev_child = find_prev_child(prev, child, i)

      let ReconciledResult(ctx, rendered_child) =
        reconcile(ctx, child, None, prev_child)

      #(ctx, [rendered_child, ..rendered])
    })

  ReconciledResult(
    ctx,
    ReconciledElement(
      element_id,
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
  prev: Option(ReconciledElement),
) -> ReconciledResult {
  let #(ctx, children) =
    children
    |> list.index_fold(#(ctx, []), fn(acc, child, i) {
      let #(ctx, rendered) = acc

      let prev_child = find_prev_child(prev, child, i)

      let ReconciledResult(ctx, rendered_child) =
        reconcile(ctx, child, None, prev_child)

      #(ctx, [rendered_child, ..rendered])
    })

  ReconciledResult(ctx, ReconciledFragment(key, list.reverse(children)))
}

fn component(
  ctx: Context,
  fc: DynamicStatefulComponent,
  key: Option(String),
  props: Dynamic,
  prev: Option(ReconciledElement),
) -> ReconciledResult {
  // Prepare ctx wip (work in progress) for component render
  let ctx = case prev {
    None ->
      // There is no previous rendered element, so this is the first render
      Context(..ctx, wip: ComponentWip(ordered_map.new(), 0, True))
    Some(ReconciledComponent(_, _, _, hooks, _)) ->
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
    Some(ReconciledComponent(_, _, _, _, el)) -> Some(el)
    _ -> None
  }

  let ReconciledResult(ctx, rendered_el) = reconcile(ctx, el, None, prev_el)

  ReconciledResult(ctx, ReconciledComponent(fc, key, props, hooks, rendered_el))
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
fn find_prev_child(prev: Option(ReconciledElement), child: Element, index: Int) {
  let child_key = get_key(child)
  option.or(
    get_prev_matching_child_by_key(prev, child_key),
    get_prev_matching_child_by_index(prev, child, index),
  )
}

fn get_prev_matching_child_by_key(
  prev: Option(ReconciledElement),
  key: Option(String),
) -> Option(ReconciledElement) {
  case prev, key {
    Some(ReconciledElement(_, _, _, _, children)), Some(key) -> {
      find_by_key(children, key)
    }
    Some(ReconciledFragment(_, children)), Some(key) -> {
      find_by_key(children, key)
    }
    _, _ -> None
  }
}

fn find_by_key(children, key) {
  // find a child by given key
  list.find(children, fn(child) {
    case child {
      ReconciledComponent(_, Some(child_key), _, _, _) -> child_key == key
      ReconciledElement(_, _, Some(child_key), _, _) -> child_key == key
      ReconciledFragment(Some(child_key), _) -> child_key == key
      _ -> False
    }
  })
  |> option.from_result()
}

fn get_prev_matching_child_by_index(
  prev: Option(ReconciledElement),
  child: Element,
  index: Int,
) -> Option(ReconciledElement) {
  case prev {
    Some(ReconciledElement(_, _, _, _, children)) -> {
      case element_at(children, index, 0) {
        Ok(prev_child) -> {
          maybe_matching_el(prev_child, child)
        }
        Error(Nil) -> None
      }
    }
    Some(ReconciledFragment(_, children)) -> {
      case element_at(children, index, 0) {
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
  prev_child: ReconciledElement,
  child: Element,
) -> Option(ReconciledElement) {
  let child_key = get_key(child)

  case prev_child, child {
    ReconciledElement(_, prev_tag, prev_key, _, _), Element(tag, ..) -> {
      case prev_tag == tag && prev_key == child_key {
        True -> Some(prev_child)
        False -> None
      }
    }
    ReconciledComponent(prev_fc, prev_key, _, _, _), Component(fc, ..) -> {
      case prev_fc == fc && prev_key == child_key {
        True -> Some(prev_child)
        False -> None
      }
    }
    ReconciledFragment(prev_key, _), Fragment(..) -> {
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

fn text(ctx: Context, t: String) -> ReconciledResult {
  ReconciledResult(ctx, ReconciledText(t))
}

fn custom(ctx: Context, kind: String, data: String) -> ReconciledResult {
  ReconciledResult(ctx, ReconciledCustom(kind, data))
}

pub fn traverse(
  el: ReconciledElement,
  updater: fn(ReconciledElement) -> ReconciledElement,
) -> ReconciledElement {
  case updater(el) {
    ReconciledComponent(fc, key, props, hooks, el) -> {
      ReconciledComponent(fc, key, props, hooks, traverse(el, updater))
    }
    ReconciledElement(id, tag, key, attrs, children) -> {
      ReconciledElement(
        id,
        tag,
        key,
        attrs,
        list.map(children, fn(child) { traverse(child, updater) }),
      )
    }
    ReconciledFragment(key, children) -> {
      ReconciledFragment(
        key,
        list.map(children, fn(child) { traverse(child, updater) }),
      )
    }
    _ -> el
  }
}

pub fn find(
  el: ReconciledElement,
  matches: fn(ReconciledElement) -> Bool,
) -> Result(ReconciledElement, Nil) {
  case matches(el) {
    True -> Ok(el)
    False -> {
      case el {
        ReconciledComponent(_fc, _key, _props, _hooks, el) -> {
          find(el, matches)
        }
        ReconciledElement(_id, _tag, _key, _attrs, children) -> {
          list.find(children, fn(child) {
            case find(child, matches) {
              Ok(_child) -> True
              Error(_) -> False
            }
          })
        }
        ReconciledFragment(_key, children) -> {
          list.find(children, fn(child) {
            case find(child, matches) {
              Ok(_child) -> True
              Error(_) -> False
            }
          })
        }
        _ -> Error(Nil)
      }
    }
  }
}

pub fn append_attribute(
  el: ReconciledElement,
  attr: ReconciledAttribute,
) -> ReconciledElement {
  case el {
    ReconciledComponent(fc, key, props, hooks, el) -> {
      // we need to append the attribute to the component's element
      ReconciledComponent(fc, key, props, hooks, append_attribute(el, attr))
    }
    ReconciledElement(id, tag, key, attrs, children) -> {
      ReconciledElement(id, tag, key, list.append(attrs, [attr]), children)
    }
    ReconciledFragment(key, children) -> {
      // since a fragment is a list of elements, we need to append the attribute to the
      // element's children
      ReconciledFragment(
        key,
        list.map(children, fn(child) { append_attribute(child, attr) }),
      )
    }
    _ -> el
  }
}
