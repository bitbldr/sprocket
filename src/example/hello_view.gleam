import gleam/option.{Some}
import sprocket/component.{Component}
import example/components/clock.{ClockProps, clock}
import example/components/counter.{CounterProps, counter}
import sprocket/html.{body, div, h1, head, html, link, script, text}
import sprocket/html/attrs.{class, href, rel, src}

pub type HelloViewProps {
  HelloViewProps
}

pub fn hello_view(_props: HelloViewProps) {
  Component(fn(_) {
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
                  clock(ClockProps(label: Some("The current time is: "))),
                ],
              ),
              div(
                [],
                [
                  text("A test component"),
                  counter(CounterProps(initial: Some(0))),
                ],
              ),
              script([src("/client.js")], []),
            ],
          ),
        ],
      ),
    ]
  })
}
