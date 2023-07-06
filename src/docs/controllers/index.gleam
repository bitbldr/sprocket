import gleam/http/request.{Request}
import gleam/http/response.{Response}
import sprocket/render.{render}
import sprocket/component.{component}
import docs/views/page_view.{PageViewProps, page_view}
import docs/app_context.{AppContext}
import sprocket/render/html

pub fn index(request: Request(String), _ctx: AppContext) -> Response(String) {
  let view = component(page_view, PageViewProps(route: request.path))

  let body = render(view, html.renderer())

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
}
