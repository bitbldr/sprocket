import gleam/int
import gleam/option.{Option}
import sprocket/component.{Component, ComponentContext, State, use_state}
import sprocket/html.{button, div, span, text}
import sprocket/html/attrs.{class}

pub type CounterProps {
  CounterProps(initial: Option(Int))
}

pub fn counter(props: CounterProps) {
  Component(fn(ctx: ComponentContext) {
    let CounterProps(initial) = props

    let State(count, _set_count) = use_state(ctx, option.unwrap(initial, 0))

    [
      div(
        [],
        [
          button([], [text("-")]),
          span([class("px-2")], [text(int.to_string(count))]),
          button([], [text("+")]),
        ],
      ),
    ]
  })
}
