import gleam/option.{Some}
import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import docs/components/clock.{ClockProps, clock}
import docs/components/counter.{CounterProps, counter}
import docs/components/say_hello.{SayHelloProps, say_hello}
import sprocket/html.{dangerous_raw_html, div, h1, p, text}
import sprocket/html/attribute.{class}

pub type IntroductionPageProps {
  IntroductionPageProps
}

pub fn introduction_page(socket: Socket, _props: IntroductionPageProps) {
  render(
    socket,
    [
      div(
        [class("flex flex-col p-4")],
        [
          div(
            [],
            [
              h1([class("text-xl mb-2")], [text("Welcome to Sprocket Docs!")]),
              component(clock, ClockProps(label: Some("The current time is: "))),
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
              component(say_hello, SayHelloProps),
            ],
          ),
        ],
      ),
    ],
  )
}
