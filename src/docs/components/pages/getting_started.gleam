import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/html.{a_text, article, h1, h2, p, text}
import sprocket/html/attributes.{href}
import docs/utils/codeblock.{codeblock}

pub type GettingStartedPageProps {
  GettingStartedPageProps
}

pub fn getting_started_page(ctx: Context, _props: GettingStartedPageProps) {
  render(
    ctx,
    [
      article(
        [],
        [
          h1([], [text("Getting Started")]),
          h2([], [text("Install Dependencies")]),
          p(
            [],
            [
              text(
                "
                    Before diving in, lets make sure you have Gleam and the necessary dependencies installed on your system. If you haven't already, head over to the Gleam installation guide and follow the instructions for your operating system.
                    ",
              ),
              text(
                "
                     Once you have Gleam installed, you can create a new project with the following command:
                    ",
              ),
            ],
          ),
          codeblock("bash", "gleam new sprocket-demo"),
          p(
            [],
            [
              text(
                "
                    Then add sprocket as a dependency:
                    ",
              ),
            ],
          ),
          codeblock("bash", "gleam add sprocket"),
          p(
            [],
            [
              text(
                "If you wish to follow along with the same styles as this documentation, you can optionally add Tailwind CSS as well by following the instructions in the ",
              ),
              a_text(
                [href("https://tailwindcss.com/docs/installation")],
                "Tailwind CSS installation guide",
              ),
              text(" and taking a look at the configuration in the "),
              a_text(
                [href("https://github.com/bitbldr/sprocket")],
                "docs repository on GitHub.",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "That's it! Now we can begin our journey to learning how to build real-time server-side components with Sprocket!",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
