import example/log
import gleam/io
import gleam/int
import gleam/string
import gleam/result
import gleam/erlang/os
import gleam/erlang/process
import mist
import mist/websocket
import mist/internal/websocket.{TextMessage} as internal_websocket
import sprocket/context_agent.{Client, ContextAgent}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http.{Get}
import gleam/bit_builder.{BitBuilder}
import sprocket/render.{render}
import example/hello_view.{HelloViewProps, hello_view}
import example/routes
import gleam/http/service.{Service}

pub fn main() {
  log.configure_backend()

  let port = load_port()
  let ca = context_agent.start()
  let web = routes.stack(ca)

  let assert Ok(_) =
    mist.serve(
      port,
      mist.handler_func(fn(req) {
        case req.method, request.path_segments(req) {
          Get, ["live"] -> websocket_echo(ca)
          _, _ ->
            req
            |> http_service(web)
        }
      }),
    )

  string.concat(["Listening on localhost:", int.to_string(port), " ✨"])
  |> log.info

  process.sleep_forever()
}

fn http_service(
  req: Request(mist.Body),
  stack: Service(BitString, BitBuilder),
) -> mist.Response {
  req
  |> mist.read_body
  |> result.map(fn(http_req: Request(BitString)) {
    http_req
    |> stack()
    |> mist_response()
  })
  |> result.unwrap(
    response.new(500)
    |> mist.empty_response(),
  )
}

fn mist_response(response: Response(BitBuilder)) -> mist.Response {
  response
  |> mist.bit_builder_response(response.body)
}

fn websocket_echo(ca: ContextAgent) {
  websocket.with_handler(fn(msg, sender) {
    io.debug("Received message:")
    io.debug(#(sender, msg))

    let _ = websocket.send(sender, TextMessage("hello client"))

    Ok(Nil)
  })
  // Here you can gain access to the `Subject` to send message to
  // with:
  |> websocket.on_init(fn(sub) {
    context_agent.push_client(ca, Client(sub))

    let view = hello_view(HelloViewProps)
    let context = context_agent.render_context(ca)
    let body = render(view, context)

    let _ = websocket.send(sub, TextMessage(body))

    io.print("Connected!")
    io.debug(sub)

    Nil
  })
  |> websocket.on_close(fn(sub) {
    context_agent.pop_client(ca, sub)

    io.print("Disconnected!")
    io.debug(sub)

    Nil
  })
  |> mist.upgrade
}

fn load_port() -> Int {
  os.get_env("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}
