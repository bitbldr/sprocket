import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic}
import sprocket/context.{
  type Attribute, type IdentifiableHandler, Attribute, Event,
}

// Events

pub fn event(name: String, handler: IdentifiableHandler) -> Attribute {
  Event(name, handler)
}

pub fn on_blur(handler: IdentifiableHandler) -> Attribute {
  event("blur", handler)
}

pub fn on_change(handler: IdentifiableHandler) -> Attribute {
  event("change", handler)
}

pub fn on_check(handler: IdentifiableHandler) -> Attribute {
  event("check", handler)
}

pub fn on_click(handler: IdentifiableHandler) -> Attribute {
  event("click", handler)
}

pub fn on_dblclick(handler: IdentifiableHandler) -> Attribute {
  event("dblclick", handler)
}

pub fn on_drag(handler: IdentifiableHandler) -> Attribute {
  event("drag", handler)
}

pub fn on_dragend(handler: IdentifiableHandler) -> Attribute {
  event("dragend", handler)
}

pub fn on_dragenter(handler: IdentifiableHandler) -> Attribute {
  event("dragenter", handler)
}

pub fn on_dragleave(handler: IdentifiableHandler) -> Attribute {
  event("dragleave", handler)
}

pub fn on_dragover(handler: IdentifiableHandler) -> Attribute {
  event("dragover", handler)
}

pub fn on_dragstart(handler: IdentifiableHandler) -> Attribute {
  event("dragstart", handler)
}

pub fn on_drop(handler: IdentifiableHandler) -> Attribute {
  event("drop", handler)
}

pub fn on_focus(handler: IdentifiableHandler) -> Attribute {
  event("focus", handler)
}

pub fn on_focusin(handler: IdentifiableHandler) -> Attribute {
  event("focusin", handler)
}

pub fn on_focusout(handler: IdentifiableHandler) -> Attribute {
  event("focusout", handler)
}

pub fn on_input(handler: IdentifiableHandler) -> Attribute {
  event("input", handler)
}

pub fn on_keydown(handler: IdentifiableHandler) -> Attribute {
  event("keydown", handler)
}

pub fn on_keyup(handler: IdentifiableHandler) -> Attribute {
  event("keyup", handler)
}

pub fn on_mousedown(handler: IdentifiableHandler) -> Attribute {
  event("mousedown", handler)
}

pub fn on_mouseenter(handler: IdentifiableHandler) -> Attribute {
  event("mouseenter", handler)
}

pub fn on_mouseleave(handler: IdentifiableHandler) -> Attribute {
  event("mouseleave", handler)
}

pub fn on_mousemove(handler: IdentifiableHandler) -> Attribute {
  event("mousemove", handler)
}

pub fn on_mouseout(handler: IdentifiableHandler) -> Attribute {
  event("mouseout", handler)
}

pub fn on_mouseover(handler: IdentifiableHandler) -> Attribute {
  event("mouseover", handler)
}

pub fn on_mouseup(handler: IdentifiableHandler) -> Attribute {
  event("mouseup", handler)
}

pub fn on_scroll(handler: IdentifiableHandler) -> Attribute {
  event("scroll", handler)
}

pub fn on_submit(handler: IdentifiableHandler) -> Attribute {
  event("submit", handler)
}

pub fn on_touchcancel(handler: IdentifiableHandler) -> Attribute {
  event("touchcancel", handler)
}

pub fn on_touchend(handler: IdentifiableHandler) -> Attribute {
  event("touchend", handler)
}

pub fn on_touchmove(handler: IdentifiableHandler) -> Attribute {
  event("touchmove", handler)
}

pub fn on_touchstart(handler: IdentifiableHandler) -> Attribute {
  event("touchstart", handler)
}

pub fn on_wheel(handler: IdentifiableHandler) -> Attribute {
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
