import gleam/otp/actor
import gleam/list
import gleam/dynamic.{Dynamic, field, optional_field}
import gleam/io
import gleam/option.{Option, Some}
import gleam/erlang
import gleam/erlang/process.{Subject}
import gleam/json
import gleam/http/request.{Request}
import mist
import mist/websocket
import mist/internal/websocket.{TextMessage} as internal_websocket
import sprocket/sprocket.{Sprocket}
import sprocket/socket.{Updater, WebSocket}
import sprocket/render.{RenderedElement}
import sprocket/internal/render/json as json_renderer
import sprocket/element.{Element}
import sprocket/internal/patch.{Patch}
import sprocket/internal/identifiable_callback.{CallbackFn, CallbackWithValueFn}
import sprocket/internal/logger
import sprocket/internal/constants.{call_timeout}
import docs/utils/timer.{interval}

pub type Preflight {
  Preflight(id: String, view: Element, created_at: Int)
}

pub type Cassette =
  Subject(Message)

pub type State {
  State(
    sprockets: List(Sprocket),
    preflights: List(Preflight),
    cancel_preflight_cleanup_job: fn() -> Nil,
  )
}

pub type Message {
  Shutdown
  PushPreflight(preflight: Preflight)
  CleanupPreflights
  StartPreflightCleanupJob(cleanup_preflights: fn() -> Nil)
  PopPreflight(reply_with: Subject(Result(Preflight, Nil)), id: String)
  PushSprocket(sprocket: Sprocket)
  GetSprocket(reply_with: Subject(Result(Sprocket, Nil)), ws: WebSocket)
  PopSprocket(reply_with: Subject(Result(Sprocket, Nil)), ws: WebSocket)
}

fn handle_message(message: Message, state: State) -> actor.Next(State) {
  case message {
    Shutdown -> {
      state.cancel_preflight_cleanup_job()
      actor.Stop(process.Normal)
    }

    PushPreflight(preflight) -> {
      let updated_preflights = [preflight, ..state.preflights]

      actor.Continue(State(..state, preflights: updated_preflights))
    }

    CleanupPreflights -> {
      let now = erlang.system_time(erlang.Millisecond)

      // cleanup all preflights older than 60 seconds
      let updated_preflights =
        list.filter(state.preflights, fn(p) { p.created_at + 60 * 1000 > now })

      actor.Continue(State(..state, preflights: updated_preflights))
    }

    StartPreflightCleanupJob(cleanup_preflights) -> {
      // start preflight cleanup job, run every minute
      let cancel = interval(60 * 1000, fn() { cleanup_preflights() })

      actor.Continue(State(..state, cancel_preflight_cleanup_job: cancel))
    }

    PopPreflight(reply_with, id) -> {
      let preflight = list.find(state.preflights, fn(p) { p.id == id })

      process.send(reply_with, preflight)

      case preflight {
        Ok(_preflight) -> {
          let updated_preflights =
            list.filter(state.preflights, fn(p) { p.id != id })

          actor.Continue(State(..state, preflights: updated_preflights))
        }

        Error(_) -> actor.Continue(state)
      }
    }

    PushSprocket(sprocket) -> {
      let updated_sprockets =
        list.reverse([sprocket, ..list.reverse(state.sprockets)])

      actor.Continue(State(..state, sprockets: updated_sprockets))
    }

    GetSprocket(reply_with, ws) -> {
      let spkt =
        list.find(state.sprockets, fn(s) { sprocket.has_websocket(s, ws) })

      process.send(reply_with, spkt)

      actor.Continue(state)
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

          actor.Continue(new_state)
        }

        Error(_) -> actor.Continue(state)
      }
    }
  }
}

pub fn start() {
  let assert Ok(ca) =
    actor.start(
      State(
        sprockets: [],
        preflights: [],
        cancel_preflight_cleanup_job: fn() { Nil },
      ),
      handle_message,
    )

  start_preflight_cleanup_job(ca, cleanup_preflights)

  ca
}

