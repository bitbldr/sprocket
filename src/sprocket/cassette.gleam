import gleam/io
import gleam/list
import gleam/dynamic.{Dynamic, field, optional_field}
import gleam/option.{None, Option, Some}
import gleam/json
import gleam/erlang
import gleam/erlang/process.{Subject}
import gleam/otp/actor
import sprocket/sprocket.{Sprocket}
import sprocket/context.{Dispatcher, Element, Updater}
import sprocket/render.{RenderedElement}
import sprocket/hooks.{Client}
import sprocket/internal/render/json as json_renderer
import sprocket/internal/patch.{Patch}
import sprocket/internal/identifiable_callback.{CallbackFn, CallbackWithValueFn}
import sprocket/internal/logger
import sprocket/internal/constants.{call_timeout}
import sprocket/internal/csrf
import sprocket/internal/utils/timer.{interval}
import sprocket/internal/utils/unique.{Unique}

pub type Preflight {
  Preflight(id: String, view: Element, csrf_token: String, created_at: Int)
}

pub type Cassette =
  Subject(Message)

pub type State {
  State(
    sprockets: List(Sprocket),
    preflights: List(Preflight),
    cancel_preflight_cleanup_job: fn() -> Nil,
    debug: Bool,
  )
}

pub type Message {
  Shutdown
  GetState(reply_with: Subject(State))
  PushPreflight(preflight: Preflight)
  CleanupPreflights
  StartPreflightCleanupJob(cleanup_preflights: fn() -> Nil)
  PopPreflight(reply_with: Subject(Result(Preflight, Nil)), id: String)
  PushSprocket(sprocket: Sprocket)
  GetSprocket(reply_with: Subject(Result(Sprocket, Nil)), ws: Unique)
  PopSprocket(reply_with: Subject(Result(Sprocket, Nil)), ws: Unique)
}

