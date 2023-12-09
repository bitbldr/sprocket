import gleam/io
import gleam/list
import gleam/dynamic.{type Dynamic, field, optional_field}
import gleam/option.{type Option, None, Some}
import gleam/json
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import ids/cuid
import sprocket/sprocket.{type Sprocket}
import sprocket/context.{type Element, Client, Dispatcher, Updater}
import sprocket/html/attributes.{callback_param_from_string}
import sprocket/render.{type RenderedElement}
import sprocket/internal/render/json as json_renderer
import sprocket/internal/patch.{type Patch}
import sprocket/internal/logger
import sprocket/internal/constants.{call_timeout}
import sprocket/internal/utils/unique.{type Unique}

pub type CSRFValidator =
  fn(String) -> Result(Nil, Nil)

pub type Cassette =
  Subject(Message)

pub type State {
  State(
    sprockets: List(Sprocket),
    debug: Bool,
    csrf_validator: CSRFValidator,
    cuid_channel: Subject(cuid.Message),
  )
}

pub type Message {
  Shutdown
  GetState(reply_with: Subject(State))
  PushSprocket(sprocket: Sprocket)
  GetSprocket(reply_with: Subject(Result(Sprocket, Nil)), id: Unique)
  PopSprocket(reply_with: Subject(Result(Sprocket, Nil)), id: Unique)
}

fn handle_message(message: Message, state: State) -> actor.Next(Message, State) {
  case message {
    Shutdown -> {
      actor.Stop(process.Normal)
    }

    GetState(reply_with) -> {
      process.send(reply_with, state)
      actor.continue(state)
    }

    PushSprocket(sprocket) -> {
      let updated_sprockets =
        list.reverse([sprocket, ..list.reverse(state.sprockets)])

      actor.continue(State(..state, sprockets: updated_sprockets))
    }

    GetSprocket(reply_with, id) -> {
      let spkt =
        list.find(
          state.sprockets,
          fn(s) {
            case sprocket.get_id(s) {
              Ok(spkt_id) -> unique.equals(spkt_id, id)
              Error(_) -> False
            }
          },
        )

      process.send(reply_with, spkt)

      actor.continue(state)
    }

    PopSprocket(reply_with, id) -> {
      let sprocket =
        list.find(
          state.sprockets,
          fn(s) {
            case sprocket.get_id(s) {
              Ok(spkt_id) -> unique.equals(spkt_id, id)
              Error(_) -> False
            }
          },
        )

      process.send(reply_with, sprocket)

      case sprocket {
        Ok(sprocket) -> {
          sprocket.stop(sprocket)

          let updated_sprockets =
            list.filter(state.sprockets, fn(s) { sprocket != s })

          let new_state = State(..state, sprockets: updated_sprockets)

          actor.continue(new_state)
        }

        Error(_) -> actor.continue(state)
      }
    }
  }
}

pub type CassetteOpts {
  CassetteOpts(debug: Bool)
}

/// Start the cassette. This is intended to only be called once during web server
/// initiliazation.
/// 
/// The cassette is a long running process that manages the state of
/// all sprockets and preflights.
pub fn start(
  csrf_validator: CSRFValidator,
  opts: Option(CassetteOpts),
) -> Cassette {
  let assert Ok(cuid_channel) = cuid.start()
  let assert Ok(ca) =
    actor.start(
      State(
        sprockets: [],
        debug: option.map(opts, fn(opts) { opts.debug })
        |> option.unwrap(False),
        csrf_validator: csrf_validator,
        cuid_channel: cuid_channel,
      ),
      handle_message,
    )

  ca
}

/// Stop the cassette
pub fn stop(ca: Cassette) {
  process.send(ca, Shutdown)
}

/// Get the current state of the cassette. Mostly intended for unit tests and debugging.
pub fn get_state(ca: Cassette) {
  process.call(ca, GetState(_), call_timeout())
}

/// Pushes a sprocket to the cassette.
pub fn push_sprocket(ca: Cassette, sprocket: Sprocket) {
  process.send(ca, PushSprocket(sprocket))
}

/// Gets a sprocket from the cassette.
pub fn get_sprocket(ca: Cassette, ws: Unique) {
  process.call(ca, GetSprocket(_, ws), call_timeout())
}

/// Pops a sprocket from the cassette.
pub fn pop_sprocket(ca: Cassette, ws: Unique) {
  process.call(ca, PopSprocket(_, ws), call_timeout())
}

