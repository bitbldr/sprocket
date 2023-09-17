import gleam/bit_builder
import gleam/option.{Some}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import mist.{Connection, ResponseData}
import sprocket/render.{render}
import sprocket/component.{component}
import sprocket/internal/render/html as sprocket_html
import docs/components/counter.{CounterProps, counter}
import docs/app_context.{AppContext}
import docs/utils/common.{mist_response}
import docs/utils/csrf

pub fn standalone(
  _req: Request(Connection),
  app_ctx: AppContext,
) -> Response(ResponseData) {
  let view = component(counter, CounterProps(initial: Some(0)))

  let standalone_counter = render(view, sprocket_html.renderer())

  let csrf = csrf.generate(app_ctx.secret_key_base)

  let body =
    "
<html>
  <head>
    <title>Counter</title>
    <meta name=\"csrf-token\" content=\"" <> csrf <> "\" />
  </head>
  <body>
    <h1>Counter</h1>
    <p>
      This is a standalone counter component.
    </p>
    <p>
      It is rendered using the <code>render</code> function.
    </p>
    <p>
      <a href=\"/\">Back to the home page</a>
    </p>
    <div id='counter'>
" <> standalone_counter <> "
    </div>
    <script src=\"/docs/standalone_counter.js\"></script>
  </body>
</html>
"

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
  |> response.map(bit_builder.from_string)
  |> mist_response()
}
