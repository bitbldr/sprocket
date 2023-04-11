import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import gleam/erlang/process.{Subject}
import example/log_requests
import example/static
import example/controllers/index.{index}
import sprocket/context_agent.{ContextMessage}

pub fn router(ca: Subject(ContextMessage)) {
  fn(request: Request(String)) -> Response(String) {
    case request.path_segments(request) {
      [] ->
        case request.method {
          http.Get -> index(request, ca)
          _ -> method_not_allowed()
        }

      _ -> not_found()
    }
  }
}

pub fn stack(ca: Subject(ContextMessage)) -> Service(BitString, BitBuilder) {
  router(ca)
  |> string_body_middleware
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

fn method_not_allowed() -> Response(String) {
  response.new(405)
  |> response.set_body("Method not allowed")
  |> response.prepend_header("content-type", "text/plain")
}

fn not_found() -> Response(String) {
  response.new(404)
  |> response.set_body("Page not found")
  |> response.prepend_header("content-type", "text/plain")
}

fn bad_request() -> Response(String) {
  response.new(400)
  |> response.set_body("Bad request. Please try again")
  |> response.prepend_header("content-type", "text/plain")
}
