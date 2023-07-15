import gleam/list
import gleam/string_builder
import gleam/option.{None, Option, Some}
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

pub fn charset(value: String) -> Attribute {
  attribute("charset", value)
}

pub fn http_equiv(value: String) -> Attribute {
  attribute("http-equiv", value)
}

pub fn name(value: String) -> Attribute {
  attribute("name", value)
}

pub fn content(value: String) -> Attribute {
  attribute("content", value)
}

pub fn id(value: String) -> Attribute {
  attribute("id", value)
}

pub fn class(value: String) -> Attribute {
  attribute("class", value)
}

pub fn classes(value: List(Option(String))) -> Attribute {
  attribute(
    "class",
    list.fold(
      value,
      string_builder.new(),
      fn(sb, v) {
        case v {
          None -> sb
          Some(v) ->
            case string_builder.is_empty(sb) {
              True -> string_builder.append(sb, v)
              False -> string_builder.append(sb, " " <> v)
            }
        }
      },
    )
    |> string_builder.to_string(),
  )
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

pub fn data(name: String, value: String) -> Attribute {
  attribute("data-" <> name, value)
}
