import gleam/dynamic
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string_builder
import sprocket/context.{
  type Attribute, type IdentifiableHandler, Attribute, ClientHook, Event,
}
import sprocket/internal/utils/unique.{type Unique}

pub fn attribute(name: String, value: any) -> Attribute {
  Attribute(name, dynamic.from(value))
}

pub fn event(name: String, handler: IdentifiableHandler) -> Attribute {
  Event(name, handler)
}

pub fn client_hook(id: Unique, name: String) -> Attribute {
  ClientHook(id, name)
}

pub fn on_click(handler: IdentifiableHandler) -> Attribute {
  event("click", handler)
}

pub fn on_doubleclick(handler: IdentifiableHandler) -> Attribute {
  event("doubleclick", handler)
}

pub fn on_change(handler: IdentifiableHandler) -> Attribute {
  event("change", handler)
}

pub fn on_input(handler: IdentifiableHandler) -> Attribute {
  event("input", handler)
}

pub fn media(value: String) -> Attribute {
  attribute("media", value)
}

pub fn role(value: String) -> Attribute {
  attribute("role", value)
}

pub fn xmlns(value: String) -> Attribute {
  attribute("xmlns", value)
}

pub fn xmlns_xlink(value: String) -> Attribute {
  attribute("xmlns_xlink", value)
}

pub fn accept(value: String) -> Attribute {
  attribute("accept", value)
}

pub fn accept_charset(value: String) -> Attribute {
  attribute("accept-charset", value)
}

pub fn action(value: String) -> Attribute {
  attribute("action", value)
}

pub fn alt(value: String) -> Attribute {
  attribute("alt", value)
}

pub fn async() -> Attribute {
  attribute("async", "true")
}

pub fn autocapitalize(value: String) -> Attribute {
  attribute("autocapitalize", value)
}

pub fn autocomplete(value: String) -> Attribute {
  attribute("autocomplete", value)
}

pub fn autofocus() -> Attribute {
  attribute("autofocus", "true")
}

pub fn autoplay() -> Attribute {
  attribute("autoplay", "true")
}

pub fn capture(value: String) -> Attribute {
  attribute("capture", value)
}

pub fn charset(value: String) -> Attribute {
  attribute("charset", value)
}

pub fn checked() -> Attribute {
  attribute("checked", "true")
}

pub fn cite(value: String) -> Attribute {
  attribute("cite", value)
}

pub fn class(value: String) -> Attribute {
  attribute("class", value)
}

pub fn classes(value: List(Option(String))) -> Attribute {
  attribute(
    "class",
    list.fold(value, string_builder.new(), fn(sb, v) {
      case v {
        None -> sb
        Some(v) ->
          case string_builder.is_empty(sb) {
            True -> string_builder.append(sb, v)
            False -> string_builder.append(sb, " " <> v)
          }
      }
    })
      |> string_builder.to_string(),
  )
}

pub fn content(value: String) -> Attribute {
  attribute("content", value)
}

pub fn contenteditable() -> Attribute {
  attribute("contenteditable", "true")
}

pub fn crossorigin(value: String) -> Attribute {
  attribute("crossorigin", value)
}

pub fn defer() -> Attribute {
  attribute("defer", "true")
}

pub fn disabled() -> Attribute {
  attribute("disabled", "true")
}

pub fn draggable() -> Attribute {
  attribute("draggable", "true")
}

pub fn for(value: String) -> Attribute {
  attribute("for", value)
}

pub fn formaction(value: String) -> Attribute {
  attribute("formaction", value)
}

pub fn height(value: String) -> Attribute {
  attribute("height", value)
}

pub fn href(value: String) -> Attribute {
  attribute("href", value)
}

pub fn http_equiv(value: String) -> Attribute {
  attribute("http-equiv", value)
}

pub fn id(value: String) -> Attribute {
  attribute("id", value)
}

pub fn input_type(value: String) -> Attribute {
  attribute("type", value)
}

pub fn integrity(value: String) -> Attribute {
  attribute("integrity", value)
}

pub fn lang(value: String) -> Attribute {
  attribute("lang", value)
}

pub fn loop() -> Attribute {
  attribute("loop", "true")
}

pub fn method(value: String) -> Attribute {
  attribute("method", value)
}

pub fn name(value: String) -> Attribute {
  attribute("name", value)
}

pub fn placeholder(value: String) -> Attribute {
  attribute("placeholder", value)
}

pub fn preload() -> Attribute {
  attribute("preload", "true")
}

pub fn property(value: String) -> Attribute {
  attribute("property", value)
}

pub fn readonly() -> Attribute {
  attribute("readonly", "true")
}

pub fn referrerpolicy(value: String) -> Attribute {
  attribute("referrerpolicy", value)
}

pub fn rel(value: String) -> Attribute {
  attribute("rel", value)
}

pub fn selected() -> Attribute {
  attribute("selected", "true")
}

pub fn src(value: String) -> Attribute {
  attribute("src", value)
}

pub fn style(value: String) -> Attribute {
  attribute("style", value)
}

pub fn tabindex(value: String) -> Attribute {
  attribute("tabindex", value)
}

pub fn target(value: String) -> Attribute {
  attribute("target", value)
}

pub fn title(value: String) -> Attribute {
  attribute("title", value)
}

pub fn value(value: String) -> Attribute {
  attribute("value", value)
}

pub fn width(value: String) -> Attribute {
  attribute("width", value)
}
