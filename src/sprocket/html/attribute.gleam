import gleam/string
import gleam/dynamic.{Dynamic}

pub type IdentifiableCallback {
  IdentifiableCallback(id: String, cb: fn() -> Nil)
}

pub type Attribute {
  Attribute(name: String, value: Dynamic)
  Key(value: String)
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

pub fn src(value: String) -> Attribute {
  attribute("src", value)
}
