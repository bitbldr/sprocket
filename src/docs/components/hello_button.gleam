import gleam/option.{None, Option, Some}
import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/html.{button, text}
import sprocket/html/attributes.{class}

pub type HelloButtonProps {
  HelloButtonProps(label: Option(String))
}

pub fn hello_button(ctx: Context, props: HelloButtonProps) {
  let HelloButtonProps(label) = props

  render(
    ctx,
    [
      button(
        [
          class(
            "p-2 bg-blue-500 hover:bg-blue-600 active:bg-blue-700 text-white rounded",
          ),
        ],
        [
          text(case label {
            Some(label) -> label
            None -> "Click me!"
          }),
        ],
      ),
    ],
  )
}