fn get_cuid_channel(ca: Cassette) {
  case get_state(ca) {
    State(cuid_channel: cuid_channel, ..) -> cuid_channel
  }
}

/// Validates a CSRF token.
fn validate_csrf(ca: Cassette, csrf: String) {
  case get_state(ca) {
    State(csrf_validator: csrf_validator, ..) -> csrf_validator(csrf)
  }
}

type Payload {
  JoinPayload(csrf_token: String)
  EventPayload(kind: String, id: String, value: Option(String))
  HookEventPayload(id: String, event: String, value: Option(Dynamic))
  EmptyPayload(nothing: Option(String))
}

pub fn client_message(
  ca: Cassette,
  id: Unique,
  view: Element,
  msg: String,
  ws_send: fn(String) -> Result(Nil, Nil),
) -> Result(Nil, Nil) {
  case
    json.decode(
      msg,
      dynamic.any([decode_join, decode_event, decode_hook_event, decode_empty]),
    )
  {
    Ok(#("join", JoinPayload(csrf))) -> {
      logger.info("New client joined")

      case validate_csrf(ca, csrf) {
        Ok(_) -> connect(ca, id, view, ws_send)
        Error(_) -> {
          logger.error("Invalid CSRF token")
          ws_send(error_to_json(InvalidCSRFToken))
        }
      }
    }
    Ok(#("event", EventPayload(kind, event_id, value))) -> {
      logger.info("Event: " <> kind <> " " <> event_id)

      case get_sprocket(ca, id) {
        Ok(sprocket) -> {
          case sprocket.get_handler(sprocket, event_id) {
            Ok(context.IdentifiableHandler(_, handler)) -> {
              // call the event handler
              handler(option.map(
                value,
                fn(value) { callback_param_from_string(value) },
              ))
              |> Ok
            }
            _ -> Ok(Nil)
          }
        }
        _ -> Error(Nil)
      }
    }
    Ok(#("hook:event", HookEventPayload(hook_id, name, value))) -> {
      logger.info("Hook Event: " <> hook_id <> " " <> name)

      case get_sprocket(ca, id) {
        Ok(sprocket) -> {
          case sprocket.get_client_hook(sprocket, hook_id) {
            Ok(Client(_id, _name, handle_event)) -> {
              // TODO: implement reply dispatcher
              let reply_dispatcher = fn(event, payload) {
                ws_send(hook_event_to_json(hook_id, event, payload))
              }

              option.map(
                handle_event,
                fn(handle_event) { handle_event(name, value, reply_dispatcher) },
              )

              Ok(Nil)
            }
            _ -> {
              logger.error("Error: no client hook defined for id: " <> hook_id)
              io.debug(value)
              panic
            }
          }
        }
        _ -> Error(Nil)
      }

      Ok(Nil)
    }
    Error(e) -> {
      logger.error("Error decoding message")
      io.debug(e)

      Error(Nil)
    }
  }
}

/// Handles client websocket connection initialization.
fn connect(
  ca: Cassette,
  id: Unique,
  view: Element,
  ws_send: fn(String) -> Result(Nil, Nil),
) {
  let updater =
    Updater(send: fn(update) {
      let _ = ws_send(update_to_json(update, get_state(ca).debug))
      Ok(Nil)
    })

  let dispatcher =
    Dispatcher(dispatch: fn(id, event, payload) {
      let _ = ws_send(hook_event_to_json(id, event, payload))
      Ok(Nil)
    })

  let sprocket =
    sprocket.start(
      id,
      view,
      get_cuid_channel(ca),
      Some(updater),
      Some(dispatcher),
    )

  push_sprocket(ca, sprocket)

  logger.info("Sprocket connected! " <> unique.to_string(id))

  // intitial live render
  let rendered = sprocket.render(sprocket)

  ws_send(rendered_to_json(rendered))
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
      optional_field("value", dynamic.dynamic),
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
  value: Option(String),
) -> String {
  json.preprocessed_array([
    json.string("hook:event"),
    case value {
      Some(value) ->
        json.object([
          #("id", json.string(id)),
          #("kind", json.string(event)),
          #("value", json.string(value)),
        ])
      None ->
        json.object([#("id", json.string(id)), #("kind", json.string(event))])
    },
  ])
  |> json.to_string()
}

fn rendered_to_json(update: RenderedElement) -> String {
  json.preprocessed_array([
    json.string("ok"),
    json_renderer.renderer().render(update),
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
