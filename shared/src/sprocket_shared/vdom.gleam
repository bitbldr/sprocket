import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Attribute applied to an element.
pub type Attribute {
  Attribute(name: String, value: String)
}

/// Event handler placeholder; `id` identifies the handler on the server.
pub type Event {
  Event(kind: String, id: String)
}

/// Client hook marker; used for client-side hook wiring.
pub type ClientHook {
  ClientHook(name: String)
}

/// Target-agnostic virtual node shape shared between BEAM and JS targets.
pub type Node {
  Element(
    id: String,
    tag: String,
    key: Option(String),
    attrs: List(Attribute),
    events: List(Event),
    hooks: List(ClientHook),
    children: List(Node),
  )
  Component(key: Option(String), node: Node)
  Fragment(key: Option(String), children: List(Node))
  Text(String)
  Custom(kind: String, data: String)
}

/// Encode a VDOM node to JSON compatible with existing Sprocket clients.
pub fn encode(node: Node) -> Json {
  case node {
    Element(id, tag, key, attrs, events, hooks, children) ->
      element(id, tag, key, attrs, events, hooks, children)
    Component(key, node) -> component(key, node)
    Fragment(key, children) -> fragment(key, children)
    Text(text) -> json.string(text)
    Custom(kind, data) -> custom(kind, data)
  }
}

/// Decode a VDOM node from JSON. Returns an error if the JSON shape is invalid.
pub fn decode(json_value: Json) -> Result(Node, json.DecodeError) {
  json.parse(json.to_string(json_value), node_decoder())
}

fn element(
  id: String,
  tag: String,
  key: Option(String),
  attrs: List(Attribute),
  events: List(Event),
  hooks: List(ClientHook),
  children: List(Node),
) -> Json {
  let encoded_attrs =
    attrs
    |> list.map(fn(attr) {
      case attr {
        Attribute(name, value) -> #(name, json.string(value))
      }
    })

  let encoded_events =
    events
    |> list.map(fn(event) {
      case event {
        Event(kind, id) ->
          json.object([
            #("kind", json.string(kind)),
            #("id", json.string(id)),
          ])
      }
    })

  let encoded_hooks =
    hooks
    |> list.map(fn(hook) {
      case hook {
        ClientHook(name) ->
          json.object([#("name", json.string(name))])
      }
    })

  let encoded_children =
    children
    |> list.index_map(fn(child, i) { #(int.to_string(i), encode(child)) })

  [
    #("type", json.string("element")),
    #("id", json.string(id)),
    #("tag", json.string(tag)),
    #("attrs", json.object(encoded_attrs)),
    #("events", json.preprocessed_array(encoded_events)),
    #("hooks", json.preprocessed_array(encoded_hooks)),
  ]
  |> maybe_append_string("key", key)
  |> list.append(encoded_children)
  |> json.object()
}

fn component(key: Option(String), node: Node) -> Json {
  [#("type", json.string("component"))]
  |> maybe_append_string("key", key)
  |> list.append([#("0", encode(node))])
  |> json.object()
}

fn fragment(key: Option(String), children: List(Node)) -> Json {
  let encoded_children =
    children
    |> list.index_map(fn(child, i) { #(int.to_string(i), encode(child)) })

  [#("type", json.string("fragment"))]
  |> maybe_append_string("key", key)
  |> list.append(encoded_children)
  |> json.object()
}

fn custom(kind: String, data: String) -> Json {
  [
    #("type", json.string("custom")),
    #("kind", json.string(kind)),
    #("data", json.string(data)),
  ]
  |> json.object()
}

fn node_decoder() {
  use <- decode.recursive

  decode.one_of(decode.string |> decode.map(Text), [typed_node_decoder()])
}

fn typed_node_decoder() {
  decode.field("type", decode.string, fn(node_type) {
    case node_type {
      "element" -> element_decoder()
      "component" -> component_decoder()
      "fragment" -> fragment_decoder()
      "custom" -> custom_decoder()
      _ -> decode.failure(Text(""), expected: "vdom node")
    }
  })
}

fn element_decoder() {
  decode.field("id", decode.string, fn(id) {
    decode.field("tag", decode.string, fn(tag) {
      decode.optional_field(
        "key",
        None,
        decode.optional(decode.string),
        fn(key) {
          decode.field("attrs", attrs_decoder(), fn(attrs) {
            decode.field("events", events_decoder(), fn(events) {
              decode.field("hooks", hooks_decoder(), fn(hooks) {
                decode.map(
                  decode.dict(decode.string, dynamic_decoder()),
                  fn(children) {
                    Element(
                      id,
                      tag,
                      key,
                      attrs,
                      events,
                      hooks,
                      decode_children(children),
                    )
                  },
                )
              })
            })
          })
        },
      )
    })
  })
}

fn component_decoder() {
  decode.optional_field(
    "key",
    None,
    decode.optional(decode.string),
    fn(key) {
      decode.field("0", node_decoder(), fn(node) {
        decode.success(Component(key, node))
      })
    },
  )
}

fn fragment_decoder() {
  decode.optional_field(
    "key",
    None,
    decode.optional(decode.string),
    fn(key) {
      decode.map(
        decode.dict(decode.string, dynamic_decoder()),
        fn(children) { Fragment(key, decode_children(children)) },
      )
    },
  )
}

fn custom_decoder() {
  decode.field("kind", decode.string, fn(kind) {
    decode.field("data", decode.string, fn(data) {
      decode.success(Custom(kind, data))
    })
  })
}

fn attrs_decoder() {
  decode.map(decode.dict(decode.string, decode.string), fn(attrs) {
    attrs
    |> dict.to_list()
    |> list.map(fn(entry) {
      let #(name, value) = entry
      Attribute(name, value)
    })
    |> list.sort(fn(a, b) {
      let Attribute(name_a, _) = a
      let Attribute(name_b, _) = b
      string.compare(name_a, name_b)
    })
  })
}

fn events_decoder() {
  decode.map(
    decode.list(event_decoder()),
    fn(events) {
      events
    },
  )
}

fn event_decoder() {
  use kind <- decode.field("kind", decode.string)
  use id <- decode.field("id", decode.string)

  decode.success(Event(kind, id))
}

fn hooks_decoder() {
  decode.map(
    decode.list(hook_decoder()),
    fn(hooks) {
      hooks
    },
  )
}

fn hook_decoder() {
  use name <- decode.field("name", decode.string)

  decode.success(ClientHook(name))
}

fn dynamic_decoder() -> decode.Decoder(Dynamic) {
  decode.new_primitive_decoder("Dynamic", fn(data) { Ok(data) })
}

fn decode_children(children: dict.Dict(String, Dynamic)) -> List(Node) {
  let ordered: List(#(Int, Node)) =
    children
    |> dict.to_list()
    |> list.fold([], fn(acc, entry) {
      let #(key, value) = entry

      case int.parse(key) {
        Ok(order) ->
          case decode.run(value, node_decoder()) {
            Ok(node) -> [#(order, node), ..acc]
            Error(_) -> acc
          }
        Error(_) -> acc
      }
    })
    |> list.sort(fn(a, b) {
      let #(order_a, _) = a
      let #(order_b, _) = b
      int.compare(order_a, order_b)
    })

  ordered
  |> list.map(fn(pair) {
    let #(_, node) = pair
    node
  })
}

fn maybe_append_string(
  builder: List(#(String, Json)),
  key: String,
  value: Option(String),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> list.append(builder, [#(key, json.string(v))])
    None -> builder
  }
}
