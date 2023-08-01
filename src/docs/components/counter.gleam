import gleam/io
import gleam/int
import gleam/string
import gleam/option.{None, Option}
import sprocket/context.{Context}
import sprocket/hooks.{WithDeps, dep}
import sprocket/component.{render}
import sprocket/hooks/reducer.{reducer}
import sprocket/hooks/effect.{effect}
import sprocket/hooks/callback.{callback}
import sprocket/internal/identifiable_callback.{CallbackFn}
import sprocket/html.{button, div, span, text}
import sprocket/html/attributes.{class, on_click}

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

pub fn counter(ctx: Context, props: CounterProps) {
  let CounterProps(initial) = props

  // Define a reducer to handle events and update the state
  use ctx, count, dispatch <- reducer(ctx, option.unwrap(initial, 0), update)

  // Example effect that runs every time count changes
  use ctx <- effect(
    ctx,
    fn() {
      io.println(string.append("Count: ", int.to_string(count)))
      None
    },
    WithDeps([dep(count)]),
  )

  // Define event handlers
  use ctx, on_increment <- callback(
    ctx,
    CallbackFn(fn() { dispatch(UpdateCounter(count + 1)) }),
    WithDeps([dep(count)]),
  )
  use ctx, on_decrement <- callback(
    ctx,
    CallbackFn(fn() { dispatch(UpdateCounter(count - 1)) }),
    WithDeps([dep(count)]),
  )

  render(
    ctx,
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
