import gleam/option.{Option}
import sprocket/sprocket
import sprocket/context.{Element}
import sprocket/cassette.{Cassette, CassetteOpts}
import sprocket/internal/utils/unique

pub type SprocketOptions {
  SprocketOptions(cassette_opts: Option(CassetteOpts))
}

/// Start the cassette. This function is typically called when the server starts. It will
/// start the cassette and setup the websocket handler.
pub fn start(
  validate_csrf: fn(String) -> Result(Nil, Nil),
  opts: Option(SprocketOptions),
) {
  cassette.start(
    validate_csrf,
    opts
    |> option.map(fn(opts) { opts.cassette_opts })
    |> option.flatten(),
  )
}

/// Stop the cassette. This function is typically called when the server stops. It will
/// stop and cleanup all sprockets that are currently running.
pub fn stop(ca: Cassette) {
  cassette.stop(ca)
}

/// Handle a message from the websocket. This function is called when a message is received
/// from the websocket. It will find the sprocket that is associated with the websocket and
/// pass the message to the sprocket. The sprocket will then handle the message and send
/// a response back to the websocket.
pub fn handle_client(
  id: String,
  ca: Cassette,
  view: Element,
  msg: String,
  ws_send: fn(String) -> Result(Nil, Nil),
) -> Result(Nil, Nil) {
  cassette.client_message(ca, unique.from_string(id), view, msg, ws_send)
}

/// Cleanup a sprocket. This function is called when a websocket is closed. It will find
/// the sprocket that is associated with the websocket and stop it.
///
/// Its important to call this function when the websocket connection is terminated.
pub fn cleanup(ca: Cassette, id: String) {
  let spkt = cassette.pop_sprocket(ca, unique.from_string(id))

  case spkt {
    Ok(sprocket) -> {
      sprocket.stop(sprocket)
    }
    Error(_) -> {
      Nil
    }
  }
}
