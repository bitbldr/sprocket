import gleam/erlang
import gleam/int
import gleam/option.{None, Option, Some}
import sprocket/component.{Component, ComponentContext}
import sprocket/html.{text}

pub type ClockProps {
  ClockProps(label: Option(String))
}

pub fn clock(props: ClockProps) {
  Component(fn(_ctx: ComponentContext) {
    let ClockProps(label) = props

    let current_time =
      erlang.system_time(erlang.Second)
      |> int.to_string

    case label {
      Some(label) -> [text(label), text(current_time)]
      None -> [text(current_time)]
    }
  })
}
