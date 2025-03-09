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

fn handle_message(message: Message, state: State) -> actor.Next(Message, State) {
  case message {
    Shutdown -> {
      actor.Stop(process.Normal)
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
  actor.start(State(count: 0), handle_message)
}

pub fn stop(actor) {
  actor.send(actor, Shutdown)
}

pub fn increment(actor) {
  actor.send(actor, Increment)
}

pub fn get_count(actor) -> Int {
  process.call(actor, GetCount, 1000)
}
