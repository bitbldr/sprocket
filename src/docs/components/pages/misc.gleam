import gleam/option.{Some}
import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/html.{article, dangerous_raw_html, div, h1, h2, p, text}
import sprocket/html/attribute.{class}
import docs/components/clock.{ClockProps, clock}
import docs/components/counter.{CounterProps, counter}
import docs/components/say_hello.{SayHelloProps, say_hello}

pub type MiscPageProps {
  MiscPageProps
}

pub fn misc_page(socket: Socket, _props: MiscPageProps) {
  render(
    socket,
    [
      div(
        [class("flex flex-col p-10")],
        [
          article(
            [class("prose dark:prose-invert max-w-[1000px] mx-auto")],
            [
              h1([], [text("Miscellaneous")]),
              h2([], [text("Step 1: Creating a Component")]),
              p(
                [],
                [
                  text(
                    "Let's create a component that displays the current time. We'll call it ",
                  ),
                  text("Clock"),
                  text("."),
                ],
              ),
              div(
                [],
                [
                  component(
                    clock,
                    ClockProps(label: Some("The current time is: ")),
                  ),
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
                  component(say_hello, SayHelloProps),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
