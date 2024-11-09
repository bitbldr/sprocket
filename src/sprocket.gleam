import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic, field, optional_field}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import ids/cuid
import sprocket/component.{component}
import sprocket/context.{type Element, type FunctionalComponent, Updater}
import sprocket/internal/logger
import sprocket/internal/patch
import sprocket/internal/reconcile.{type ReconciledResult, ReconciledResult}
import sprocket/internal/reconcilers/recursive.{reconcile}
import sprocket/render.{type Renderer, renderer} as _
import sprocket/renderers/json.{json_renderer} as _
import sprocket/runtime.{
  type RenderedUpdate, type Runtime, FullUpdate, PatchUpdate,
}

pub type WSSend =
  fn(String) -> Result(Nil, Nil)

pub type CSRFValidator =
  fn(String) -> Result(Nil, Nil)

pub type SprocketOpts {
  SprocketOpts(debug: Bool)
}

pub type Sprocket(p) {
  Sprocket(
    component: FunctionalComponent(p),
    initialize_props: fn(Option(PropList)) -> p,
    runtime: Option(Runtime),
    ws_send: WSSend,
    csrf_validator: CSRFValidator,
    opts: Option(SprocketOpts),
  )
}

pub fn new(
  component: FunctionalComponent(p),
  initialize_props: fn(Option(PropList)) -> p,
  ws_send: WSSend,
  csrf_validator: CSRFValidator,
  opts: Option(SprocketOpts),
) -> Sprocket(p) {
  Sprocket(
    component: component,
    initialize_props: initialize_props,
    runtime: None,
    ws_send: ws_send,
    csrf_validator: csrf_validator,
    opts: opts,
  )
}

type Payload {
  JoinPayload(csrf_token: String, initial_props: Option(Dict(String, String)))
  EventPayload(kind: String, id: String, payload: Dynamic)
  HookEventPayload(id: String, event: String, payload: Option(Dynamic))
  EmptyPayload(nothing: Option(String))
}

pub type Response(p) {
  Joined(spkt: Sprocket(p))
  Empty
}

