import gleam/http/request.{Request}
import gleam/http/response.{Response}
import sprocket/component.{ComponentContext}
import sprocket/render.{render}
import example/hello_view.{HelloViewProps, hello_view}

pub fn index(_request: Request(String)) -> Response(String) {
  // TODO: these are just dummy functions to simulate state management.
  // We will have to implement some sort of actor linked to the websocket
  // session to store and update this data
  let push_hook = fn(h) { h }
  let state_updater = fn(_index) { fn(s) { s } }

  let context =
    ComponentContext(
      hooks: [],
      h_index: 0,
      push_hook: push_hook,
      state_updater: state_updater,
    )

  let view = hello_view(HelloViewProps)

  let body = render(view, context)

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/html")
}
