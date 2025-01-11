import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic}
import sprocket/context.{type Attribute, Attribute, Event}

// Events

type EventCallback =
  fn(Dynamic) -> Nil

pub fn event(name: String, cb: EventCallback) -> Attribute {
  Event(name, cb)
}

pub fn on_blur(cb: EventCallback) -> Attribute {
  event("blur", cb)
}

pub fn on_change(cb: EventCallback) -> Attribute {
  event("change", cb)
}

pub fn on_check(cb: EventCallback) -> Attribute {
  event("check", cb)
}

pub fn on_click(cb: EventCallback) -> Attribute {
  event("click", cb)
}

pub fn on_dblclick(cb: EventCallback) -> Attribute {
  event("dblclick", cb)
}

pub fn on_drag(cb: EventCallback) -> Attribute {
  event("drag", cb)
}

pub fn on_dragend(cb: EventCallback) -> Attribute {
  event("dragend", cb)
}

pub fn on_dragenter(cb: EventCallback) -> Attribute {
  event("dragenter", cb)
}

pub fn on_dragleave(cb: EventCallback) -> Attribute {
  event("dragleave", cb)
}

pub fn on_dragover(cb: EventCallback) -> Attribute {
  event("dragover", cb)
}

pub fn on_dragstart(cb: EventCallback) -> Attribute {
  event("dragstart", cb)
}

pub fn on_drop(cb: EventCallback) -> Attribute {
  event("drop", cb)
}

pub fn on_focus(cb: EventCallback) -> Attribute {
  event("focus", cb)
}

pub fn on_focusin(cb: EventCallback) -> Attribute {
  event("focusin", cb)
}

pub fn on_focusout(cb: EventCallback) -> Attribute {
  event("focusout", cb)
}

pub fn on_input(cb: EventCallback) -> Attribute {
  event("input", cb)
}

pub fn on_keydown(cb: EventCallback) -> Attribute {
  event("keydown", cb)
}

pub fn on_keyup(cb: EventCallback) -> Attribute {
  event("keyup", cb)
}

pub fn on_mousedown(cb: EventCallback) -> Attribute {
  event("mousedown", cb)
}

pub fn on_mouseenter(cb: EventCallback) -> Attribute {
  event("mouseenter", cb)
}

pub fn on_mouseleave(cb: EventCallback) -> Attribute {
  event("mouseleave", cb)
}

pub fn on_mousemove(cb: EventCallback) -> Attribute {
  event("mousemove", cb)
}

pub fn on_mouseout(cb: EventCallback) -> Attribute {
  event("mouseout", cb)
}

pub fn on_mouseover(cb: EventCallback) -> Attribute {
  event("mouseover", cb)
}

pub fn on_mouseup(cb: EventCallback) -> Attribute {
  event("mouseup", cb)
}

pub fn on_scroll(cb: EventCallback) -> Attribute {
  event("scroll", cb)
}

pub fn on_submit(cb: EventCallback) -> Attribute {
  event("submit", cb)
}

pub fn on_touchcancel(cb: EventCallback) -> Attribute {
  event("touchcancel", cb)
}

pub fn on_touchend(cb: EventCallback) -> Attribute {
  event("touchend", cb)
}

pub fn on_touchmove(cb: EventCallback) -> Attribute {
  event("touchmove", cb)
}

pub fn on_touchstart(cb: EventCallback) -> Attribute {
  event("touchstart", cb)
}

pub fn on_wheel(cb: EventCallback) -> Attribute {
  event("wheel", cb)
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