pub type PropList =
  List(#(String, String))

/// Handle a message from the websocket. This function is called when a message is received
/// from the websocket. It will find the sprocket that is associated with the websocket and
/// pass the message to the sprocket. The sprocket will then handle the message and send
/// a response back to the websocket.
pub fn handle_ws(spkt: Sprocket(p), msg: String) -> Result(Response(p), String) {
  case
    json.decode(
      msg,
      dynamic.any([decode_join, decode_event, decode_hook_event, decode_empty]),
    )
  {
    Ok(#("join", JoinPayload(csrf, initial_props))) -> {
      case spkt.csrf_validator(csrf) {
        Ok(_) ->
          case connect(spkt, option.map(initial_props, dict.to_list)) {
            Ok(runtime) -> Ok(Joined(Sprocket(..spkt, runtime: Some(runtime))))
            Error(_) -> Error("Error connecting to runtime")
          }
        Error(_) -> {
          logger.error("Invalid CSRF token")

          let _ =
            InvalidCSRFToken
            |> error_to_json()
            |> spkt.ws_send()

          Error("Invalid CSRF token")
        }
      }
    }
    Ok(#("event", EventPayload(kind, event_id, payload))) -> {
      logger.debug("Event: " <> kind <> " " <> event_id)

      use runtime <- require_runtime(spkt)

      runtime.process_event(runtime, event_id, payload)

      Ok(Empty)
    }
    Ok(#("hook:event", HookEventPayload(id, event, payload))) -> {
      logger.debug("Hook Event: " <> event <> " " <> id)

      use runtime <- require_runtime(spkt)

      let reply_emitter = fn(event, payload) {
        hook_event_to_json(id, event, payload)
        |> spkt.ws_send()
      }

      runtime.process_client_hook(runtime, id, event, payload, reply_emitter)

      Ok(Empty)
    }
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

fn require_runtime(
  spkt: Sprocket(p),
  cb: fn(Runtime) -> Result(a, String),
) -> Result(a, String) {
  case spkt {
    Sprocket(runtime: Some(runtime), ..) -> cb(runtime)
    _ ->
      Error(
        "Sprocket runtime not found. Runtime must be started before handling messages",
      )
  }
}

/// Handles client websocket connection initialization.
fn connect(
  spkt: Sprocket(p),
  initial_props: Option(List(#(String, String))),
) -> Result(Runtime, Nil) {
  let debug =
    option.map(spkt.opts, fn(opts) { opts.debug })
    |> option.unwrap(False)

  let updater =
    Updater(send: fn(update) {
      update_to_json(update, debug)
      |> json.to_string()
      |> spkt.ws_send()
    })

  let emitter = fn(id, event, payload) {
    let _ =
      hook_event_to_json(id, event, payload)
      |> spkt.ws_send()

    Ok(Nil)
  }

  let view = component(spkt.component, spkt.initialize_props(initial_props))

  case runtime.start(view, updater, Some(emitter)) {
    Ok(r) -> {
      // schedule intitial render
      runtime.render_update(r)

      Ok(r)
    }
    Error(_err) -> {
      logger.error("Error starting runtime")

      Error(Nil)
    }
  }
}

fn decode_join(data: Dynamic) {
  data
  |> dynamic.tuple2(
    dynamic.string,
    dynamic.decode2(
      JoinPayload,
      field("csrf", dynamic.string),
      optional_field(
        "initialProps",
        dynamic.dict(dynamic.string, dynamic.string),
      ),
    ),
  )
}

fn decode_event(data: Dynamic) {
  data
  |> dynamic.tuple2(
    dynamic.string,
    dynamic.decode3(
      EventPayload,
      field("kind", dynamic.string),
      field("id", dynamic.string),
      field("payload", dynamic.dynamic),
    ),
  )
}

fn decode_hook_event(data: Dynamic) {
  data
  |> dynamic.tuple2(
    dynamic.string,
    dynamic.decode3(
      HookEventPayload,
      field("id", dynamic.string),
      field("name", dynamic.string),
      optional_field("payload", dynamic.dynamic),
    ),
  )
}

fn decode_empty(data: Dynamic) {
  data
  |> dynamic.tuple2(
    dynamic.string,
    dynamic.decode1(EmptyPayload, optional_field("nothing", dynamic.string)),
  )
}

fn update_to_json(update: RenderedUpdate, debug: Bool) -> Json {
  case update {
    PatchUpdate(p) -> {
      json.preprocessed_array([
        json.string("update"),
        patch.patch_to_json(p, debug),
        json.object([#("debug", json.bool(debug))]),
      ])
    }
    FullUpdate(update) -> {
      use render_json <- renderer(json_renderer())

      json.preprocessed_array([json.string("ok"), render_json(update)])
    }
  }
}

fn hook_event_to_json(
  id: String,
  event: String,
  payload: Option(String),
) -> String {
  json.preprocessed_array([
    json.string("hook:event"),
    case payload {
      Some(payload) ->
        json.object([
          #("id", json.string(id)),
          #("kind", json.string(event)),
          #("payload", json.string(payload)),
        ])
      None ->
        json.object([#("id", json.string(id)), #("kind", json.string(event))])
    },
  ])
  |> json.to_string()
}

type ConnectError {
  ConnectError
  PreflightNotFound
  InvalidCSRFToken
}

fn error_to_json(error: ConnectError) {
  json.preprocessed_array([
    json.string("error"),
    case error {
      ConnectError ->
        json.object([
          #("code", json.string("connect_error")),
          #("msg", json.string("Unable to connect to session")),
        ])
      PreflightNotFound ->
        json.object([
          #("code", json.string("preflight_not_found")),
          #("msg", json.string("No preflight found")),
        ])
      InvalidCSRFToken ->
        json.object([
          #("code", json.string("invalid_csrf_token")),
          #("msg", json.string("Invalid CSRF token")),
        ])
    },
  ])
  |> json.to_string()
}

/// Cleanup a sprocket. This function is called when a websocket is closed. It will find
/// the sprocket that is associated with the websocket and stop it.
///
/// Its important to call this function when the websocket connection is terminated.
pub fn cleanup(spkt: Sprocket(p)) {
  spkt.runtime
  |> option.map(fn(r) { runtime.stop(r) })
}

// Renders the given element as a stateless element using a given renderer.
pub fn render(el: Element, r: Renderer(a)) -> a {
  use render <- renderer(r)

  // Internally this function uses the reconciler with an empty previous element
  // and a placeholder ctx but then discards the ctx and returns the result.
  let assert Ok(cuid_channel) =
    cuid.start()
    |> result.map_error(fn(error) {
      logger.error("render.render: Failed to start cuid channel")
      error
    })

  let render_update = fn() { Nil }
  let update_hook = fn(_index, _updater) { Nil }

  let ctx = context.new(el, cuid_channel, None, render_update, update_hook)

  let ReconciledResult(reconciled: reconciled, ..) =
    reconcile(ctx, el, None, None)

  render(reconciled)
}
