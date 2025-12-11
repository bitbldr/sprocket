import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import sprocket_shared/vdom

pub fn main() {
  gleeunit.main()
}

pub fn roundtrip_element_test() {
  let node =
    vdom.Element(
      "root-id",
      "div",
      Some("key-1"),
      [vdom.Attribute("class", "c1"), vdom.Attribute("data-x", "y")],
      [vdom.Event("click", "evt-1")],
      [vdom.ClientHook("focus")],
      [
        vdom.Text("hi"),
        vdom.Component(None, vdom.Custom("raw", "{\"ok\":true}")),
        vdom.Fragment(
          Some("frag"),
          [vdom.Element("child", "span", None, [], [], [], [])],
        ),
      ],
    )

  let encoded = vdom.encode(node)
  should.equal(Ok(node), vdom.decode(encoded))
}

pub fn text_is_string_test() {
  let encoded = vdom.encode(vdom.Text("hello"))
  should.equal(json.string("hello"), encoded)
  should.equal(Ok(vdom.Text("hello")), vdom.decode(encoded))
}
