import gleam/io
import gleam/list
import gleam/result
import gleam/dynamic.{type Dynamic, field, optional_field}
import gleam/option.{type Option, None, Some}
import gleam/json
import gleam/function.{identity}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor.{type StartError, Spec}
import ids/cuid
import sprocket/runtime.{type Runtime}
import sprocket/context.{
  type Element, Client, Dispatcher, Updater, callback_param_from_string,
}
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
    sprockets: List(Runtime),
    debug: Bool,
    csrf_validator: CSRFValidator,
    cuid_channel: Subject(cuid.Message),
  )
}

pub type Message {
  Shutdown
  GetState(reply_with: Subject(State))
  PushSprocket(sprocket: Runtime)
  GetSprocket(reply_with: Subject(Result(Runtime, Nil)), id: Unique)
  PopSprocket(reply_with: Subject(Result(Nil, Nil)), id: Unique)
  GetCUIDChannel(reply_with: Subject(Subject(cuid.Message)))
  GetCSRFValidator(reply_with: Subject(CSRFValidator))
  GetDebug(reply_with: Subject(Bool))
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
            case runtime.get_id(s) {
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
            case runtime.get_id(s) {
              Ok(spkt_id) -> unique.equals(spkt_id, id)
              Error(_) -> False
            }
          },
        )

      case sprocket {
        Ok(sprocket) -> {
          runtime.stop(sprocket)

          let updated_sprockets =
            list.filter(state.sprockets, fn(s) { sprocket != s })

          let new_state = State(..state, sprockets: updated_sprockets)

          process.send(reply_with, Ok(Nil))

          actor.continue(new_state)
        }

        Error(_) -> {
          logger.error(
            "Failed to pop sprocket with id: " <> unique.to_string(id) <> " from cassette",
          )

          process.send(reply_with, Error(Nil))

          actor.continue(state)
        }
      }
    }

    GetCUIDChannel(reply_with) -> {
      process.send(reply_with, state.cuid_channel)
      actor.continue(state)
    }

    GetCSRFValidator(reply_with) -> {
      process.send(reply_with, state.csrf_validator)
      actor.continue(state)
    }

    GetDebug(reply_with) -> {
      process.send(reply_with, state.debug)
      actor.continue(state)
    }
  }
}

pub type CassetteOpts {
  CassetteOpts(debug: Bool)
}

/// Start the cassette. This is intended to only be called once during web server
/// initiliazation.
/// 
/// The cassette is a long running service process that manages the state of
/// all sprocket runtimes.
pub fn start(
  csrf_validator: CSRFValidator,
  opts: Option(CassetteOpts),
) -> Result(Cassette, StartError) {
  let init = fn() {
    let self = process.new_subject()
    let assert Ok(cuid_channel) =
      cuid.start()
      |> result.map_error(fn(error) {
        logger.error("cassette.start: error starting cuid process")
        error
      })

    let state =
      State(
        sprockets: [],
        debug: option.map(opts, fn(opts) { opts.debug })
        |> option.unwrap(False),
        csrf_validator: csrf_validator,
        cuid_channel: cuid_channel,
      )

    let selector = process.selecting(process.new_selector(), self, identity)

    actor.Ready(state, selector)
  }

  actor.start_spec(Spec(init, call_timeout, handle_message))
}

/// Stop the cassette
pub fn stop(ca: Cassette) {
  process.send(ca, Shutdown)
}

/// Get the current state of the cassette. Mostly intended for unit tests and debugging.
pub fn get_state(ca: Cassette) {
  case process.try_call(ca, GetState(_), call_timeout) {
    Ok(state) -> state
    Error(err) -> {
      logger.error("Error getting cassette state")
      io.debug(err)
      panic
    }
  }
}

/// Pushes a sprocket runtime into the cassette.
pub fn push_sprocket(ca: Cassette, sprocket: Runtime) {
  process.send(ca, PushSprocket(sprocket))
}

