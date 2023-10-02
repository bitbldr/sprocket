import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/html.{article, h1, h2, p, text}

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
          h2([], [text("Custom Hooks")]),
          p([], [text("COMING SOON")]),
        ],
      ),
    ],
  )
}
