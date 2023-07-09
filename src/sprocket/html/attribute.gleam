import gleam/string
import gleam/dynamic.{Dynamic}
import sprocket/identifiable_callback.{IdentifiableCallback}

pub type Attribute {
  Attribute(name: String, value: Dynamic)
  Event(name: String, identifiable_cb: IdentifiableCallback)
}

pub fn attribute(name: String, value: any) -> Attribute {
  Attribute(name, dynamic.from(value))
}

pub fn event(name: String, identifiable_cb: IdentifiableCallback) -> Attribute {
  Event(name, identifiable_cb)
}

pub fn on_click(identifiable_cb: IdentifiableCallback) -> Attribute {
  event("click", identifiable_cb)
}

pub fn on_change(identifiable_cb: IdentifiableCallback) -> Attribute {
  event("change", identifiable_cb)
}

pub fn on_input(identifiable_cb: IdentifiableCallback) -> Attribute {
  event("input", identifiable_cb)
}

pub fn lang(value: String) -> Attribute {
  attribute("lang", value)
}

pub fn class(value: String) -> Attribute {
  attribute("class", value)
}

pub fn classes(value: List(String)) -> Attribute {
  attribute("class", string.join(value, " "))
}

pub fn href(value: String) -> Attribute {
  attribute("href", value)
}

pub fn rel(value: String) -> Attribute {
  attribute("rel", value)
}

pub fn integrity(value: String) -> Attribute {
  attribute("integrity", value)
}

pub fn crossorigin(value: String) -> Attribute {
  attribute("crossorigin", value)
}

pub fn referrerpolicy(value: String) -> Attribute {
  attribute("referrerpolicy", value)
}

pub fn src(value: String) -> Attribute {
  attribute("src", value)
}

pub fn placeholder(value: String) -> Attribute {
  attribute("placeholder", value)
}

pub fn input_type(value: String) -> Attribute {
  attribute("type", value)
}

pub fn value(value: String) -> Attribute {
  attribute("value", value)
}

pub fn target(value: String) -> Attribute {
  attribute("target", value)
}
