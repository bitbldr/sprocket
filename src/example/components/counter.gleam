import gleam/io
import gleam/int
import gleam/dynamic
import gleam/string
import gleam/option.{None, Option}
import sprocket/socket.{Component, Socket, WithDependencies}
import sprocket/component.{State, effect, reducer, render}
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
  Component(fn(socket: Socket) {
    let CounterProps(initial) = props

    use socket, State(count, dispatch) <- reducer(
      socket,
      option.unwrap(initial, 0),
      update,
    )

    // example effect that runs on every update
    use socket <- effect(
      socket,
      fn() {
        io.println(string.append("Count: ", int.to_string(count)))
        None
      },
      WithDependencies([dynamic.from(count)]),
    )

    let on_increment = fn() { dispatch(UpdateCounter(count + 1)) }
    let on_decrement = fn() { dispatch(UpdateCounter(count - 1)) }

    render(
      socket,
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
              [
                class(
                  "p-1 px-2 w-10 border-t border-b align-center text-center",
                ),
              ],
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
      ],
    )
  })
}
