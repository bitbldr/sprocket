import gleam/int
import gleam/string
import sprocket/context.{Context}
import sprocket/component.{component}
import sprocket/html.{button, text}
import sprocket/html/attributes.{id, on_click}
import sprocket/hooks.{WithDeps, dep}
import sprocket/hooks/state.{state}
import sprocket/hooks/callback.{callback}
import sprocket/internal/identifiable_callback.{CallbackFn}
import test_helpers.{ClickEvent, live, render_event, render_html}

type TestCounterProps {
  TestCounterProps
}

fn inc_reset_on_button_click_using_state(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, count, set_count <- state(ctx, 0)

  // Define event handlers
  use ctx, on_increment <- callback(
    ctx,
    CallbackFn(fn() { set_count(count + 1) }),
    WithDeps([dep(count)]),
  )
  use ctx, on_reset <- callback(
    ctx,
    CallbackFn(fn() { set_count(0) }),
    WithDeps([dep(count)]),
  )

  let current_count = int.to_string(count)

  component.render(
    ctx,
    [
      text("current count is: "),
      text(current_count),
      button([id("increment"), on_click(on_increment)], [text("increment")]),
      button([id("reset"), on_click(on_reset)], [text("reset")]),
    ],
  )
}

pub fn counter_should_increment_and_reset_using_state_test() {
  let view = component(inc_reset_on_button_click_using_state, TestCounterProps)

  let spkt = live(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")

  // click increment button
  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 1")

  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 2")

  // click reset button
  let spkt = render_event(spkt, ClickEvent, "reset")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")
}
