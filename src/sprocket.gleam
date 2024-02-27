import gleam/result
import gleam/option.{type Option, None, Some}
import gleam/dynamic.{type Dynamic, field, optional_field}
import gleam/json.{type Json}
import ids/cuid
import sprocket/runtime.{
  type RenderedUpdate, type Runtime, FullUpdate, PatchUpdate,
}
import sprocket/context.{type Dispatcher, type Element, Dispatcher, Updater}
import sprocket/internal/reconcile.{type ReconciledResult, ReconciledResult}
import sprocket/internal/reconcilers/recursive.{reconcile}
import sprocket/internal/render.{renderer} as _
import sprocket/internal/renderers/json.{json_renderer} as _
import sprocket/internal/renderers/html.{html_renderer}
import sprocket/internal/patch
import sprocket/internal/logger

pub type WSSend =
  fn(String) -> Result(Nil, Nil)

pub type CSRFValidator =
  fn(String) -> Result(Nil, Nil)

pub type SprocketOpts {
  SprocketOpts(debug: Bool)
}

pub type Sprocket {
  Sprocket(
    runtime: Option(Runtime),
    view: Element,
    ws_send: WSSend,
    csrf_validator: CSRFValidator,
    opts: Option(SprocketOpts),
  )
}

pub fn new(
  view: Element,
  ws_send: WSSend,
  csrf_validator: CSRFValidator,
  opts: Option(SprocketOpts),
) -> Sprocket {
  Sprocket(
    runtime: None,
    view: view,
    ws_send: ws_send,
    csrf_validator: csrf_validator,
    opts: opts,
  )
}

type Payload {
  JoinPayload(csrf_token: String)
  EventPayload(kind: String, id: String, value: Option(String))
  HookEventPayload(id: String, event: String, payload: Option(Dynamic))
  EmptyPayload(nothing: Option(String))
}

pub type Response {
  Joined(spkt: Sprocket)
  Empty
}

/// Handle a message from the websocket. This function is called when a message is received
/// from the websocket. It will find the sprocket that is associated with the websocket and
/// pass the message to the sprocket. The sprocket will then handle the message and send
/// a response back to the websocket.
pub fn handle_ws(spkt: Sprocket, msg: String) -> Result(Response, String) {
  case
    json.decode(
      msg,
      dynamic.any([decode_join, decode_event, decode_hook_event, decode_empty]),
    )
  {
    Ok(#("join", JoinPayload(csrf))) -> {
      case spkt.csrf_validator(csrf) {
        Ok(_) ->
          case connect(spkt) {
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
    Ok(#("event", EventPayload(kind, event_id, value))) -> {
      logger.debug("Event: " <> kind <> " " <> event_id)

      use runtime <- require_runtime(spkt)

      runtime.process_event(runtime, event_id, value)

      Ok(Empty)
    }
    Ok(#("hook:event", HookEventPayload(id, event, payload))) -> {
      logger.debug("Hook Event: " <> event <> " " <> id)

      use runtime <- require_runtime(spkt)

      let reply_dispatcher = fn(event, payload) {
        hook_event_to_json(id, event, payload)
        |> spkt.ws_send()
      }

      runtime.process_client_hook(runtime, id, event, payload, reply_dispatcher)

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
  spkt: Sprocket,
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
fn connect(spkt: Sprocket) -> Result(Runtime, Nil) {
  let debug =
    option.map(spkt.opts, fn(opts) { opts.debug })
    |> option.unwrap(False)

  let updater =
    Updater(send: fn(update) {
      update_to_json(update, debug)
      |> json.to_string()
      |> spkt.ws_send()
    })

  let dispatcher =
    Dispatcher(dispatch: fn(id, event, payload) {
      let _ =
        hook_event_to_json(id, event, payload)
        |> spkt.ws_send()

      Ok(Nil)
    })

  case runtime.start(spkt.view, updater, Some(dispatcher)) {
    Ok(r) -> {
      // schedule intitial live render
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
    dynamic.decode1(JoinPayload, field("csrf", dynamic.string)),
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
      optional_field("value", dynamic.string),
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
pub fn cleanup(spkt: Sprocket) {
  spkt.runtime
  |> option.map(fn(r) { runtime.stop(r) })
}

// Renders the given element as a stateless element to html.
pub fn render_html(el: Element) -> String {
  use render_html <- renderer(html_renderer())

  // Internally this function uses the reconciler with an empty previous element
  // and a placeholder ctx but then discards the ctx and returns the result.
  let assert Ok(cuid_channel) =
    cuid.start()
    |> result.map_error(fn(error) {
      logger.error("render.render: Failed to start cuid channel")
      error
    })

  let ctx =
    context.new(el, cuid_channel, None, fn() { Nil }, fn(_index, _updater) {
      Nil
    })

  let ReconciledResult(reconciled: reconciled, ..) =
    reconcile(ctx, el, None, None)

  render_html(reconciled)
}