fn handle_message(message: Message, state: State) -> actor.Next(Message, State) {
  case message {
    Shutdown -> {
      state.cancel_preflight_cleanup_job()
      actor.Stop(process.Normal)
    }

    GetState(reply_with) -> {
      process.send(reply_with, state)
      actor.continue(state)
    }

    PushPreflight(preflight) -> {
      let updated_preflights = [preflight, ..state.preflights]

      actor.continue(State(..state, preflights: updated_preflights))
    }

    CleanupPreflights -> {
      let now = erlang.system_time(erlang.Millisecond)

      // cleanup all preflights older than 60 seconds
      let updated_preflights =
        list.filter(state.preflights, fn(p) { p.created_at + 60 * 1000 > now })

      actor.continue(State(..state, preflights: updated_preflights))
    }

    StartPreflightCleanupJob(cleanup_preflights) -> {
      // start preflight cleanup job, run every minute
      let cancel = interval(60 * 1000, fn() { cleanup_preflights() })

      actor.continue(State(..state, cancel_preflight_cleanup_job: cancel))
    }

    PopPreflight(reply_with, id) -> {
      let preflight = list.find(state.preflights, fn(p) { p.id == id })

      process.send(reply_with, preflight)

      case preflight {
        Ok(_preflight) -> {
          let updated_preflights =
            list.filter(state.preflights, fn(p) { p.id != id })

          actor.continue(State(..state, preflights: updated_preflights))
        }

        Error(_) -> actor.continue(state)
      }
    }

    PushSprocket(sprocket) -> {
      let updated_sprockets =
        list.reverse([sprocket, ..list.reverse(state.sprockets)])

      actor.continue(State(..state, sprockets: updated_sprockets))
    }

    GetSprocket(reply_with, ws) -> {
      let spkt =
        list.find(state.sprockets, fn(s) { sprocket.has_websocket(s, ws) })

      process.send(reply_with, spkt)

      actor.continue(state)
    }

    PopSprocket(reply_with, ws) -> {
      let sprocket =
        list.find(state.sprockets, fn(s) { sprocket.has_websocket(s, ws) })

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
pub fn start(opts: Option(CassetteOpts)) -> Cassette {
  let assert Ok(ca) =
    actor.start(
      State(
        sprockets: [],
        preflights: [],
        cancel_preflight_cleanup_job: fn() { Nil },
        debug: option.map(opts, fn(opts) { opts.debug })
        |> option.unwrap(False),
      ),
      handle_message,
    )

  start_preflight_cleanup_job(ca, cleanup_preflights)

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

fn cleanup_preflights(ca: Cassette) {
  process.send(ca, CleanupPreflights)
}

fn start_preflight_cleanup_job(
  ca: Cassette,
  cleanup_preflights: fn(Cassette) -> Nil,
) {
  process.send(ca, StartPreflightCleanupJob(fn() { cleanup_preflights(ca) }))
}

/// Pushes a preflight to the cassette.
pub fn push_preflight(ca: Cassette, preflight: Preflight) -> Preflight {
  process.send(ca, PushPreflight(preflight))

  preflight
}

/// Pops a preflight from the cassette.
pub fn pop_preflight(ca: Cassette, id: String) -> Result(Preflight, Nil) {
  process.call(ca, PopPreflight(_, id), call_timeout())
}

pub type LiveService {
  LiveService(
    id: Unique,
    on_msg: fn(String, Unique, fn(String) -> Result(Nil, Nil)) ->
      Result(Nil, Nil),
    on_init: fn(Unique) -> Result(Nil, Nil),
    on_close: fn(Unique) -> Result(Nil, Nil),
  )
}

/// Returns a live service specification for a sprocket websocket.
/// 
/// This is a generic interface for handling websocket messages that can be
/// used to implement a live service for a sprocket with a variety of different
/// web servers.
/// 
/// Refer to the example docs repository for an example of how to use this.
pub fn live_service(ca: Cassette) {
  LiveService(
    id: unique.new(),
    on_msg: fn(msg, ws, ws_send) { handle_ws_message(ca, msg, ws, ws_send) },
    on_init: fn(_ws) { Ok(Nil) },
    on_close: fn(ws) {
      let spkt = pop_sprocket(ca, ws)

      case spkt {
        Ok(sprocket) -> {
          sprocket.stop(sprocket)
          Ok(Nil)
        }
        Error(_) -> {
          logger.error("failed to pop sprocket for websoket:")
          io.debug(ws)
          Ok(Nil)
        }
      }
    },
  )
}

/// Pushes a sprocket to the cassette.
fn push_sprocket(ca: Cassette, sprocket: Sprocket) {
  process.send(ca, PushSprocket(sprocket))
}

/// Gets a sprocket from the cassette.
fn get_sprocket(ca: Cassette, ws: Unique) {
  process.call(ca, GetSprocket(_, ws), call_timeout())
}

/// Pops a sprocket from the cassette.
fn pop_sprocket(ca: Cassette, ws: Unique) {
  process.call(ca, PopSprocket(_, ws), call_timeout())
}

/// Handles client websocket connection initialization.
fn connect(
  ca: Cassette,
  ws: Unique,
  ws_send: fn(String) -> Result(Nil, Nil),
  preflight_id: String,
  preflight_csrf: String,
) {
  let updater =
    Updater(send: fn(update) {
      let _ = ws_send(update_to_json(update, get_state(ca).debug))
      Ok(Nil)
    })

  let dispatcher =
    Dispatcher(dispatch: fn(id, event, payload) {
      let _ = ws_send(event_to_json(id, event, payload))
      Ok(Nil)
    })

  case pop_preflight(ca, preflight_id) {
    Ok(Preflight(view: view, csrf_token: csrf_token, ..)) -> {
      case csrf.validate(preflight_csrf, csrf_token) {
        Ok(_) -> {
          let sprocket =
            sprocket.start(view, Some(ws), Some(updater), Some(dispatcher))
          push_sprocket(ca, sprocket)

          logger.info("Sprocket connected!")

          // intitial live render
          let rendered = sprocket.render(sprocket)
          ws_send(rendered_to_json(rendered))
        }
        Error(_) -> {
          logger.error("CSRF token mismatch for preflight id:" <> preflight_id)
          ws_send(error_to_json(InvalidCSRFToken))
        }
      }
    }
    Error(Nil) -> {
      logger.error("Error no sprocket found for preflight id:" <> preflight_id)
      ws_send(error_to_json(PreflightNotFound))
    }
  }
}

type Payload {
  JoinPayload(preflight_id: String, csrf_token: String)
  EventPayload(kind: String, id: String, value: Option(String))
  HookEventPayload(id: String, event: String, value: Option(Dynamic))
  EmptyPayload(nothing: Option(String))
}

fn decode_join(data: Dynamic) {
  data
  |> dynamic.tuple2(
    dynamic.string,
    dynamic.decode2(
      JoinPayload,
      field("id", dynamic.string),
      field("csrf", dynamic.string),
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

fn handle_ws_message(
  ca: Cassette,
  msg: String,
  ws: Unique,
  ws_send: fn(String) -> Result(Nil, Nil),
) -> Result(Nil, Nil) {
  case
    json.decode(
      msg,
      dynamic.any([decode_join, decode_event, decode_hook_event, decode_empty]),
    )
  {
    Ok(#("join", JoinPayload(id, csrf))) -> {
      logger.info("New client joined with preflight id: " <> id)

      connect(ca, ws, ws_send, id, csrf)
    }
    Ok(#("event", EventPayload(kind, id, value))) -> {
      logger.info("Event: " <> kind <> " " <> id)

      case get_sprocket(ca, ws) {
        Ok(sprocket) -> {
          case sprocket.get_handler(sprocket, id) {
            Ok(context.EventHandler(_, handler)) -> {
              // call the event handler
              case handler {
                CallbackFn(cb) -> {
                  cb()

                  Ok(Nil)
                }
                CallbackWithValueFn(cb) -> {
                  case value {
                    Some(value) -> {
                      cb(value)

                      Ok(Nil)
                    }
                    _ -> {
                      logger.error("Error: expected a value but got None")
                      io.debug(value)
                      panic
                    }
                  }
                }
              }
            }
            _ -> Ok(Nil)
          }
        }
        _ -> Error(Nil)
      }
    }
    Ok(#("hook:event", HookEventPayload(id, name, value))) -> {
      logger.info("Hook Event: " <> id <> " " <> name)

      case get_sprocket(ca, ws) {
        Ok(sprocket) -> {
          case sprocket.get_client_hook(sprocket, id) {
            Ok(Client(_id, _name, handle_event)) -> {
              // TODO: implement reply dispatcher
              let reply_dispatcher = fn(_event, _payload) { todo }

              option.map(
                handle_event,
                fn(handle_event) { handle_event(name, value, reply_dispatcher) },
              )

              Ok(Nil)
            }
            _ -> {
              logger.error("Error: no client hook defined for id: " <> id)
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

fn update_to_json(update: Patch, debug: Bool) -> String {
  json.preprocessed_array([
    json.string("update"),
    patch.patch_to_json(update, debug),
    json.object([#("debug", json.bool(debug))]),
  ])
  |> json.to_string()
}

fn event_to_json(id: String, event: String, value: Option(String)) -> String {
  json.preprocessed_array([
    json.string("event"),
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
