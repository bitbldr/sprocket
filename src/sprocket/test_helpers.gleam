import gleam/bool.{guard}
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp
import sprocket/html/events
import sprocket/internal/context.{type Element}
import sprocket/internal/reconcile.{
  type ReconciledElement, ReconciledAttribute, ReconciledElement,
  ReconciledEventHandler,
}
import sprocket/internal/reconcilers/recursive
import sprocket/internal/utils/common.{dynamic_from}
import sprocket/internal/utils/time
import sprocket/internal/utils/unique
import sprocket/render.{renderer}
import sprocket/renderers/html.{html_renderer}
import sprocket/runtime.{type Runtime}

pub fn connect(el: Element) {
  let assert Ok(spkt) = runtime.start(el, fn(_) { Ok(Nil) })

  spkt
}

/// Renders the current state of the sprocket runtime as HTML
pub fn render_html(spkt: Runtime) {
  use render_html <- renderer(html_renderer())

  let html =
    runtime.reconcile_immediate(spkt)
    |> render_html()

  #(spkt, html)
}

/// Renders a reconciled element as HTML
pub fn render_el_html(el: ReconciledElement) {
  use render_html <- renderer(html_renderer())

  render_html(el)
}

/// Creates a mouse move event
pub fn mouse_move(x: Int, y: Int) -> Event {
  MouseMoveEvent(events.MouseEvent(x, y, False, False, False, False))
}

/// Creates a keydown event
pub fn key_down(key: String, code: String) -> Event {
  KeyDownEvent(events.KeyEvent(key, code, False, False, False, False))
}

pub type Event {
  ClickEvent
  InputEvent(value: String)
  MouseMoveEvent(e: events.MouseEvent)
  FormChangeEvent(data: Dict(String, String))
  FormSubmitEvent(data: Dict(String, String))
  BlurEvent
  FocusEvent
  KeyDownEvent(e: events.KeyEvent)
}

/// Renders an event to the given sprocket runtime
pub fn render_event(spkt: Runtime, event: Event, html_id: String) {
  case runtime.get_reconciled(spkt) {
    Some(reconciled) -> {
      let found =
        recursive.find(reconciled, fn(el: ReconciledElement) {
          case el {
            ReconciledElement(_id, _tag, _key, attrs, _children) -> {
              // try and find id attr that matches the given id
              let matching_id_attr =
                attrs
                |> list.find(fn(attr) {
                  case attr {
                    ReconciledAttribute("id", id) if id == html_id -> True
                    _ -> False
                  }
                })

              case matching_id_attr {
                Ok(_) -> True
                _ -> False
              }
            }
            _ -> False
          }
        })

      case found {
        Ok(ReconciledElement(id, _tag, _key, attrs, _children)) -> {
          let #(event_kind, event_payload) = case event {
            ClickEvent -> #("click", dynamic_from(Nil))
            InputEvent(value) -> #(
              "input",
              dynamic_from(
                dict.from_list([
                  #("target", dict.from_list([#("value", value)])),
                ]),
              ),
            )
            MouseMoveEvent(e) -> #(
              "mousemove",
              dynamic_from(
                dict.new()
                |> dict.insert("clientX", dynamic_from(e.x))
                |> dict.insert("clientY", dynamic_from(e.y))
                |> dict.insert("ctrlKey", dynamic_from(e.ctrl_key))
                |> dict.insert("shiftKey", dynamic_from(e.shift_key))
                |> dict.insert("altKey", dynamic_from(e.alt_key))
                |> dict.insert("metaKey", dynamic_from(e.meta_key)),
              ),
            )
            FormChangeEvent(data) -> #(
              "change",
              dynamic_from(dict.from_list([#("formData", data)])),
            )
            FormSubmitEvent(data) -> #(
              "submit",
              dynamic_from(dict.from_list([#("formData", data)])),
            )
            BlurEvent -> #("blur", dynamic_from(Nil))
            FocusEvent -> #("focus", dynamic_from(Nil))
            KeyDownEvent(e) -> #(
              "keydown",
              dynamic_from(
                dict.new()
                |> dict.insert("key", dynamic_from(e.key))
                |> dict.insert("code", dynamic_from(e.code))
                |> dict.insert("ctrlKey", dynamic_from(False))
                |> dict.insert("shiftKey", dynamic_from(False))
                |> dict.insert("altKey", dynamic_from(False))
                |> dict.insert("metaKey", dynamic_from(False)),
              ),
            )
          }

          // find click event handler id
          let rendered_event_handler =
            attrs
            |> list.find(fn(attr) {
              case attr {
                ReconciledEventHandler(element_id, kind) ->
                  element_id == id && kind == event_kind
                _ -> False
              }
            })

          case rendered_event_handler {
            Ok(ReconciledEventHandler(element_id, kind)) -> {
              case
                runtime.process_client_message_immediate(
                  spkt,
                  unique.to_string(element_id),
                  kind,
                  event_payload,
                )
              {
                Ok(_) -> spkt
                _ -> panic
              }
            }
            _ -> {
              panic as "No handler found for event"
            }
          }
        }
        _ -> {
          panic_no_element_with_id()
        }
      }
    }
    None -> {
      panic_no_reconciled()
    }
  }

  spkt
}

