import gleam/http/request.{Request}
import gleam/http/response.{Response}
import sprocket/render.{render}
import sprocket/component.{component}
import sprocket/internal/render/html
import docs/views/page_view.{PageViewProps, page_view}
import docs/app_context.{AppContext}
import docs/page_route

pub fn index(req: Request(String), ctx: AppContext) -> Response(String) {
  let view =
    component(
      page_view,
      PageViewProps(
        route: page_route.from_string(req.path),
        path_segments: request.path_segments(req),
      ),
    )

  let body = render(view, html.preflight_renderer(ctx.ca, view, "/app.js"))

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
}
