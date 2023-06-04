import gleam/http/request.{Request}
import gleam/http/response.{Response}
import sprocket/render.{render}
import example/hello_view.{HelloViewProps, hello_view}
import example/app_context.{AppContext}

pub fn index(_request: Request(String), _ctx: AppContext) -> Response(String) {
  let view = hello_view(HelloViewProps)

  let body = render(view)

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
}
