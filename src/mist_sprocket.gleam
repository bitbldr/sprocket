import gleam/io
import gleam/option.{None}
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
      let id = unique.new()

      req
      |> mist.websocket(
        fn(state, conn, message) {
          handle_ws_message(id, state, conn, message, ca, view)
        },
        fn() { #(Nil, None) },
        fn() { maybe_cleanup_sprocket(ca, id) },
      )
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
    case mist.send_text_frame(conn, bit_string.from_string(msg)) {
      Ok(_) -> Ok(Nil)
      Error(_) -> {
        logger.error("failed to send websocket message: " <> msg)
        Ok(Nil)
      }
    }
  }

  case message {
    mist.Text(msg) -> {
      let assert Ok(msg) = bit_string.to_string(msg)
      let assert Ok(_) = cassette.live_message(ca, id, view, msg, ws_send)

      actor.continue(state)
    }

    mist.Closed | mist.Shutdown -> {
      maybe_cleanup_sprocket(ca, id)

      actor.Stop(process.Normal)
    }
    _ -> {
      logger.info("Received unsupported websocket message type")
      io.debug(message)

      actor.continue(state)
    }
  }
}

// If the sprocket is still in the cassette, stop it. This can be called
// either when the websocket received a CLOSED message or when connection is
// terminated. In the latter case, the sprocket may already have been removed
fn maybe_cleanup_sprocket(ca: Cassette, id: unique.Unique) {
  let spkt = cassette.pop_sprocket(ca, id)
  case spkt {
    Ok(sprocket) -> {
      sprocket.stop(sprocket)
    }
    Error(_) -> {
      Nil
    }
  }
}
