import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{None, Some}
import gleam/result
import ids/cuid
import sprocket/context.{type Element}
import sprocket/internal/logger
import sprocket/internal/patch
import sprocket/internal/reconcile.{type ReconciledResult, ReconciledResult}
import sprocket/internal/reconcilers/recursive.{reconcile}
import sprocket/render.{type Renderer, renderer} as _
import sprocket/renderers/json.{json_renderer} as _
import sprocket/runtime.{
  type ClientMessage, type EventDispatcher, type Runtime, type RuntimeMessage,
  ClientEvent, FullUpdate, InboundClientHookEvent, OutboundClientHookEvent,
  PatchUpdate,
}

pub type Sprocket {
  Sprocket(runtime: Runtime)
}

pub type SprocketError {
  RuntimeStartError
}

/// Starts a new Sprocket runtime with the given element and event dispatcher.
pub fn start(
  el: Element,
  dispatch: EventDispatcher,
) -> Result(Sprocket, SprocketError) {
  case runtime.start(el, dispatch) {
    Ok(r) -> {
      // schedule intitial render
      runtime.render_update(r)

      Ok(Sprocket(r))
    }
    Error(_err) -> {
      Error(RuntimeStartError)
    }
  }
}

/// Handles a client message by passing it to the runtime.
pub fn handle_client_message(spkt: Sprocket, msg: ClientMessage) -> Nil {
  runtime.handle_client_message(spkt.runtime, msg)
}

/// Shuts down the given Sprocket runtime.
pub fn shutdown(spkt: Sprocket) {
  runtime.stop(spkt.runtime)
}

/// Renders the given element as a stateless element using a given renderer.
pub fn render(el: Element, r: Renderer(a)) -> a {
  use render <- renderer(r)

  // Internally this function uses the reconciler with an empty previous element
  // and a placeholder ctx but then discards the ctx and returns the result.
  let assert Ok(cuid_channel) =
    cuid.start()
    |> result.map_error(fn(error) {
      logger.error("render.render: Failed to start a cuid channel")
      error
    })

  let dispatch_client_hook_event = fn(_id, _kind, _payload) { Nil }
  let trigger_reconciliation = fn() { Nil }
  let update_hook = fn(_index, _updater) { Nil }

  let ctx =
    context.new(
      el,
      cuid_channel,
      dispatch_client_hook_event,
      trigger_reconciliation,
      update_hook,
    )

  let ReconciledResult(reconciled: reconciled, ..) =
    reconcile(ctx, el, None, None)

  render(reconciled)
}

/// Returns a human-readable error message for the given SprocketError.
pub fn humanize_error(error: SprocketError) -> String {
  case error {
    RuntimeStartError -> "Failed to start runtime"
  }
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
