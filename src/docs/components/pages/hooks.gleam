import sprocket/socket.{Socket}
import sprocket/component.{render}
import sprocket/html.{article, h1, h2, p, text}

pub type HooksPageProps {
  HooksPageProps
}

pub fn hooks_page(socket: Socket, _props: HooksPageProps) {
  render(
    socket,
    [
      article(
        [],
        [
          h1([], [text("Hooks")]),
          p(
            [],
            [
              text(
                "Hooks are a core concept in Sprocket. They are a way to implement stateful logic, produce and consume side-effects,
                and couple a component to it's hierarchical context within the UI tree. They also make it easy to isolate and share
                stateful logic across components.",
              ),
            ],
          ),
          h2([], [text("Hook Basics")]),
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
