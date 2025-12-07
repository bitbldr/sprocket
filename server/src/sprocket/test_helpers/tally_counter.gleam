import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub opaque type State {
  State(count: Int)
}

pub opaque type Message {
  Shutdown
  Increment
  GetCount(reply_with: Subject(Int))
}

fn handle_message(state: State, message: Message) -> actor.Next(State, Message) {
  case message {
    Shutdown -> {
      actor.stop()
    }

    Increment -> {
      actor.continue(State(count: state.count + 1))
    }

    GetCount(reply_with) -> {
      process.send(reply_with, state.count)
      actor.continue(state)
    }
  }
}

pub fn start() {
  let assert Ok(actor.Started(data: actor, ..)) =
    actor.new(State(count: 0))
    |> actor.on_message(handle_message)
    |> actor.start()

  actor
}

pub fn stop(actor) {
  actor.send(actor, Shutdown)
}

pub fn increment(actor) {
  actor.send(actor, Increment)
}

pub fn get_count(actor) -> Int {
  process.call(actor, 1000, GetCount)
}
