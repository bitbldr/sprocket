import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import sprocket.{Sprocket}
import sprocket/socket.{WebSocket}

pub type Cassette =
  Subject(Message)

pub type State {
  State(sprockets: List(Sprocket))
}

pub type Message {
  Shutdown
  PushSprocket(sprocket: Sprocket)
  GetSprocket(reply_with: Subject(Result(Sprocket, Nil)), ws: WebSocket)
  PopSprocket(reply_with: Subject(Result(Sprocket, Nil)), ws: WebSocket)
}

fn handle_message(message: Message, state: State) -> actor.Next(State) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    PushSprocket(sprocket) -> {
      let updated_sprockets =
        list.reverse([sprocket, ..list.reverse(state.sprockets)])
      actor.Continue(State(sprockets: updated_sprockets))
    }

    GetSprocket(reply_with, ws) -> {
      let skt =
        list.find(state.sprockets, fn(s) { sprocket.has_websocket(s, ws) })

      process.send(reply_with, skt)

      actor.Continue(state)
    }

    PopSprocket(reply_with, ws) -> {
      let sprocket =
        list.find(state.sprockets, fn(s) { sprocket.has_websocket(s, ws) })

      process.send(reply_with, sprocket)

      case sprocket {
        Ok(sprocket) -> {
          sprocket.stop(sprocket)

          let updated_sprockets =
            list.filter(state.sprockets, fn(s) { sprocket != s })

          let new_state = State(sprockets: updated_sprockets)

          actor.Continue(new_state)
        }

        Error(_) -> actor.Continue(state)
      }
    }
  }
}

pub fn start() {
  let assert Ok(ca) = actor.start(State(sprockets: []), handle_message)

  ca
}

pub fn stop(ca: Cassette) {
  process.send(ca, Shutdown)
}

pub fn push_sprocket(ca: Cassette, sprocket: Sprocket) {
  process.send(ca, PushSprocket(sprocket))
}

pub fn get_sprocket(ca: Cassette, ws: WebSocket) {
  process.call(ca, GetSprocket(_, ws), 10)
}

pub fn pop_sprocket(ca: Cassette, ws: WebSocket) {
  process.call(ca, PopSprocket(_, ws), 10)
}
