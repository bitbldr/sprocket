import gleam/io
import gleam/erlang
import gleam/option.{None, Option, Some}
import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/hooks.{WithDeps, dep}
import sprocket/hooks/reducer.{reducer}
import sprocket/hooks/effect.{effect}
import sprocket/html.{span, text}
import sprocket/internal/utils/timer.{interval}

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
  ClockProps(label: Option(String), time_unit: Option(erlang.TimeUnit))
}

pub fn clock(ctx: Context, props: ClockProps) {
  let ClockProps(label, time_unit) = props

  // Define a reducer to handle events and update the state
  use ctx, Model(time: time, ..), dispatch <- reducer(ctx, initial(), update)

  // Example effect with an empty list of dependencies, runs once on mount
  use ctx <- effect(
    ctx,
    fn() {
      io.println("Clock component mounted!")
      None
    },
    WithDeps([]),
  )

  let time_unit =
    time_unit
    |> option.unwrap(erlang.Second)

  // Example effect that runs whenever the `time` variable changes and has a cleanup function
  use ctx <- effect(
    ctx,
    fn() {
      let interval_duration = case time_unit {
        erlang.Millisecond -> 1
        erlang.Second -> 1000
        _ -> 1000
      }

      let update_time = fn() {
        dispatch(UpdateTime(erlang.system_time(time_unit)))
      }

      update_time()

      let cancel = interval(interval_duration, update_time)

      Some(fn() { cancel() })
    },
    WithDeps([dep(time), dep(time_unit)]),
  )

  let current_time = format_time(time, "%y-%m-%d %I:%M:%S %p")

  render(
    ctx,
    case label {
      Some(label) -> [span([], [text(label)]), span([], [text(current_time)])]
      None -> [text(current_time)]
    },
  )
}

@external(erlang, "Elixir.FFIUtils", "format_time")
pub fn format_time(a: a, b: String) -> String
