import gleam/int
import gleam/option.{Option}
import sprocket/component.{Component, ComponentContext, State, reducer}
import sprocket/html.{button, div, span, text}
import sprocket/html/attribute.{class, on_click}

type Model =
  Int

type Msg {
  UpdateCounter(Int)
}

fn update(_model: Model, msg: Msg) -> Model {
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

    let on_increment = fn() { dispatch(UpdateCounter(count + 1)) }
    let on_decrement = fn() { dispatch(UpdateCounter(count - 1)) }

    [
      div(
        [class("flex flex-row m-4")],
        [
          button(
            [
              class("p-1 px-2 border rounded-l bg-gray-100"),
              on_click(on_decrement),
            ],
            [text("-")],
          ),
          span(
            [class("p-1 px-2 w-10 border-t border-b align-center text-center")],
            [text(int.to_string(count))],
          ),
          button(
            [
              class("p-1 px-2 border rounded-r bg-gray-100"),
              on_click(on_increment),
            ],
            [text("+")],
          ),
        ],
      ),
    ]
  })
}
