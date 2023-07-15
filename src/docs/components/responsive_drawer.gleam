import gleam/option.{Some}
import sprocket/socket.{Socket}
import sprocket/component.{render}
import sprocket/hooks.{OnMount}
import sprocket/hooks/reducer.{State, reducer}
import sprocket/hooks/callback.{callback}
import sprocket/identifiable_callback.{CallbackFn}
import sprocket/element.{Element}
import sprocket/html.{aside, button, div, i}
import sprocket/html/attribute.{class, classes, on_click}

type Model {
  Model(show: Bool)
}

type Msg {
  NoOp
  Show
  Hide
  Toggle
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> model
    Show -> Model(show: True)
    Hide -> Model(show: False)
    Toggle -> Model(show: !model.show)
  }
}

fn initial() -> Model {
  Model(show: False)
}

pub type ResponsiveDrawerProps {
  ResponsiveDrawerProps(drawer: Element, content: Element)
}

pub fn responsive_drawer(socket: Socket, props) {
  let ResponsiveDrawerProps(drawer: drawer, content: content) = props

  use socket, State(Model(show: show), dispatch) <- reducer(
    socket,
    initial(),
    update,
  )

  use socket, toggle_drawer <- callback(
    socket,
    CallbackFn(fn() { dispatch(Toggle) }),
    OnMount,
  )

  use socket, hide_drawer <- callback(
    socket,
    CallbackFn(fn() { dispatch(Hide) }),
    OnMount,
  )

  let backdrop =
    div(
      [
        class(
          "absolute bg-gray-900 bg-opacity-50 dark:bg-opacity-80 inset-0 z-30",
        ),
        on_click(hide_drawer),
      ],
      [],
    )

  render(
    socket,
    [
      div(
        [classes([Some("relative flex-1 flex flex-row")])],
        [
          aside(
            [
              classes([
                case show {
                  True -> Some("block absolute top-0 left-0 bottom-0")
                  False -> Some("hidden")
                },
                Some(
                  "sm:block w-64 z-40 transition-transform -translate-x-full translate-x-0 transition-transform",
                ),
              ]),
            ],
            [
              div(
                [
                  class(
                    "h-full px-3 py-4 overflow-y-auto bg-gray-50 dark:bg-gray-800",
                  ),
                ],
                [drawer],
              ),
            ],
          ),
          div(
            [class("flex-1")],
            [
              button(
                [
                  on_click(toggle_drawer),
                  class(
                    "
                    inline-flex
                    sm:hidden
                    items-center
                    p-2
                    mt-2
                    ml-3
                    text-sm
                    text-gray-500
                    rounded-lg
                    hover:bg-gray-100
                    focus:outline-none
                    focus:ring-2
                    focus:ring-gray-200
                    dark:text-gray-400
                    dark:hover:bg-gray-700
                    dark:focus:ring-gray-600
                  ",
                  ),
                ],
                [i([class("fa-solid fa-bars")], [])],
              ),
              content,
            ],
          ),
          ..case show {
            True -> [backdrop]
            False -> []
          }
        ],
      ),
    ],
  )
}
