import gleam/string

pub type HtmlAttr {
  HtmlAttr(name: String, value: String)
  Key(value: String)
}

pub fn attr(name: String, value: String) -> HtmlAttr {
  HtmlAttr(name, value)
}

pub fn class(value: String) -> HtmlAttr {
  attr("class", value)
}

pub fn classes(value: List(String)) -> HtmlAttr {
  attr("class", string.join(value, " "))
}

pub fn href(value: String) -> HtmlAttr {
  attr("href", value)
}

pub fn rel(value: String) -> HtmlAttr {
  attr("rel", value)
}

pub fn src(value: String) -> HtmlAttr {
  attr("src", value)
}