/// Gets a sprocket from the cassette.
pub fn get_sprocket(ca: Cassette, ws: Unique) -> Result(Runtime, Nil) {
  case process.try_call(ca, GetSprocket(_, ws), call_timeout) {
    Ok(sprocket) -> sprocket
    Error(err) -> {
      logger.error("Error getting sprocket")
      io.debug(err)
      panic
    }
  }
}

/// Pops a sprocket runtime from the cassette.
pub fn pop_sprocket(ca: Cassette, ws: Unique) -> Result(Nil, Nil) {
  case process.try_call(ca, PopSprocket(_, ws), call_timeout) {
    Ok(_) -> Ok(Nil)
    Error(err) -> {
      logger.error("Error popping sprocket with id: " <> unique.to_string(ws))
      io.debug(err)
      panic
    }
  }
}

fn get_cuid_channel(ca: Cassette) {
  case process.try_call(ca, GetCUIDChannel(_), call_timeout) {
    Ok(cuid_channel) -> cuid_channel
    Error(err) -> {
      logger.error("Error getting cuid channel")
      io.debug(err)
      panic
    }
  }
}

fn get_debug(ca: Cassette) {
  case process.try_call(ca, GetDebug(_), call_timeout) {
    Ok(debug) -> debug
    Error(err) -> {
      logger.error("Error getting debug")
      io.debug(err)
      panic
    }
  }
}

/// Validates a CSRF token.
fn validate_csrf(ca: Cassette, csrf: String) {
  let validator = case process.try_call(ca, GetCSRFValidator(_), call_timeout) {
    Ok(validator) -> validator
    Error(err) -> {
      logger.error("Error getting CSRF validator")
      io.debug(err)
      panic
    }
  }

  validator(csrf)
}

type Payload {
  JoinPayload(csrf_token: String)
  EventPayload(kind: String, id: String, value: Option(String))
  HookEventPayload(id: String, event: String, payload: Option(Dynamic))
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
          case runtime.get_handler(sprocket, event_id) {
            Ok(context.IdentifiableHandler(_, handler)) -> {
              // call the event handler
              handler(option.map(
                value,
                fn(value) { callback_param_from_string(value) },
              ))
              |> Ok
            }
            _ -> {
              logger.error("Error: no handler defined for id: " <> event_id)

              Ok(Nil)
            }
          }
        }
        _ -> Error(Nil)
      }
    }
    Ok(#("hook:event", HookEventPayload(hook_id, name, payload))) -> {
      logger.info("Hook Event: " <> hook_id <> " " <> name)

      case get_sprocket(ca, id) {
        Ok(sprocket) -> {
          case runtime.get_client_hook(sprocket, hook_id) {
            Ok(Client(_id, _name, handle_event)) -> {
              // TODO: implement reply dispatcher
              let reply_dispatcher = fn(event, payload) {
                ws_send(hook_event_to_json(hook_id, event, payload))
              }

              option.map(
                handle_event,
                fn(handle_event) {
                  handle_event(name, payload, reply_dispatcher)
                },
              )

              Ok(Nil)
            }
            _ -> {
              logger.error("Error: no client hook defined for id: " <> hook_id)
              io.debug(payload)
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
      let _ = ws_send(update_to_json(update, get_debug(ca)))
      Ok(Nil)
    })

  let dispatcher =
    Dispatcher(dispatch: fn(id, event, payload) {
      let _ = ws_send(hook_event_to_json(id, event, payload))
      Ok(Nil)
    })

  let sprocket = case
    runtime.start(
      id,
      view,
      get_cuid_channel(ca),
      Some(updater),
      Some(dispatcher),
    )
  {
    Ok(sprocket) -> sprocket
    Error(err) -> {
      logger.error("Error starting sprocket")
      io.debug(err)
      panic
    }
  }

  push_sprocket(ca, sprocket)

  logger.info("Sprocket connected! " <> unique.to_string(id))

  // intitial live render
  let rendered = runtime.render(sprocket)

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
