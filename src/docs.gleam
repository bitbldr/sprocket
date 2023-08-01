import gleam/int
import gleam/string
import gleam/option.{None}
import gleam/result
import gleam/dynamic
import gleam/erlang/os
import gleam/erlang/process
import gleam/http/service.{Service}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http.{Get}
import gleam/bit_builder.{BitBuilder}
import mist
import mist/websocket
import mist/internal/websocket.{TextMessage} as internal_websocket
import sprocket/cassette.{Cassette, LiveService}
import docs/routes
import docs/app_context.{AppContext}
import docs/utils/logger

pub fn main() {
  logger.configure_backend()

  let port = load_port()
  let ca = cassette.start(None)
  let router = routes.stack(AppContext(ca))

  let assert Ok(_) =
    mist.serve(
      port,
      mist.handler_func(fn(req) {
        case req.method, request.path_segments(req) {
          Get, ["live"] -> live_service(req, ca)
          _, _ -> http_service(req, router)
        }
      }),
    )

  string.concat(["Listening on localhost:", int.to_string(port), " ✨"])
  |> logger.info

  process.sleep_forever()
}

fn live_service(_req: Request(mist.Body), ca: Cassette) {
  let LiveService(on_msg, on_init, on_close) = cassette.live_service(ca)

  websocket.with_handler(fn(msg, ws) {
    case msg {
      TextMessage(msg) ->
        on_msg(
          msg,
          dynamic.from(ws),
          fn(msg) {
            websocket.send(ws, TextMessage(msg))
            Ok(Nil)
          },
        )

      internal_websocket.BinaryMessage(_) -> {
        logger.info("Received binary message")

        Ok(Nil)
      }
    }
  })
  |> websocket.on_init(fn(ws) {
    let _ = on_init(dynamic.from(ws))

    Nil
  })
  |> websocket.on_close(fn(ws) {
    let _ = on_close(dynamic.from(ws))

    Nil
  })
  |> mist.upgrade
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

fn load_port() -> Int {
  os.get_env("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}
