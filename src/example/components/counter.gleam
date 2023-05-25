import gleam/int
import gleam/option.{Option}
import sprocket/component.{Component, ComponentContext, State, reducer}
import sprocket/html.{button, div, span, text}
import sprocket/html/attribute.{class, event}

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
    let on_increment = fn() { dispatch(UpdateCounter(count + 1)) }
    let on_decrement = fn() { dispatch(UpdateCounter(count - 1)) }

    [
      div(
        [],
        [
          button([event("click", on_decrement)], [text("-")]),
          span([class("px-2")], [text(int.to_string(count))]),
          button([event("click", on_increment)], [text("+")]),
        ],
      ),
    ]
  })
}
