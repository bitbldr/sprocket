import gleam/option.{Some}
import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import example/components/clock.{ClockProps, clock}
import example/components/counter.{CounterProps, counter}
import sprocket/html.{body, div, h1, head, html, link, script, text}
import sprocket/html/attribute.{class, href, rel, src}

pub type HelloViewProps {
  HelloViewProps
}

pub fn hello_view(socket: Socket, _props: HelloViewProps) {
  render(
    socket,
    [
      html(
        [],
        [
          head([], [link([href("/app.css"), rel("stylesheet")])]),
          body(
            [class("bg-white dark:bg-gray-900 dark:text-white")],
            [
              div(
                [],
                [
                  h1([], [text("Hello World!")]),
                  component(
                    clock,
                    ClockProps(label: Some("The current time is: ")),
                  ),
                ],
              ),
              div(
                [],
                [
                  text("A test component"),
                  component(counter, CounterProps(initial: Some(0))),
                ],
              ),
              script([src("/client.js")], []),
            ],
          ),
        ],
      ),
    ],
  )
}
