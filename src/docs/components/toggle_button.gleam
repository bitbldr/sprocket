import sprocket/context.{Context, Element}
import sprocket/component.{render}
import sprocket/html.{button}
import sprocket/html/attributes.{class, on_click}
import sprocket/hooks.{WithDeps, dep}
import sprocket/hooks/callback.{callback}
import sprocket/internal/identifiable_callback.{CallbackFn}
import sprocket/hooks/state.{state}

pub type ToggleButtonProps {
  ToggleButtonProps(render_label: fn(Bool) -> Element)
}

pub fn toggle_button(ctx: Context, props: ToggleButtonProps) {
  let ToggleButtonProps(render_label) = props

  // add a state hook to track the active state, we'll cover hooks in more detail later
  use ctx, is_active, set_active <- state(ctx, False)

  // add a callback hook to toggle the active state
  use ctx, on_toggle_active <- callback(
    ctx,
    CallbackFn(fn() {
      set_active(!is_active)
      Nil
    }),
    WithDeps([dep(is_active)]),
  )

  render(
    ctx,
    [
      button(
        [
          class(case is_active {
            True ->
              "rounded-lg text-white px-3 py-2 bg-green-700 hover:bg-green-800 active:bg-green-900"
            False ->
              "rounded-lg text-white px-3 py-2 bg-blue-500 hover:bg-blue-600 active:bg-blue-700"
          }),
          on_click(on_toggle_active),
        ],
        [render_label(is_active)],
      ),
    ],
  )
}
