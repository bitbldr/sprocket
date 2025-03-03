import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import ids/cuid
import sprocket/component
import sprocket/context.{type Element}
import sprocket/internal/logger
import sprocket/internal/patch
import sprocket/internal/reconcile.{type ReconciledResult, ReconciledResult}
import sprocket/internal/reconcilers/recursive.{reconcile}
import sprocket/render.{type Renderer, renderer} as _
import sprocket/renderers/json.{json_renderer} as _
import sprocket/runtime.{
  type ClientMessage, type EventDispatcher, type Runtime, type RuntimeMessage,
  FullUpdate, OutboundClientHookEvent, PatchUpdate,
}

// Re-export library types and functions for convenience
pub type StatefulComponent(p) =
  context.StatefulComponent(p)

pub const component = component.component

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

pub fn handle_client_message(spkt: Sprocket, msg: ClientMessage) -> Nil {
  runtime.handle_client_message(spkt.runtime, msg)
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

pub fn runtime_message_to_json(event: RuntimeMessage) -> Json {
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
