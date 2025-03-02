import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic, field, optional_field}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
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
  type EventDispatcher, type Runtime, ClientHookEvent, FullUpdate, PatchUpdate,
}

pub type StatefulComponent(p) =
  context.StatefulComponent(p)

pub type RuntimeEvent =
  runtime.Event

pub type Sprocket {
  Sprocket(runtime: Runtime)
}

pub type SprocketError {
  RuntimeStartError
}

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

pub type Message {
  JoinMessage(
    id: Option(String),
    csrf_token: String,
    initial_props: Option(Dict(String, String)),
  )
  EventMessage(element_id: String, kind: String, payload: Dynamic)
  ClientHookEventMessage(
    element_id: String,
    hook: String,
    kind: String,
    payload: Option(Dynamic),
  )
}

pub fn process_event(
  spkt: Sprocket,
  element_id: String,
  kind: String,
  payload: Dynamic,
) -> Nil {
  runtime.process_event(spkt.runtime, element_id, kind, payload)
}

pub fn process_client_hook_event(
  spkt: Sprocket,
  element_id: String,
  hook: String,
  kind: String,
  payload: Option(Dynamic),
) -> Nil {
  runtime.process_client_hook_event(
    spkt.runtime,
    element_id,
    hook,
    kind,
    payload,
  )
}

pub fn shutdown(spkt: Sprocket) {
  runtime.stop(spkt.runtime)
}

// Renders the given element as a stateless element using a given renderer.
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
  let schedule_update = fn() { Nil }
  let update_hook = fn(_index, _updater) { Nil }

  let ctx =
    context.new(
      el,
      cuid_channel,
      dispatch_client_hook_event,
      schedule_update,
      update_hook,
    )

  let ReconciledResult(reconciled: reconciled, ..) =
    reconcile(ctx, el, None, None)

  render(reconciled)
}

pub fn humanize_error(error: SprocketError) -> String {
  case error {
    RuntimeStartError -> "Failed to start runtime"
  }
}

pub fn decode_message(msg: String) {
  case
    json.decode(
      msg,
      dynamic.any([decode_join, decode_client_hook_event, decode_client_event]),
    )
  {
    Ok(#("join", payload)) -> Ok(payload)
    Ok(#("hook:event", payload)) -> Ok(payload)
    Ok(#("event", payload)) -> Ok(payload)
    Error(_) -> {
      logger.error("Error decoding message: " <> msg)

      Error("Error decoding message")
    }
    _ -> {
      logger.error("Unexpected payload type: " <> msg)

      Error("Unexpected payload type")
    }
  }
}

fn decode_join(data: Dynamic) {
  data
  |> dynamic.tuple2(
    dynamic.string,
    dynamic.decode3(
      JoinMessage,
      optional_field("id", dynamic.string),
      field("csrf", dynamic.string),
      optional_field(
        "initialProps",
        dynamic.dict(dynamic.string, dynamic.string),
      ),
    ),
  )
}

pub fn decode_client_hook_event(data: Dynamic) {
  data
  |> dynamic.tuple2(
    dynamic.string,
    dynamic.decode4(
      ClientHookEventMessage,
      field("id", dynamic.string),
      field("hook", dynamic.string),
      field("kind", dynamic.string),
      optional_field("payload", dynamic.dynamic),
    ),
  )
}

pub fn decode_client_event(data: Dynamic) {
  data
  |> dynamic.tuple2(
    dynamic.string,
    dynamic.decode3(
      EventMessage,
      field("id", dynamic.string),
      field("kind", dynamic.string),
      field("payload", dynamic.dynamic),
    ),
  )
}

pub fn event_to_json(event: RuntimeEvent) -> Json {
  case event {
    FullUpdate(update) -> {
      use render_json <- renderer(json_renderer())

      json.preprocessed_array([json.string("ok"), render_json(update)])
    }
    PatchUpdate(p) -> {
      json.preprocessed_array([json.string("update"), patch.patch_to_json(p)])
    }
    ClientHookEvent(id, hook, kind, payload) -> {
      let payload_json =
        payload
        |> option.map(payload_to_json)
        |> option.flatten()

      json.preprocessed_array([
        json.string("hook:emit"),
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

fn payload_to_json(payload: Dynamic) -> Option(Json) {
  case dynamic.classify(payload) {
    "String" ->
      payload
      |> dynamic.string()
      |> result.map(json.string)
      |> option.from_result()
    "Int" ->
      payload |> dynamic.int() |> result.map(json.int) |> option.from_result()
    "Float" ->
      payload
      |> dynamic.float()
      |> result.map(json.float)
      |> option.from_result()
    "Boolean" ->
      payload |> dynamic.bool() |> result.map(json.bool) |> option.from_result()
    _ -> None
  }
}
