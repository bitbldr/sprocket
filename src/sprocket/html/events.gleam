import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/result
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

pub fn on_focus(handler: IdentifiableHandler) -> Attribute {
  event("focus", handler)
}

pub fn on_input(handler: IdentifiableHandler) -> Attribute {
  event("input", handler)
}

pub fn on_keydown(handler: IdentifiableHandler) -> Attribute {
  event("keydown", handler)
}

pub fn on_keypress(handler: IdentifiableHandler) -> Attribute {
  event("keypress", handler)
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

pub fn on_submit(handler: IdentifiableHandler) -> Attribute {
  event("submit", handler)
}

// Decoders used to extract values from events

/// 
/// Decode the value from an event `event.target.value`.
pub fn decode_value(event: Dynamic) -> Result(String, List(DecodeError)) {
  event
  |> dynamic.field("target", dynamic.field("value", dynamic.string))
}

// Decode the checked state from an event `event.target.checked`.
pub fn decode_checked(event: Dynamic) -> Result(Bool, List(DecodeError)) {
  event
  |> dynamic.field("target", dynamic.field("checked", dynamic.bool))
}

/// Decode the mouse position from any event that has a `clientX` and `clientY`.
pub fn decode_mouse_position(
  event: Dynamic,
) -> Result(#(Int, Int), List(DecodeError)) {
  use x <- result.then(dynamic.field("clientX", dynamic.int)(event))
  use y <- result.then(dynamic.field("clientY", dynamic.int)(event))

  Ok(#(x, y))
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
