import gleam/io
import gleam/erlang
import gleam/int
import gleam/option.{None, Option, Some}
import sprocket/component.{
  Component, ComponentContext, EffectCleanup, NoCleanup, OnUpdate, State,
  WithDependencies, effect, reducer,
}
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

pub fn clock(props: ClockProps) {
  Component(fn(ctx: ComponentContext) {
    let ClockProps(label) = props

    let State(Model(time: time, ..), dispatch) = reducer(ctx, initial(), update)

    // effect(
    //   ctx,
    //   fn() {
    //     let cancel =
    //       interval(
    //         1000,
    //         fn() { dispatch(UpdateTime(erlang.system_time(erlang.Second))) },
    //       )

    //     EffectCleanup(fn() { cancel() })
    //   },
    //   WithDependencies([]),
    // )

    let current_time = int.to_string(time)

    // TODO: not working, infinite loop
    // effect(
    //   ctx,
    //   fn() {
    //     io.println(current_time)
    //     NoCleanup
    //   },
    //   OnUpdate,
    // )

    case label {
      Some(label) -> [text(label), text(current_time)]
      None -> [text(current_time)]
    }
  })
}
