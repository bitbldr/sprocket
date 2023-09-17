import gleam/bit_builder.{BitBuilder}
import gleam/string
import gleam/option.{Some}
import gleam/bit_string
import gleam/result
import gleam/erlang
import gleam/http.{Get}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import mist.{Connection, ResponseData}
import gleam/http/service.{Service}
import docs/log_requests
import docs/static
import docs/utils/csrf
import docs/utils/logger
import docs/utils/common.{mist_response}
import docs/app_context.{AppContext}
import docs/views/page_view.{PageViewProps, page_view}
import docs/page_route
import docs/controllers/standalone.{standalone}
import docs/components/counter.{CounterProps, counter}
import mist_sprocket

pub fn router(app_ctx: AppContext) {
  fn(request: Request(Connection)) -> Response(ResponseData) {
    use <- rescue_crashes()

    case request.method, request.path_segments(request) {
      Get, ["standalone"] -> standalone(request, app_ctx)
      Get, ["counter", "live"] ->
        mist_sprocket.live(
          request,
          app_ctx.ca,
          counter,
          CounterProps(initial: Some(100)),
        )

      Get, _ ->
        mist_sprocket.live(
          request,
          app_ctx.ca,
          page_view,
          PageViewProps(
            route: page_route.from_string(request.path),
            csrf: csrf.generate(app_ctx.secret_key_base),
          ),
        )

      _, _ ->
        not_found()
        |> response.map(bit_builder.from_string)
        |> mist_response()
    }
  }
}

pub fn stack(ctx: AppContext) -> Service(Connection, ResponseData) {
  router(ctx)
  // |> string_body_middleware
  |> log_requests.middleware
  |> static.middleware()
  |> service.prepend_response_header("made-with", "Gleam")
}

pub fn string_body_middleware(
  service: Service(String, String),
) -> Service(BitString, BitBuilder) {
  fn(request: Request(BitString)) {
    case bit_string.to_string(request.body) {
      Ok(body) -> service(request.set_body(request, body))
      Error(_) -> bad_request()
    }
    |> response.map(bit_builder.from_string)
  }
}

pub fn method_not_allowed() -> Response(String) {
  response.new(405)
  |> response.set_body("Method not allowed")
  |> response.prepend_header("content-type", "text/plain")
}

pub fn not_found() -> Response(String) {
  response.new(404)
  |> response.set_body("Page not found")
  |> response.prepend_header("content-type", "text/plain")
}

pub fn bad_request() -> Response(String) {
  response.new(400)
  |> response.set_body("Bad request. Please try again")
  |> response.prepend_header("content-type", "text/plain")
}

pub fn internal_server_error() -> Response(String) {
  response.new(500)
  |> response.set_body("Internal Server Error")
  |> response.prepend_header("content-type", "text/plain")
}

pub fn http_service(
  req: Request(Connection),
  service: Service(BitString, BitBuilder),
) -> Response(ResponseData) {
  req
  |> mist.read_body(1024 * 1024 * 10)
  |> result.map(fn(http_req: Request(BitString)) {
    http_req
    |> service()
    |> mist_response()
  })
  |> result.unwrap(
    response.new(500)
    |> response.set_body(mist.Bytes(bit_builder.new())),
  )
}

pub fn rescue_crashes(
  handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  case erlang.rescue(handler) {
    Ok(response) -> response
    Error(error) -> {
      logger.error(string.inspect(error))

      internal_server_error()
      |> response.map(bit_builder.from_string)
      |> mist_response()
    }
  }
}
