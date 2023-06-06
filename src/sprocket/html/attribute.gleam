import gleam/string
import gleam/dynamic.{Dynamic}

pub type Attribute {
  Attribute(name: String, value: Dynamic)
  Key(value: String)
  Event(name: String, handler: fn() -> Nil)
}

pub fn attribute(name: String, value: any) -> Attribute {
  Attribute(name, dynamic.from(value))
}

pub fn event(name: String, handler: fn() -> Nil) -> Attribute {
  Event(name, handler)
}

pub fn on_click(handler: fn() -> Nil) -> Attribute {
  event("click", handler)
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
