import gleam/int
import gleam/string
import gleam/result
import gleam/erlang/os
import gleam/erlang/process
import gleam/http/service.{Service}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http.{Get}
import gleam/bit_builder.{BitBuilder}
import mist
import cassette
import docs/routes
import docs/app_context.{AppContext}
import docs/utils/logger

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
          Get, ["live"] -> cassette.live_service(req, ca)
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

fn load_port() -> Int {
  os.get_env("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}
