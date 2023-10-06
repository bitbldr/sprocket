import gleam/option.{None, Option, Some}
import gleam/erlang
import sprocket/context.{Context}
import sprocket/component.{component, render}
import sprocket/html.{
  article, button_text, dangerous_raw_html, div, h1, h2, p, text,
}
import sprocket/html/attributes.{classes, on_click}
import sprocket/internal/identifiable_callback.{CallbackFn}
import sprocket/hooks.{WithDeps}
import sprocket/hooks/callback.{callback}
import sprocket/hooks/reducer.{reducer}
import docs/components/clock.{ClockProps, clock}
import docs/components/analog_clock.{AnalogClockProps, analog_clock}
import docs/components/counter.{CounterProps, counter}
import docs/components/hello_button.{HelloButtonProps, hello_button}

type Msg {
  NoOp
  SetTimeUnit(erlang.TimeUnit)
}

type Model {
  Model(time_unit: erlang.TimeUnit)
}

fn update(state: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> state
    SetTimeUnit(time_unit) -> Model(time_unit)
  }
}

fn initial() -> Model {
  Model(time_unit: erlang.Second)
}

pub type MiscPageProps {
  MiscPageProps
}

pub fn misc_page(ctx: Context, _props: MiscPageProps) {
  use ctx, Model(time_unit), _dispatch <- reducer(ctx, initial(), update)

  render(
    ctx,
    [
      article(
        [],
        [
          h1([], [text("Miscellaneous")]),
          h2([], [text("Example Components")]),
          div(
            [],
            [
              // // disable millisecond selection for now, it could have a negative impact on bandwidth costs and resources
              // // consider adding it as an example to try out locally instead
              // component(
              //   unit_toggle,
              //   UnitToggleProps(
              //     current: time_unit,
              //     on_select: fn(unit: erlang.TimeUnit) {
              //       dispatch(SetTimeUnit(unit))
              //     },
              //   ),
              // ),
              div(
                [],
                [
                  component(
                    clock,
                    ClockProps(
                      label: Some("The current time is: "),
                      time_unit: Some(time_unit),
                    ),
                  ),
                ],
              ),
              div([], [component(analog_clock, AnalogClockProps)]),
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
              component(hello_button, HelloButtonProps),
            ],
          ),
        ],
      ),
    ],
  )
}

type UnitToggleProps {
  UnitToggleProps(
    current: erlang.TimeUnit,
    on_select: fn(erlang.TimeUnit) -> Nil,
  )
}

fn unit_toggle(ctx: Context, props: UnitToggleProps) {
  let UnitToggleProps(current, on_select) = props

  use ctx, on_select_millisecond <- callback(
    ctx,
    CallbackFn(fn() { on_select(erlang.Millisecond) }),
    WithDeps([]),
  )
  use ctx, on_select_second <- callback(
    ctx,
    CallbackFn(fn() { on_select(erlang.Second) }),
    WithDeps([]),
  )
  render(
    ctx,
    [
      div(
        [],
        [
          p(
            [],
            [
              button_text(
                [
                  on_click(on_select_second),
                  classes([
                    Some(
                      "p-1 px-2 border dark:border-gray-500 rounded-l bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 active:bg-gray-300 dark:active:bg-gray-600",
                    ),
                    maybe_active(current == erlang.Second),
                  ]),
                ],
                "Second",
              ),
              button_text(
                [
                  on_click(on_select_millisecond),
                  classes([
                    Some(
                      "p-1 px-2 border dark:border-gray-500 rounded-r bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 active:bg-gray-300 dark:active:bg-gray-600",
                    ),
                    maybe_active(current == erlang.Millisecond),
                  ]),
                ],
                "Millisecond",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}

fn maybe_active(is_active: Bool) -> Option(String) {
  case is_active {
    True ->
      Some(
        "text-white bg-gray-500 border-gray-500 hover:bg-gray-500 dark:bg-gray-900",
      )
    False -> None
  }
}
