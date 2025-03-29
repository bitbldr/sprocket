import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{None, Some}
import sprocket/internal/patch
import sprocket/render.{renderer} as _
import sprocket/renderers/json.{json_renderer} as _
import sprocket/runtime.{
  type RuntimeMessage, ClientEvent, FullUpdate, InboundClientHookEvent,
  OutboundClientHookEvent, PatchUpdate,
}

/// Decoder for client messages.
pub fn client_message_decoder() {
  use message_type <- decode.then(decode.at([0], decode.string))

  case message_type {
    "hook" -> decode.at([1], inbound_client_hook_event_decoder())
    _ -> decode.at([1], client_event_decoder())
  }
}

/// Decoder for inbound client hook events.
fn inbound_client_hook_event_decoder() {
  use element_id <- decode.field("id", decode.string)
  use hook <- decode.field("hook", decode.string)
  use kind <- decode.field("kind", decode.string)
  use payload <- decode.optional_field(
    "payload",
    None,
    decode.optional(decode.dynamic),
  )

  decode.success(InboundClientHookEvent(element_id, hook, kind, payload))
}

fn client_event_decoder() {
  use element_id <- decode.field("id", decode.string)
  use kind <- decode.field("kind", decode.string)
  use payload <- decode.optional_field(
    "payload",
    dynamic.from(Nil),
    decode.dynamic,
  )

  decode.success(ClientEvent(element_id, kind, payload))
}

/// Encodes a runtime message as JSON.
pub fn encode_runtime_message(event: RuntimeMessage) -> Json {
  case event {
    FullUpdate(update) -> {
      use render_json <- renderer(json_renderer())

      json.preprocessed_array([json.string("ok"), render_json(update)])
    }
    PatchUpdate(p) -> {
      json.preprocessed_array([json.string("update"), patch.patch_to_json(p)])
    }
    OutboundClientHookEvent(id, hook, kind, payload) -> {
      let payload_json =
        payload
        |> option.map(encode_payload)
        |> option.map(option.from_result)
        |> option.flatten()

      json.preprocessed_array([
        json.string("hook"),
        case payload_json {
          Some(payload_json) ->
            json.object([
              #("id", json.string(id)),
              #("hook", json.string(hook)),
              #("kind", json.string(kind)),
              #("payload", payload_json),
            ])
          None ->
            json.object([
              #("id", json.string(id)),
              #("hook", json.string(hook)),
              #("kind", json.string(kind)),
            ])
        },
      ])
    }
  }
}

fn encode_payload(payload: Dynamic) -> Result(Json, List(decode.DecodeError)) {
  decode.run(payload, payload_decoder())
}

fn payload_decoder() {
  // This is a recursive decoder that can decode any JSON payload. This call
  // is required to prevent a infinite loop in the recursive decoder.
  use <- decode.recursive

  decode.one_of(decode.string |> decode.map(json.string), or: [
    decode.int |> decode.map(json.int),
    decode.float |> decode.map(json.float),
    decode.bool |> decode.map(json.bool),
    decode.list(payload_decoder()) |> decode.map(json.preprocessed_array),
    decode.dict(decode.string, payload_decoder())
      |> decode.map(fn(d) {
        d
        |> dict.to_list()
        |> json.object
      }),
  ])
}
