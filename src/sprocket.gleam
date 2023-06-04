import example/utils/logger
import gleam/io
import gleam/int
import gleam/string
import gleam/result
import gleam/option.{Some}
import gleam/erlang/os
import gleam/erlang/process
import gleam/json.{array}
import gleam/dynamic.{field}
import mist
import mist/websocket
import mist/internal/websocket.{TextMessage} as internal_websocket
import sprocket/cassette.{Cassette}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http.{Get}
import gleam/bit_builder.{BitBuilder}
import sprocket/render.{live_render}
import sprocket/socket.{Updater}
import sprocket/sprocket
import sprocket/component.{component}
import example/hello_view.{HelloViewProps, hello_view}
import example/routes
import example/app_context.{AppContext}
import gleam/http/service.{Service}

pub fn main() {
  logger.configure_backend()

  let port = load_port()
  let ca = cassette.start()
  let router = routes.stack(AppContext(ca))

  let assert Ok(_) =
    mist.serve(
      port,
      mist.handler_func(fn(req) {
        case req.method, request.path_segments(req) {
          Get, ["live"] -> websocket_service(ca)
          _, _ -> http_service(req, router)
        }
      }),
    )

  string.concat(["Listening on localhost:", int.to_string(port), " ✨"])
  |> logger.info

  process.sleep_forever()
}

fn http_service(
  req: Request(mist.Body),
  router: Service(BitString, BitBuilder),
) -> mist.Response {
  req
  |> mist.read_body
  |> result.map(fn(http_req: Request(BitString)) {
    http_req
    |> router()
    |> mist_response()
  })
  |> result.unwrap(
    response.new(500)
    |> mist.empty_response(),
  )
}

fn mist_response(response: Response(BitBuilder)) -> mist.Response {
  response
  |> mist.bit_builder_response(response.body)
}

fn websocket_service(ca: Cassette) {
  websocket.with_handler(fn(msg, ws) {
    // let _ = websocket.send(sender, TextMessage("hello client"))

    case msg {
      TextMessage("join") -> {
        io.println("New client joined")

        case cassette.get_sprocket(ca, ws) {
          Ok(spkt) -> {
            sprocket.render_update(spkt)

            Nil
          }
          _ -> Nil
        }
      }
      TextMessage(text) -> {
        case decode_event(text) {
          Ok(event) -> {
            io.debug(event)

            case cassette.get_sprocket(ca, ws) {
              Ok(socket) -> {
                case sprocket.get_handler(socket, event.id) {
                  Ok(socket.EventHandler(_, handler)) -> {
                    // call the event handler
                    handler()
                  }
                  _ -> Nil
                }
              }
              _ -> Nil
            }
          }

          Error(e) -> {
            io.debug("Error decoding event:")
            io.debug(e)

            Nil
          }
        }
      }
      internal_websocket.BinaryMessage(_) -> {
        io.debug("Received binary message")
        Nil
      }
    }

    Ok(Nil)
  })
  // Here you can gain access to the `Subject` to send message to
  // with:
  |> websocket.on_init(fn(ws) {
    let updater =
      Updater(send: fn(html) {
        let _ = websocket.send(ws, TextMessage(update_to_json(html)))
        Ok(Nil)
      })

    let view = component(hello_view, HelloViewProps)

    let sprocket =
      sprocket.start(Some(ws), Some(view), Some(live_render), Some(updater))
    cassette.push_sprocket(ca, sprocket)

    sprocket.render_update(sprocket)

    io.println("Client connected!")
    io.debug(ws)

    Nil
  })
  |> websocket.on_close(fn(ws) {
    let assert Ok(_) = cassette.pop_sprocket(ca, ws)

    io.println("Disconnected!")
    io.debug(ws)

    Nil
  })
  |> mist.upgrade
}

fn load_port() -> Int {
  os.get_env("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}

type Event {
  Event(event: String, id: String)
}

fn decode_event(body: String) {
  json.decode(
    body,
    dynamic.decode2(
      Event,
      field("event", dynamic.string),
      field("id", dynamic.string),
    ),
  )
}

fn update_to_json(html: String) -> String {
  array(["update", html], of: json.string)
  |> json.to_string
}
