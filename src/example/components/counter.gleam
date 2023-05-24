import gleam/int
import gleam/option.{Option}
import sprocket/component.{Component, ComponentContext, State, reducer}
import sprocket/html.{button, div, span, text}
import sprocket/html/attrs.{class}

type Model =
  Int

pub type Msg {
  UpdateCounter(Int)
}

pub fn update(_model: Model, msg: Msg) -> Model {
  case msg {
    UpdateCounter(count) -> {
      count
    }
  }
}

pub type CounterProps {
  CounterProps(initial: Option(Int))
}

pub fn counter(props: CounterProps) {
  Component(fn(ctx: ComponentContext) {
    let CounterProps(initial) = props

    let State(count, dispatch) = reducer(ctx, option.unwrap(initial, 0), update)

    // TODO: use dispatch from event handler
    dispatch(UpdateCounter(count + 1))

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
