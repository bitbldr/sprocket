import gleam/string

pub type HtmlAttr {
  HtmlAttr(name: String, value: String)
  Key(value: String)
}

pub fn class(value: String) -> HtmlAttr {
  HtmlAttr("class", value)
}

pub fn classes(value: List(String)) -> HtmlAttr {
  HtmlAttr("class", string.join(value, " "))
}
