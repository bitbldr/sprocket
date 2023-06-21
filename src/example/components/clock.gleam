import gleam/io
import gleam/erlang
import gleam/int
import gleam/option.{None, Option, Some}
import gleam/dynamic
import sprocket/socket.{Socket, WithDependencies}
import sprocket/component.{State, effect, reducer, render}
import sprocket/html.{span, text}
import example/utils/timer.{interval}

pub type ClockProps {
  ClockProps(label: Option(String))
}

pub fn clock(socket: Socket, props) {
  let ClockProps(label) = props

  // Define a reducer to handle events and update the state
  use socket, State(Model(time: time, ..), dispatch) <- reducer(
    socket,
    initial(),
    update,
  )

  // Example effect with an empty list of dependencies, runs once on mount
  use socket <- effect(
    socket,
    fn() {
      io.println("Clock component mounted!")
      None
    },
    WithDependencies([]),
  )

  // Example effect that runs whenever the `time` variable changes and has a cleanup function
  use socket <- effect(
    socket,
    fn() {
      let cancel =
        interval(
          1000,
          fn() { dispatch(UpdateTime(erlang.system_time(erlang.Second))) },
        )

      Some(fn() { cancel() })
    },
    WithDependencies([dynamic.from(time)]),
  )

  let current_time = int.to_string(time)

  render(
    socket,
    case label {
      Some(label) -> [span([], [text(label)]), span([], [text(current_time)])]
      None -> [text(current_time)]
    },
  )
}

type Model {
  Model(time: Int, timezone: String)
}

type Msg {
  UpdateTime(Int)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UpdateTime(time) -> {
      Model(..model, time: time)
    }
  }
}

fn initial() -> Model {
  Model(time: erlang.system_time(erlang.Second), timezone: "UTC")
}
