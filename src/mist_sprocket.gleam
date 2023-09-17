import gleam/io
import gleam/list
import gleam/bit_string
import gleam/bit_builder.{BitBuilder}
import gleam/otp/actor
import gleam/erlang/process
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import mist.{Connection, ResponseData}
import sprocket/sprocket
import sprocket/cassette.{Cassette}
import sprocket/render.{render}
import sprocket/component.{component}
import sprocket/internal/render/html as sprocket_html
import sprocket/context.{FunctionalComponent}
import sprocket/internal/utils/unique
import sprocket/internal/logger

pub fn live(
  req: Request(Connection),
  ca: Cassette,
  view: FunctionalComponent(p),
  props: p,
) -> Response(ResponseData) {
  let view = component(view, props)

  // if the request path ends with "live", then start a websocket connection
  case list.last(request.path_segments(req)) {
    Ok("live") -> {
      let selector = process.new_selector()

      let id = unique.new()

      req
      |> mist.websocket()
      |> mist.with_state(Nil)
      |> mist.selecting(selector)
      |> mist.on_message(fn(state, conn, message) {
        handle_ws_message(id, state, conn, message, ca, view)
      })
      |> mist.upgrade()
    }

    _ -> {
      let body = render(view, sprocket_html.renderer())

      response.new(200)
      |> response.set_body(body)
      |> response.prepend_header("content-type", "text/html")
      |> response.map(bit_builder.from_string)
      |> mist_response()
    }
  }
}

fn mist_response(response: Response(BitBuilder)) -> Response(ResponseData) {
  response.new(response.status)
  |> response.set_body(mist.Bytes(response.body))
}

fn handle_ws_message(id, state: Nil, conn, message, ca, view) {
  let ws_send = fn(msg) {
    let assert Ok(_) = mist.send_text_frame(conn, bit_string.from_string(msg))
    Ok(Nil)
  }

  case message {
    mist.Text(msg) -> {
      let assert Ok(msg) = bit_string.to_string(msg)
      let assert Ok(_) = cassette.live_message(ca, id, view, msg, ws_send)

      actor.continue(state)
    }

    mist.Closed | mist.Shutdown -> {
      let spkt = cassette.pop_sprocket(ca, id)
      case spkt {
        Ok(sprocket) -> {
          sprocket.stop(sprocket)
          Ok(Nil)
        }
        Error(_) -> {
          logger.error(
            "failed to pop sprocket with id: " <> unique.to_string(id),
          )
          Ok(Nil)
        }
      }
      actor.Stop(process.Normal)
    }
    _ -> {
      logger.info("Received unsupported websocket message type")
      io.debug(message)

      actor.continue(state)
    }
  }
}
