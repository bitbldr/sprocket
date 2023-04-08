import gleam/option.{Some}
import sprocket/component.{Component}
import example/components/clock.{ClockProps, clock}
import sprocket/html.{body, div, h1, html, text}

pub type HelloViewProps {
  HelloViewProps
}

pub fn hello_view(_props: HelloViewProps) {
  Component(fn(_) {
    [
      html(
        [],
        [
          body(
            [],
            [
              div(
                [],
                [
                  h1([], [text("Hello World!")]),
                  clock(ClockProps(label: Some("The current time is: "))),
                ],
              ),
              div([], [text("A test component")]),
            ],
          ),
        ],
      ),
    ]
  })
}