pub fn stop(ca: Cassette) {
  process.send(ca, Shutdown)
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

pub fn push_preflight(ca: Cassette, preflight: Preflight) -> Preflight {
  process.send(ca, PushPreflight(preflight))

  preflight
}

pub fn pop_preflight(ca: Cassette, id: String) -> Result(Preflight, Nil) {
  process.call(ca, PopPreflight(_, id), call_timeout())
}

pub fn live_service(_req: Request(mist.Body), ca: Cassette) {
  websocket.with_handler(fn(msg, ws) {
    handle_ws_message(ca, ws, msg)

    Ok(Nil)
  })
  |> websocket.on_init(fn(_ws) { Nil })
  |> websocket.on_close(fn(ws) {
    let assert Ok(_) = pop_sprocket(ca, ws)

    Nil
  })
  |> mist.upgrade
}

fn push_sprocket(ca: Cassette, sprocket: Sprocket) {
  process.send(ca, PushSprocket(sprocket))
}

fn get_sprocket(ca: Cassette, ws: WebSocket) {
  process.call(ca, GetSprocket(_, ws), call_timeout())
}

fn pop_sprocket(ca: Cassette, ws: WebSocket) {
  process.call(ca, PopSprocket(_, ws), call_timeout())
}

fn connect(ca: Cassette, ws: WebSocket, preflight_id: String) {
  let updater =
    Updater(send: fn(update) {
      let _ = websocket.send(ws, TextMessage(update_to_json(update)))
      Ok(Nil)
    })

  case pop_preflight(ca, preflight_id) {
    Ok(Preflight(view: view, ..)) -> {
      let sprocket = sprocket.start(Some(ws), Some(view), Some(updater))
      push_sprocket(ca, sprocket)

      // intitial live render
      let rendered = sprocket.render(sprocket)
      websocket.send(ws, TextMessage(rendered_to_json(rendered)))

      logger.info("Sprocket connected!")

      Nil
    }
    Error(Nil) -> {
      logger.error("Error no sprocket found for preflight id:" <> preflight_id)

      Nil
    }
  }
}

type Event {
  Event(kind: String, id: String, value: Option(String))
}

fn decode_event(event: Dynamic) {
  event
  |> dynamic.decode3(
    Event,
    field("kind", dynamic.string),
    field("id", dynamic.string),
    optional_field("value", dynamic.string),
  )
}

fn handle_ws_message(
  ca: Cassette,
  ws: WebSocket,
  msg: internal_websocket.Message,
) {
  case msg {
    TextMessage(msg) -> {
      case json.decode(msg, dynamic.tuple2(dynamic.string, dynamic.dynamic)) {
        Ok(#("join", id)) -> {
          case
            id
            |> dynamic.string
          {
            Ok(id) -> {
              logger.info("New client joined with preflight id: " <> id)

              connect(ca, ws, id)
            }
            Error(e) -> {
              logger.error("Error decoding join id")
              io.debug(e)

              Nil
            }
          }
        }
        Ok(#("event", event)) -> {
          case decode_event(event) {
            Ok(event) -> {
              logger.info("Event: " <> event.kind <> " " <> event.id)

              case get_sprocket(ca, ws) {
                Ok(sprocket) -> {
                  case sprocket.get_handler(sprocket, event.id) {
                    Ok(socket.EventHandler(_, handler)) -> {
                      // call the event handler
                      case handler {
                        CallbackFn(cb) -> {
                          cb()
                        }
                        CallbackWithValueFn(cb) -> {
                          case event.value {
                            Some(value) -> cb(value)
                            _ -> {
                              logger.error("Error decoding event value:")
                              io.debug(event)
                              panic
                            }
                          }
                        }
                      }
                    }
                    _ -> Nil
                  }
                }
                _ -> Nil
              }
            }
            Error(e) -> {
              logger.error("Error decoding event")
              io.debug(e)

              Nil
            }
          }
        }
        Error(e) -> {
          logger.error("Error decoding message")
          io.debug(e)

          Nil
        }
      }
    }
    internal_websocket.BinaryMessage(_) -> {
      logger.info("Received binary message")
      Nil
    }
  }
}

fn update_to_json(update: Patch) -> String {
  json.preprocessed_array([json.string("update"), patch.patch_to_json(update)])
  |> json.to_string()
}

fn rendered_to_json(update: RenderedElement) -> String {
  json.preprocessed_array([
    json.string("ok"),
    json_renderer.renderer().render(update),
  ])
  |> json.to_string()
}
