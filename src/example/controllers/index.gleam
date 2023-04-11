import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/erlang/process.{Subject}
import sprocket/render.{render}
import example/hello_view.{HelloViewProps, hello_view}
import sprocket/context_agent.{ContextMessage}

pub fn index(
  _request: Request(String),
  ca: Subject(ContextMessage),
) -> Response(String) {
  let view = hello_view(HelloViewProps)

  let context = context_agent.fetch_context(ca)

  let body = render(view, context)

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
}
