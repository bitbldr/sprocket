import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/html.{article, code_text, h1, p, span_text, text}
import sprocket/html/attributes.{class}
import docs/utils/codeblock.{codeblock}
import docs/utils/common.{example}
import docs/components/events_counter.{CounterProps, counter}

pub type PropsAndEventsPageProps {
  PropsAndEventsPageProps
}

pub fn props_and_events_page(socket: Socket, _props: PropsAndEventsPageProps) {
  render(
    socket,
    [
      article(
        [],
        [
          h1([], [text("Props and Events")]),
          p(
            [],
            [
              text(
                "
                  Props and events in Sprocket are how components communicate with each other. Props are how components communicate
                  with their children, and events are how components communicate with their parents in the component hierarchy.
                ",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "
                  Props are passed to components as arguments to the component function. Event callbacks are
                  are also passed to components as props in the form of a function. The component
                  can then call the event callback when an event occurs, notifying the parent.
                ",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "Let's take a look at how props and events work in a functional example. In this example, the ",
              ),
              code_text([], "counter"),
              text(" component is passing a prop called "),
              code_text([], "on_click"),
              text(" to the two "),
              code_text([], "button"),
              text(
                "
                    components. The ",
              ),
              code_text([], "counter"),
              text(" component is also passing a prop called "),
              code_text([], "count"),
              text(" to the "),
              code_text([], "display"),
              text(
                " component.
                ",
              ),
              text(
                "
                    When the ",
              ),
              code_text([], "button"),
              text(" components are clicked, they call the "),
              code_text([], "on_click"),
              text(
                " event handler that was passed to them
                    as a prop. The ",
              ),
              code_text([], "counter"),
              text(" component then increments its "),
              code_text([], "count"),
              text(" state and re-renders. The "),
              code_text([], "display"),
              text(
                " component
                    is also re-rendered because its ",
              ),
              code_text([], "count"),
              text(
                " prop has changed. We're using Tailwind CSS to style the components here, but you can use any CSS framework you like.
                ",
              ),
            ],
          ),
          codeblock(
            "gleam",
            "
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
              CounterProps
            }

            pub fn counter(socket: Socket, _props: CounterProps) {
              // Define a reducer to handle events and update the state
              use socket, State(count, dispatch) <- reducer(socket, 0, update)

              render(
                socket,
                [
                  div(
                    [class(\"flex flex-row m-4\")],
                    [
                      component(
                        button,
                        ButtonProps(
                          class: Some(\"rounded-l\"),
                          label: \"-\",
                          on_click: fn() { dispatch(UpdateCounter(count - 1)) },
                        ),
                      ),
                      component(display, DisplayProps(count: count)),
                      component(
                        button,
                        ButtonProps(
                          class: Some(\"rounded-r\"),
                          label: \"+\",
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
                          \"p-1 px-2 border dark:border-gray-500 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 active:bg-gray-300 dark:active:bg-gray-600\",
                        ),
                      ]),
                    ],
                    label,
                  ),
                ],
              )
            }

            pub type DisplayProps {
              DisplayProps(count: Int)
            }

            pub fn display(socket: Socket, props: DisplayProps) {
              let DisplayProps(count: count) = props

              render(
                socket,
                [
                  span(
                    [
                      class(
                        \"p-1 px-2 w-10 bg-white dark:bg-gray-900 border-t border-b dark:border-gray-500 align-center text-center\",
                      ),
                    ],
                    [text(int.to_string(count))],
                  ),
                ],
              )
            }
            ",
          ),
          example([component(counter, CounterProps(enable_reset: False))]),
          p(
            [],
            [
              text(
                "
                  We can expand the ",
              ),
              code_text([], "display"),
              text(" component to accept another optional prop called "),
              code_text([], "on_reset"),
              text(
                " which will reset the count and re-render the component when the ",
              ),
              code_text([], "display"),
              text(" component is double-clicked."),
            ],
          ),
          codeblock(
            "gleam",
            "
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
                        \"p-1 px-2 w-10 bg-white dark:bg-gray-900 border-t border-b dark:border-gray-500 align-center text-center\",
                      ),
                    ],
                    [text(int.to_string(count))],
                  ),
                ],
              )
            }
            ",
          ),
          example([component(counter, CounterProps(enable_reset: True))]),
          p(
            [],
            [
              text("So "),
              span_text([class("font-bold")], "state flows down"),
              text(" the component tree while "),
              span_text([class("font-bold")], "events bubble up"),
              text(
                ".
                We'll cover state management more in-depth in the next section, but it's useful to start thinking about how this data-flow will inform
                where state should live in your component hierarchy. And since we have the safety provided by the Gleam type system,
                we aren't afraid of refactoring our state to a different part of the hierarchy when our requirements or designs inevitably change!",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
