import gleam/int
import gleam/option.{Option, Some}
import sprocket/socket.{Socket}
import sprocket/hooks.{WithDeps, dep}
import sprocket/component.{component, render}
import sprocket/hooks/reducer.{State, reducer}
import sprocket/hooks/callback.{callback}
import sprocket/internal/identifiable_callback.{CallbackFn}
import sprocket/html.{div, span, text}
import sprocket/html/attributes.{class, classes}

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
  CounterProps(enable_reset: Bool)
}

pub fn counter(socket: Socket, props: CounterProps) {
  let CounterProps(enable_reset: enable_reset) = props

  // Define a reducer to handle events and update the state
  use socket, State(count, dispatch) <- reducer(socket, 0, update)

  render(
    socket,
    [
      div(
        [class("flex flex-row m-4")],
        [
          component(
            button,
            ButtonProps(
              class: Some("rounded-l"),
              label: "-",
              on_click: fn() { dispatch(UpdateCounter(count - 1)) },
            ),
          ),
          component(
            display,
            DisplayProps(
              count: count,
              on_reset: Some(fn() {
                case enable_reset {
                  True -> dispatch(UpdateCounter(0))
                  False -> Nil
                }
              }),
            ),
          ),
          component(
            button,
            ButtonProps(
              class: Some("rounded-r"),
              label: "+",
              on_click: fn() { dispatch(UpdateCounter(count + 1)) },
            ),
          ),
        ],
      ),
    ],
  )
}

pub type ButtonProps {
  ButtonProps(class: Option(String), label: String, on_click: fn() -> Nil)
}

pub fn button(socket: Socket, props: ButtonProps) {
  let ButtonProps(class, label, ..) = props

  use socket, on_click <- callback(
    socket,
    CallbackFn(props.on_click),
    WithDeps([dep(props.on_click)]),
  )

  render(
    socket,
    [
      html.button_text(
        [
          attributes.on_click(on_click),
          classes([
            class,
            Some(
              "p-1 px-2 border dark:border-gray-500 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 active:bg-gray-300 dark:active:bg-gray-600",
            ),
          ]),
        ],
        label,
      ),
    ],
  )
}

pub type DisplayProps {
  DisplayProps(count: Int, on_reset: Option(fn() -> Nil))
}

pub fn display(socket: Socket, props: DisplayProps) {
  let DisplayProps(count: count, on_reset: on_reset) = props

  use socket, on_reset <- callback(
    socket,
    CallbackFn(option.unwrap(on_reset, fn() { Nil })),
    WithDeps([]),
  )

  render(
    socket,
    [
      span(
        [
          attributes.on_doubleclick(on_reset),
          class(
            "p-1 px-2 w-10 bg-white dark:bg-gray-900 border-t border-b dark:border-gray-500 align-center text-center select-none",
          ),
        ],
        [text(int.to_string(count))],
      ),
    ],
  )
}
