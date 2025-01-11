import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic}
import sprocket/context.{type Attribute, Attribute, Event}

// Events

type Handler =
  fn(Dynamic) -> Nil

pub fn event(name: String, handler: Handler) -> Attribute {
  Event(name, handler)
}

pub fn on_blur(handler: Handler) -> Attribute {
  event("blur", handler)
}

pub fn on_change(handler: Handler) -> Attribute {
  event("change", handler)
}

pub fn on_check(handler: Handler) -> Attribute {
  event("check", handler)
}

pub fn on_click(handler: Handler) -> Attribute {
  event("click", handler)
}

pub fn on_dblclick(handler: Handler) -> Attribute {
  event("dblclick", handler)
}

pub fn on_drag(handler: Handler) -> Attribute {
  event("drag", handler)
}

pub fn on_dragend(handler: Handler) -> Attribute {
  event("dragend", handler)
}

pub fn on_dragenter(handler: Handler) -> Attribute {
  event("dragenter", handler)
}

pub fn on_dragleave(handler: Handler) -> Attribute {
  event("dragleave", handler)
}

pub fn on_dragover(handler: Handler) -> Attribute {
  event("dragover", handler)
}

pub fn on_dragstart(handler: Handler) -> Attribute {
  event("dragstart", handler)
}

pub fn on_drop(handler: Handler) -> Attribute {
  event("drop", handler)
}

pub fn on_focus(handler: Handler) -> Attribute {
  event("focus", handler)
}

pub fn on_focusin(handler: Handler) -> Attribute {
  event("focusin", handler)
}

pub fn on_focusout(handler: Handler) -> Attribute {
  event("focusout", handler)
}

pub fn on_input(handler: Handler) -> Attribute {
  event("input", handler)
}

pub fn on_keydown(handler: Handler) -> Attribute {
  event("keydown", handler)
}

pub fn on_keyup(handler: Handler) -> Attribute {
  event("keyup", handler)
}

pub fn on_mousedown(handler: Handler) -> Attribute {
  event("mousedown", handler)
}

pub fn on_mouseenter(handler: Handler) -> Attribute {
  event("mouseenter", handler)
}

pub fn on_mouseleave(handler: Handler) -> Attribute {
  event("mouseleave", handler)
}

pub fn on_mousemove(handler: Handler) -> Attribute {
  event("mousemove", handler)
}

pub fn on_mouseout(handler: Handler) -> Attribute {
  event("mouseout", handler)
}

pub fn on_mouseover(handler: Handler) -> Attribute {
  event("mouseover", handler)
}

pub fn on_mouseup(handler: Handler) -> Attribute {
  event("mouseup", handler)
}

pub fn on_scroll(handler: Handler) -> Attribute {
  event("scroll", handler)
}

pub fn on_submit(handler: Handler) -> Attribute {
  event("submit", handler)
}

pub fn on_touchcancel(handler: Handler) -> Attribute {
  event("touchcancel", handler)
}

pub fn on_touchend(handler: Handler) -> Attribute {
  event("touchend", handler)
}

pub fn on_touchmove(handler: Handler) -> Attribute {
  event("touchmove", handler)
}

pub fn on_touchstart(handler: Handler) -> Attribute {
  event("touchstart", handler)
}

pub fn on_wheel(handler: Handler) -> Attribute {
  event("wheel", handler)
}

// Decoders used to extract values from events

/// 
/// Decode the value from an event `event.target.value`.
pub fn decode_target_value(event: Dynamic) -> Result(String, List(DecodeError)) {
  event
  |> dynamic.field("target", dynamic.field("value", dynamic.string))
}

// Decode the checked state from an event `event.target.checked`.
pub fn decode_target_checked(event: Dynamic) -> Result(Bool, List(DecodeError)) {
  event
  |> dynamic.field("target", dynamic.field("checked", dynamic.bool))
}

pub type MouseEvent {
  MouseEvent(
    x: Int,
    y: Int,
    ctrl_key: Bool,
    shift_key: Bool,
    alt_key: Bool,
    meta_key: Bool,
  )
}

/// Decode a mouse event that includes position `clientX` and `clientY` and modifier keys.
pub fn decode_mouse_event(
  event: Dynamic,
) -> Result(MouseEvent, List(DecodeError)) {
  dynamic.decode6(
    MouseEvent,
    dynamic.field("clientX", dynamic.int),
    dynamic.field("clientY", dynamic.int),
    dynamic.field("ctrlKey", dynamic.bool),
    dynamic.field("shiftKey", dynamic.bool),
    dynamic.field("altKey", dynamic.bool),
    dynamic.field("metaKey", dynamic.bool),
  )(event)
}

pub type KeyEvent {
  KeyEvent(
    key: String,
    code: String,
    ctrl_key: Bool,
    shift_key: Bool,
    alt_key: Bool,
    meta_key: Bool,
  )
}

// Decode a key event that includes the key `key`, the code `code`, and modifier keys.
pub fn decode_key_event(event: Dynamic) -> Result(KeyEvent, List(DecodeError)) {
  dynamic.decode6(
    KeyEvent,
    dynamic.field("key", dynamic.string),
    dynamic.field("code", dynamic.string),
    dynamic.field("ctrlKey", dynamic.bool),
    dynamic.field("shiftKey", dynamic.bool),
    dynamic.field("altKey", dynamic.bool),
    dynamic.field("metaKey", dynamic.bool),
  )(event)
}

/// Decode the form data from a form submit event.
pub fn decode_form_data(
  event: Dynamic,
) -> Result(Dict(String, String), List(DecodeError)) {
  dynamic.field("formData", dynamic.dict(dynamic.string, dynamic.string))(event)
}

/// Decode the key from a key press event.
pub fn decode_keypress(event: Dynamic) -> Result(String, List(DecodeError)) {
  event |> dynamic.field("key", dynamic.string)
}
