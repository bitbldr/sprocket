// import example/routes
import example/log
import gleam/io
import gleam/int
import gleam/string
import gleam/list
import gleam/result
import gleam/erlang/os
import gleam/erlang/process.{Subject}
import mist
import mist/websocket
import mist/internal/websocket.{TextMessage} as internal_websocket
import sprocket/context_agent.{Client, ContextMessage}
import gleam/http/request.{Request}
import gleam/http/response
import gleam/http.{Get}
import gleam/bit_builder
import sprocket/render.{render}
import example/hello_view.{HelloViewProps, hello_view}
import gleam/erlang/file

pub fn main() {
  log.configure_backend()
  let port = load_port()
  let ca = context_agent.start()
  // let web = routes.stack(ca)

  string.concat(["Listening on localhost:", int.to_string(port), " ✨"])
  |> log.info

  // let assert Ok(_) = mist.run_service(port, web, max_body_limit: 4_000_000)
  // process.sleep_forever()

  let assert Ok(_) =
    mist.serve(
      port,
      mist.handler_func(fn(req) {
        case req.method, request.path_segments(req) {
          Get, ["live"] -> websocket_echo(ca)
          Get, ["client.js"] -> client(req)
          Get, [] -> index(req, ca)
        }
      }),
    )
  process.sleep_forever()
}

pub external fn priv_directory() -> String =
  "example_ffi" "priv_directory"

fn client(_req: Request(mist.Body)) {
  let path = string.concat([priv_directory(), "/static/client.js"])

  let file_contents =
    path
    |> file.read_bits
    |> result.nil_error
    |> result.map(bit_builder.from_bit_string)

  let extension =
    path
    |> string.split(on: ".")
    |> list.last
    |> result.unwrap("")

  case file_contents {
    Ok(bits) -> {
      let content_type = case extension {
        "html" -> "text/html"
        "css" -> "text/css"
        "js" -> "application/javascript"
        "png" | "jpg" -> "image/jpeg"
        "gif" -> "image/gif"
        "svg" -> "image/svg+xml"
        "ico" -> "image/x-icon"
        _ -> "octet-stream"
      }

      response.new(200)
      |> response.prepend_header("content-type", content_type)
      |> mist.bit_builder_response(bits)
    }
    Error(_) ->
      response.new(500)
      |> mist.empty_response
  }
}

fn index(_req: Request(mist.Body), ca: Subject(ContextMessage)) {
  let view = hello_view(HelloViewProps)

  let context = context_agent.render_context(ca)

  let body = render(view, context)

  response.new(200)
  |> response.prepend_header("content-type", "text/html")
  |> mist.bit_builder_response(bit_builder.from_string(body))
}

fn websocket_echo(ca: Subject(ContextMessage)) {
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
