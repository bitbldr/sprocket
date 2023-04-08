import gleam/erlang
import gleam/int
import gleam/option.{None, Option, Some}
import sprocket/component.{Component, ComponentContext, State, use_state}
import sprocket/html.{text}

pub type ClockProps {
  ClockProps(label: Option(String))
}

pub fn clock(props: ClockProps) {
  Component(fn(ctx: ComponentContext) {
    let ClockProps(label) = props

    let current_time =
      erlang.system_time(erlang.Second)
      |> int.to_string()

    let State(time, _set_time) = use_state(ctx, current_time)

    case label {
      Some(label) -> [text(label), text(time)]
      None -> [text(time)]
    }
  })
}
