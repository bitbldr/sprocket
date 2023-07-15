import gleam/io
import gleam/int
import gleam/string
import gleam/option.{None, Option}
import sprocket/socket.{Socket}
import sprocket/hooks.{WithDeps, dep}
import sprocket/component.{render}
import sprocket/hooks/reducer.{State, reducer}
import sprocket/hooks/effect.{effect}
import sprocket/hooks/callback.{callback}
import sprocket/identifiable_callback.{CallbackFn}
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

pub fn counter(socket: Socket, props: CounterProps) {
  let CounterProps(initial) = props

  // Define a reducer to handle events and update the state
  use socket, State(count, dispatch) <- reducer(
    socket,
    option.unwrap(initial, 0),
    update,
  )

  // Example effect that runs every time count changes
  use socket <- effect(
    socket,
    fn() {
      io.println(string.append("Count: ", int.to_string(count)))
      None
    },
    WithDeps([dep(count)]),
  )

  // Define event handlers
  use socket, on_increment <- callback(
    socket,
    CallbackFn(fn() { dispatch(UpdateCounter(count + 1)) }),
    WithDeps([dep(count)]),
  )
  use socket, on_decrement <- callback(
    socket,
    CallbackFn(fn() { dispatch(UpdateCounter(count - 1)) }),
    WithDeps([dep(count)]),
  )

  render(
    socket,
    [
      div(
        [class("flex flex-row m-4")],
        [
          button(
            [
              class(
                "p-1 px-2 border dark:border-gray-500 rounded-l bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 active:bg-gray-300 dark:active:bg-gray-600",
              ),
              on_click(on_decrement),
            ],
            [text("-")],
          ),
          span(
            [
              class(
                "p-1 px-2 w-10 border-t border-b dark:border-gray-500 align-center text-center",
              ),
            ],
            [text(int.to_string(count))],
          ),
          button(
            [
              class(
                "p-1 px-2 border dark:border-gray-500 rounded-r bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 active:bg-gray-300 dark:active:bg-gray-600",
              ),
              on_click(on_increment),
            ],
            [text("+")],
          ),
        ],
      ),
    ],
  )
}
