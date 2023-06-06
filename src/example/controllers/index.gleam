import gleam/http/request.{Request}
import gleam/http/response.{Response}
import sprocket/render.{render}
import sprocket/component.{component}
import example/hello_view.{HelloViewProps, hello_view}
import example/app_context.{AppContext}
import sprocket/render/html

pub fn index(_request: Request(String), _ctx: AppContext) -> Response(String) {
  let view = component(hello_view, HelloViewProps)

  let body = render(view, html.renderer())

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
}
