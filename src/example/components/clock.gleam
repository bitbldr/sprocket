import gleam/io
import gleam/erlang
import gleam/int
import gleam/option.{None, Option, Some}
import gleam/dynamic
import sprocket/socket.{Component, Socket, WithDependencies}
import sprocket/component.{State, effect, reducer, render}
import sprocket/html.{text}
import example/utils/timer.{interval}

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

pub type ClockProps {
  ClockProps(label: Option(String))
}

pub fn clock(socket: Socket, props) {
  let ClockProps(label) = props

  use socket, State(Model(time: time, ..), dispatch) <- reducer(
    socket,
    initial(),
    update,
  )

  let current_time = int.to_string(time)

  // example effect with an empty list of dependencies, runs once on mount
  use socket <- effect(
    socket,
    fn() {
      io.println("Clock component mounted!")
      None
    },
    WithDependencies([]),
  )

  // example effect that runs whenever the `time` variable changes and has a cleanup function
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

  render(
    socket,
    case label {
      Some(label) -> [text(label), text(current_time)]
      None -> [text(current_time)]
    },
  )
}
