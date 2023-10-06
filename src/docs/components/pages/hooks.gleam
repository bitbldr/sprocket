import sprocket/context.{Context}
import sprocket/component.{component, render}
import sprocket/html.{article, code_text, h1, h2, p, text}
import docs/components/common.{codeblock, example}
import docs/components/events_counter.{CounterProps, counter}

pub type HooksPageProps {
  HooksPageProps
}

pub fn hooks_page(ctx: Context, _props: HooksPageProps) {
  render(
    ctx,
    [
      article(
        [],
        [
          h1([], [text("Hooks")]),
          p(
            [],
            [
              text(
                "Hooks are the essential mechanism that enable components to implement stateful logic, produce and consume side-effects,
                and couple a component to it's hierarchical context within the UI tree. They also make it easy to abstract and reuse
                stateful logic across different components.",
              ),
            ],
          ),
          h2([], [text("Hook Basics")]),
          p([], [text("COMING SOON")]),
          h2([], [text("State Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Reducer Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Callback Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Effect Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Memo Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Channel Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Context Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Params Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Portal Hooks")]),
          p([], [text("COMING SOON")]),
          h2([], [text("Client Hooks")]),
          p([], [text("COMING SOON")]),
          p(
            [],
            [
              text(
                "
                  We can expand the ",
              ),
              code_text([], "display"),
              text(" component to accept another optional prop called "),
              code_text([], "on_reset"),
              text(
                " which will reset the count and re-render the component when the ",
              ),
              code_text([], "display"),
              text(" component is double-clicked."),
            ],
          ),
          codeblock(
            "gleam",
            "
            pub type DisplayProps {
              DisplayProps(count: Int, on_reset: Option(fn() -> Nil))
            }

            pub fn display(ctx: Context, props: DisplayProps) {
              let DisplayProps(count: count, on_reset: on_reset) = props

              use ctx, on_reset <- callback(
                ctx,
                CallbackFn(option.unwrap(on_reset, fn() { Nil })),
                WithDeps([]),
              )

              render(
                ctx,
                [
                  span(
                    [
                      attributes.on_doubleclick(on_reset),
                      class(
                        \"p-1 px-2 w-10 bg-white dark:bg-gray-900 border-t border-b dark:border-gray-500 align-center text-center\",
                      ),
                    ],
                    [text(int.to_string(count))],
                  ),
                ],
              )
            }
            ",
          ),
          example([component(counter, CounterProps(enable_reset: True))]),
          h2([], [text("Custom Hooks")]),
          p([], [text("COMING SOON")]),
        ],
      ),
    ],
  )
}
