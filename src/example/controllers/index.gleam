import gleam/option.{None}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import sprocket/render.{render}
import example/hello_view.{HelloViewProps, hello_view}
import sprocket/socket
import sprocket/app_context.{AppContext}

pub fn index(_request: Request(String), _ctx: AppContext) -> Response(String) {
  let view = hello_view(HelloViewProps)

  let agent = socket.start(None, None, None)
  let body = render(view, socket.get_socket(agent))

  socket.stop(agent)

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
}
