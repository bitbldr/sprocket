import gleam/io
import gleam/int
import gleam/string
import gleam/option.{None}
import gleam/result
import gleam/bit_string
import gleam/otp/actor
import gleam/erlang/os
import gleam/erlang/process
import gleam/http/service.{Service}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http.{Get}
import gleam/bit_builder.{BitBuilder}
import mist.{Connection, ResponseData}
import sprocket/cassette.{Cassette, LiveService}
import docs/routes
import docs/app_context.{AppContext}
import docs/utils/logger

pub fn main() {
  logger.configure_backend()

  let port = load_port()
  let ca = cassette.start(validate_csrf, None)
  let router = routes.stack(AppContext(ca))

  fn(req: Request(Connection)) -> Response(ResponseData) {
    case req.method, request.path_segments(req) {
      Get, ["live"] -> live_service(req, ca)
      _, _ -> http_service(req, router)
    }
  }
  |> mist.new
  |> mist.port(port)
  |> mist.start_http

  string.concat(["Listening on localhost:", int.to_string(port), " ✨"])
  |> logger.info

  process.sleep_forever()
}

fn validate_csrf(_token: String) {
  Ok(Nil)
}

fn live_service(req: Request(Connection), ca: Cassette) {
  let live_service = cassette.live_service(ca)

  let selector = process.new_selector()

  mist.websocket(req)
  |> mist.with_state(Nil)
  |> mist.selecting(selector)
  |> mist.on_message(fn(state, conn, message) {
    handle_ws_message(state, conn, message, live_service)
  })
  |> mist.upgrade
}

fn handle_ws_message(state: Nil, conn, message, live_service) {
  let LiveService(id, on_msg, _on_init, on_close) = live_service

  io.debug(#("LiveService id", id))

  case message {
    mist.Text(msg) -> {
      let assert Ok(msg) = bit_string.to_string(msg)

      let _ =
        on_msg(
          id,
          msg,
          fn(msg) {
            let assert Ok(_) =
              mist.send_text_frame(conn, bit_string.from_string(msg))
            Ok(Nil)
          },
        )

      actor.continue(state)
    }
    mist.Closed | mist.Shutdown -> {
      let _ = on_close(id)
      actor.Stop(process.Normal)
    }
    _ -> {
      logger.info("Received unsupported websocket message type")
      actor.continue(state)
    }
  }
}

fn http_service(
  req: Request(Connection),
  router: Service(BitString, BitBuilder),
) -> Response(ResponseData) {
  req
  |> mist.read_body(1024 * 1024 * 10)
  |> result.map(fn(http_req: Request(BitString)) {
    http_req
    |> router()
    |> mist_response()
  })
  |> result.unwrap(
    response.new(500)
    |> response.set_body(mist.Bytes(bit_builder.new())),
  )
}

fn mist_response(response: Response(BitBuilder)) -> Response(ResponseData) {
  response.new(response.status)
  |> response.set_body(mist.Bytes(response.body))
}

fn load_port() -> Int {
  os.get_env("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}
