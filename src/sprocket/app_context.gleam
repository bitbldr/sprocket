import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import sprocket/socket.{SocketActor, WebSocket}

pub type AppContext =
  Subject(Message)

pub type State {
  State(cassette: List(SocketActor))
}

pub type Message {
  Shutdown
  PushSocket(socket: SocketActor)
  GetSocket(reply_with: Subject(Result(SocketActor, Nil)), ws: WebSocket)
  PopSocket(reply_with: Subject(Result(SocketActor, Nil)), ws: WebSocket)
}

fn handle_message(message: Message, state: State) -> actor.Next(State) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    PushSocket(socket) -> {
      let r_sockets = list.reverse(state.cassette)
      let updated_sockets = list.reverse([socket, ..r_sockets])
      actor.Continue(State(cassette: updated_sockets))
    }

    GetSocket(reply_with, ws) -> {
      let skt =
        list.find(state.cassette, fn(s) { socket.matches_websocket(s, ws) })

      process.send(reply_with, skt)

      actor.Continue(state)
    }

    PopSocket(reply_with, ws) -> {
      let socket =
        list.find(state.cassette, fn(s) { socket.matches_websocket(s, ws) })

      process.send(reply_with, socket)

      case socket {
        Ok(socket) -> {
          socket.stop(socket)

          let updated_cassete =
            list.filter(state.cassette, fn(s) { socket != s })

          let new_state = State(cassette: updated_cassete)

          actor.Continue(new_state)
        }

        Error(_) -> actor.Continue(state)
      }
    }
  }
}

pub fn start() {
  let assert Ok(app_context) = actor.start(State(cassette: []), handle_message)

  app_context
}

pub fn stop(app_context) {
  process.send(app_context, Shutdown)
}

pub fn push_socket(app_context: AppContext, sa: SocketActor) {
  process.send(app_context, PushSocket(sa))
}

pub fn get_socket(app_context: AppContext, ws: WebSocket) {
  process.call(app_context, GetSocket(_, ws), 10)
}

pub fn pop_socket(app_context: AppContext, ws: WebSocket) {
  process.call(app_context, PopSocket(_, ws), 10)
}
