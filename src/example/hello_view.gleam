import gleam/option.{Some}
import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import example/components/clock.{ClockProps, clock}
import example/components/counter.{CounterProps, counter}
import sprocket/html.{
  body, dangerous_raw_html, div, h1, head, html, link, p, script, text,
}
import sprocket/html/attribute.{class, href, lang, rel, src}

pub type HelloViewProps {
  HelloViewProps
}

pub fn hello_view(socket: Socket, _props: HelloViewProps) {
  render(
    socket,
    [
      html(
        [lang("en")],
        [
          head([], [link([rel("stylesheet"), href("/app.css")])]),
          body(
            [class("bg-white dark:bg-gray-900 dark:text-white p-4")],
            [
              div(
                [],
                [
                  h1([class("text-xl mb-2")], [text("Hello World!")]),
                  component(
                    clock,
                    ClockProps(label: Some("The current time is: ")),
                  ),
                ],
              ),
              div(
                [],
                [
                  p(
                    [],
                    [
                      text(
                        "An html escaped & safe <span style=\"color: green\">string</span>",
                      ),
                    ],
                  ),
                  p(
                    [],
                    [
                      dangerous_raw_html(
                        "A <b>raw <em>html</em></b> <span style=\"color: blue\">string</span></b>",
                      ),
                    ],
                  ),
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
