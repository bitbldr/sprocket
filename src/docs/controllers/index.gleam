import gleam/http/request.{Request}
import gleam/http/response.{Response}
import sprocket/render.{render}
import sprocket/component.{component}
import docs/views/page_view.{PageViewProps, page_view}
import docs/app_context.{AppContext}
import sprocket/render/html
import cassette

pub fn index(req: Request(String), ctx: AppContext) -> Response(String) {
  let view =
    component(
      page_view,
      PageViewProps(route: req.path, path_segments: request.path_segments(req)),
    )

  let preflight = cassette.preflight(ctx.ca, view)

  let body = render(view, html.renderer_with_preflight(preflight))

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
}
