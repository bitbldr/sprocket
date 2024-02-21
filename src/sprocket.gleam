import gleam/result
import gleam/option.{type Option, None, Some}
import gleam/dynamic.{type Dynamic, field, optional_field}
import gleam/json.{type Json}
import ids/cuid
import sprocket/runtime.{type Runtime}
import sprocket/context.{
  type Dispatcher, type Element, type IdentifiableHandler, Client, Dispatcher,
  IdentifiableHandler, Updater, callback_param_from_string,
}
import sprocket/internal/reconcile.{
  type ReconciledElement, type ReconciledResult, ReconciledResult,
}
import sprocket/internal/reconcilers/recursive.{reconcile}
import sprocket/internal/render.{renderer} as _
import sprocket/internal/renderers/json.{json_renderer} as _
import sprocket/internal/renderers/html.{html_renderer}
import sprocket/internal/patch.{type Patch}
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
    send_update: WSSend,
    csrf_validator: CSRFValidator,
    opts: Option(SprocketOpts),
  )
}

pub fn new(
  view: Element,
  send_update: WSSend,
  csrf_validator: CSRFValidator,
  opts: Option(SprocketOpts),
) -> Sprocket {
  Sprocket(
    runtime: None,
    view: view,
    send_update: send_update,
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
      logger.info("New client joined")

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
            |> spkt.send_update()

          Error("Invalid CSRF token")
        }
      }
    }
    Ok(#("event", EventPayload(kind, event_id, value))) -> {
      logger.info("Event: " <> kind <> " " <> event_id)

      use runtime <- require_runtime(spkt)

      case runtime.get_handler(runtime, event_id) {
        Ok(context.IdentifiableHandler(_, handler_fn)) -> {
          // call the event handler function
          value
          |> option.map(callback_param_from_string)
          |> handler_fn()

          Ok(Empty)
        }
        _ -> {
          logger.error("Error: no handler defined for id: " <> event_id)

          Ok(Empty)
        }
      }
    }
    Ok(#("hook:event", HookEventPayload(hook_id, name, payload))) -> {
      logger.info("Hook Event: " <> hook_id <> " " <> name)

      use runtime <- require_runtime(spkt)

      case runtime.get_client_hook(runtime, hook_id) {
        Ok(Client(_id, _name, handle_event)) -> {
          // TODO: implement reply dispatcher
          let reply_dispatcher = fn(event, payload) {
            hook_event_to_json(hook_id, event, payload)
            |> spkt.send_update()
          }

          option.map(handle_event, fn(handle_event) {
            handle_event(name, payload, reply_dispatcher)
          })

          Ok(Empty)
        }
        _ -> {
          Error("No client hook defined for id: " <> hook_id)
        }
      }
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
      let _ =
        update_to_json(update, debug)
        |> spkt.send_update()

      Ok(Nil)
    })

  let dispatcher =
    Dispatcher(dispatch: fn(id, event, payload) {
      let _ =
        hook_event_to_json(id, event, payload)
        |> spkt.send_update()

      Ok(Nil)
    })

  case runtime.start(spkt.view, Some(updater), Some(dispatcher)) {
    Ok(runtime) -> {
      logger.info("Sprocket runtime connected!")

      // intitial live render
      let rendered = runtime.render(runtime)

      let _ =
        rendered
        |> rendered_to_json()
        |> json.to_string()
        |> spkt.send_update()

      Ok(runtime)
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

fn update_to_json(update: Patch, debug: Bool) -> String {
  json.preprocessed_array([
    json.string("update"),
    patch.patch_to_json(update, debug),
    json.object([#("debug", json.bool(debug))]),
  ])
  |> json.to_string()
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

fn rendered_to_json(update: ReconciledElement) -> Json {
  use render_json <- renderer(json_renderer())

  json.preprocessed_array([json.string("ok"), render_json(update)])
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
