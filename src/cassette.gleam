import gleam/otp/actor
import gleam/list
import gleam/dynamic.{field}
import sprocket/identifiable_callback.{CallbackFn, CallbackWithValueFn}
import gleam/io
import gleam/option.{Some}
import gleam/erlang/process.{Subject}
import gleam/json
import gleam/http/request.{Request}
import mist
import mist/websocket
import mist/internal/websocket.{TextMessage} as internal_websocket
import sprocket.{Sprocket}
import sprocket/socket.{Updater, WebSocket}
import sprocket/render.{RenderedElement}
import sprocket/render/json as json_renderer
import sprocket/component.{component}
import sprocket/patch.{Patch}
import sprocket/logger
import docs/views/page_view.{PageViewProps, page_view}

pub type Cassette =
  Subject(Message)

pub type State {
  State(sprockets: List(Sprocket))
}

pub type Message {
  Shutdown
  PushSprocket(sprocket: Sprocket)
  GetSprocket(reply_with: Subject(Result(Sprocket, Nil)), ws: WebSocket)
  PopSprocket(reply_with: Subject(Result(Sprocket, Nil)), ws: WebSocket)
}

fn handle_message(message: Message, state: State) -> actor.Next(State) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    PushSprocket(sprocket) -> {
      let updated_sprockets =
        list.reverse([sprocket, ..list.reverse(state.sprockets)])
      actor.Continue(State(sprockets: updated_sprockets))
    }

    GetSprocket(reply_with, ws) -> {
      let skt =
        list.find(state.sprockets, fn(s) { sprocket.has_websocket(s, ws) })

      process.send(reply_with, skt)

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

          let new_state = State(sprockets: updated_sprockets)

          actor.Continue(new_state)
        }

        Error(_) -> actor.Continue(state)
      }
    }
  }
}

pub fn start() {
  let assert Ok(ca) = actor.start(State(sprockets: []), handle_message)

  ca
}

pub fn stop(ca: Cassette) {
  process.send(ca, Shutdown)
}

pub fn live_service(req: Request(mist.Body), ca: Cassette) {
  websocket.with_handler(fn(msg, ws) {
    handle_ws_message(ca, ws, msg)

    Ok(Nil)
  })
  |> websocket.on_init(fn(ws) {
    connect(req, ca, ws)

    Nil
  })
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
  process.call(ca, GetSprocket(_, ws), 10)
}

fn pop_sprocket(ca: Cassette, ws: WebSocket) {
  process.call(ca, PopSprocket(_, ws), 10)
}

fn connect(req: Request(mist.Body), ca: Cassette, ws: WebSocket) {
  let updater =
    Updater(send: fn(update) {
      let _ = websocket.send(ws, TextMessage(update_to_json(update)))
      Ok(Nil)
    })

  // TODO: Remove hard coded view and replace with dynamic view that is
  // determined by the previous page request
  let view = component(page_view, PageViewProps(route: req.path))

  let sprocket = sprocket.start(Some(ws), Some(view), Some(updater))
  push_sprocket(ca, sprocket)

  // intitial live render
  let rendered = sprocket.render(sprocket)
  websocket.send(ws, TextMessage(rendered_to_json(rendered)))

  logger.info("Client connected!")
  io.debug(ws)
}

type Event {
  Event(kind: String, id: String)
}

fn decode_event(body: String) {
  json.decode(
    body,
    dynamic.decode2(
      Event,
      field("kind", dynamic.string),
      field("id", dynamic.string),
    ),
  )
}

fn decode_event_value(body: String) {
  json.decode(body, field("value", dynamic.string))
}

fn handle_ws_message(
  ca: Cassette,
  ws: WebSocket,
  msg: internal_websocket.Message,
) {
  case msg {
    TextMessage("[\"join\"]") -> {
      logger.info("New client joined")

      case get_sprocket(ca, ws) {
        Ok(spkt) -> {
          sprocket.render_update(spkt)

          Nil
        }
        _ -> Nil
      }
    }
    TextMessage(body) -> {
      case decode_event(body) {
        Ok(event) -> {
          logger.info("Event: " <> event.kind <> " " <> event.id)

          case get_sprocket(ca, ws) {
            Ok(socket) -> {
              case sprocket.get_handler(socket, event.id) {
                Ok(socket.EventHandler(_, handler)) -> {
                  // call the event handler
                  case handler {
                    CallbackFn(cb) -> {
                      cb()
                    }
                    CallbackWithValueFn(cb) -> {
                      case decode_event_value(body) {
                        Ok(value) -> cb(value)
                        _ -> {
                          logger.error("Error decoding event value:")
                          io.debug(body)
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