pub type FindElementBy {
  ById(String)
  ByClass(String)
  ByTag(String)
  ByPredicate(fn(ReconciledElement) -> Bool)
}

pub fn find_element(
  spkt: Runtime,
  one_that is_desired: FindElementBy,
) -> Result(ReconciledElement, Nil) {
  case runtime.get_reconciled(spkt) {
    Some(reconciled) -> {
      recursive.find(reconciled, check_predicate(_, is_desired))
    }
    None -> {
      panic_no_reconciled()
    }
  }
}

pub fn assert_element(maybe_el: Result(ReconciledElement, Nil)) {
  case maybe_el {
    Ok(el) -> el
    _ -> panic as "Element not found"
  }
}

pub fn assert_regex(maybe_el: Result(ReconciledElement, Nil), regex: String) {
  case maybe_el {
    Ok(el) -> {
      let html = render_el_html(el)

      let assert Ok(re) = regexp.from_string(regex)
      regexp.check(re, html)
    }
    _ -> panic as "Element not found"
  }
}

pub fn has_element(spkt: Runtime, one_that is_desired: FindElementBy) -> Bool {
  case find_element(spkt, is_desired) {
    Ok(_) -> True
    _ -> False
  }
}

fn check_predicate(el: ReconciledElement, is_desired: FindElementBy) {
  case is_desired {
    ById(id) -> find_by_matching_attr(el, "id", id)
    ByClass(class_name) -> find_by_matching_attr(el, "class", class_name)
    ByTag(tag_name) -> {
      case el {
        ReconciledElement(_id, tag, _key, _attrs, _children) if tag == tag_name ->
          True
        _ -> False
      }
    }
    ByPredicate(func) -> func(el)
  }
}

pub fn wait_while(predicate: fn() -> Bool, timeout: Int) -> Bool {
  case
    wait_helper(
      fn() { !predicate() },
      timeout,
      time.system_time(time.Millisecond),
    )
  {
    True -> True
    False -> panic as "Timeout waiting for condition"
  }
}

pub fn wait_until(predicate: fn() -> Bool, timeout: Int) -> Bool {
  case wait_helper(predicate, timeout, time.system_time(time.Millisecond)) {
    True -> True
    False -> panic as "Timeout waiting for condition"
  }
}

fn wait_helper(predicate: fn() -> Bool, timeout: Int, started_at: Int) -> Bool {
  use <- guard(
    when: time.system_time(time.Millisecond) - started_at > timeout,
    return: False,
  )
  use <- guard(when: predicate(), return: True)

  wait_helper(predicate, timeout, started_at)
}

fn find_by_matching_attr(el, key, expected_value) {
  case el {
    ReconciledElement(_id, _tag, _key, attrs, _children) -> {
      let matching_attr =
        attrs
        |> list.find(fn(attr) {
          case attr {
            ReconciledAttribute(attr_key, attr_value)
              if attr_key == key && attr_value == expected_value
            -> True
            _ -> False
          }
        })

      case matching_attr {
        Ok(_) -> True
        _ -> False
      }
    }
    _ -> False
  }
}

fn panic_no_reconciled() {
  panic as "Nothing reconciled! This is likely because the view has not been rendered yet."
}

fn panic_no_element_with_id() {
  panic as "No element found with matching id"
}
