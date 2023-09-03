import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/html.{a_text, article, div, h1, h2, li, p, span, text, ul}
import sprocket/html/attributes.{class, href}
import docs/utils/codeblock.{codeblock}

pub type IntroductionPageProps {
  IntroductionPageProps
}

pub fn introduction_page(ctx: Context, _props: IntroductionPageProps) {
  render(
    ctx,
    [
      article(
        [],
        [
          h1([], [text("Introduction")]),
          p(
            [],
            [
              text(
                "
                    Welcome to the official documentation of Sprocket, a real-time server-side components library for Gleam! In this guide, we'll
                    cover the core concepts of Sprocket, but some prerequisite knowledge of Gleam is recommended. Gleam is a type-safe functional language designed
                    to harness the power of the Erlang Beam virtual machine. Whether you are a seasoned Gleam enthusiast or new to this exciting language,
                    this documentation will serve as your roadmap to building highly scalable, robust, and efficient server-side components.
                    ",
              ),
            ],
          ),
          div(
            [
              class(
                "flex flex-row p-4 mb-4 text-sm text-yellow-800 rounded-lg bg-yellow-50 dark:bg-gray-800 dark:text-yellow-300",
              ),
            ],
            [
              div([class("mr-2")], [span([class("text-xl")], [text("🚧")])]),
              div(
                [class("flex-grow-1")],
                [
                  span([class("font-bold")], [text("Important Note: ")]),
                  text(
                    "Sprocket is under heavy development and this documentation is a work in progress! Please proceed with caution as things are likely to change.",
                  ),
                ],
              ),
              div([class("ml-2")], [span([class("text-xl")], [text("🚧")])]),
            ],
          ),
          h2([], [text("What is Sprocket?")]),
          p(
            [],
            [
              text(
                "
                      Sprocket is a library based on existing patterns that empowers developers to build real-time applications with ease, embracing the strengths of
                      Gleam's type-safety and the Erlang Beam virtual machine's concurrency and fault-tolerance capabilities. It offers an expressive and
                      intuitive syntax, making it effortless to reason about complex systems and craft maintainable codebases.
                    ",
              ),
            ],
          ),
          p(
            [class("italic")],
            [
              span([class("font-bold")], [text("Fun fact: ")]),
              text(
                "Sprocket is named after the humble bicycle gear that enables the wheels to spin effortlessly! Also, this documentation is completely powered by it!",
              ),
            ],
          ),
          h2([], [text("Why Sprocket?")]),
          p(
            [],
            [
              text(
                "
                      Sprocket was born out of a vision to bridge the gap between functional component views, type-safety, and the real-time server renderd
                      applications. With Sprocket, developers can quickly construct server-side live views without compromising on type-safety and maintainability.
                      By leveraging the Erlang Beam VM, Sprocket enables high-throughput, fault-tolerant, and real-time server renderd applications that 
                      reduce the amount of code required to build rich web applications.
                    ",
              ),
            ],
          ),
          h2([], [text("Key Features")]),
          p(
            [],
            [
              ul(
                [],
                [
                  li(
                    [],
                    [
                      span(
                        [class("font-bold")],
                        [text("Real-time Components: ")],
                      ),
                      text(
                        "Build reactive and real-time applications effortlessly by designing modular and reusable components with Sprocket's
                      declarative approach.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Type-Safety: ")]),
                      text(
                        "Gleam's static typing guarantees that your code is free of runtime errors, making it easier to reason about complex systems and
                        build maintainable codebases.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Concurrency: ")]),
                      text(
                        "Sprocket harnesses the power of the Erlang Beam VM, providing lightweight processes and easy-to-use abstractions for
                      concurrent programming.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Fault-Tolerance: ")]),
                      text(
                        "Battle-tested fault-tolerance mechanisms ensure that your applications stay resilient even under adverse conditions.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Interoperability: ")]),
                      text(
                        "Seamlessly plug-in existing Erlang/Elixir libraries with Gleam's first class FFI.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Scalability: ")]),
                      text(
                        "Scaling your application is a breeze thanks to the Erlang Beam VM's distributed nature.",
                      ),
                    ],
                  ),
                  li(
                    [],
                    [
                      span([class("font-bold")], [text("Open Source: ")]),
                      text(
                        "Sprocket is completely open-source and free to use. Contributions are welcome and encouraged!",
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          h2([], [text("Who Should Read This Documentation?")]),
          p(
            [],
            [
              text(
                "
                    This documentation is tailored to developers and enthusiasts who are eager to explore the world of UI functional programming with Gleam. Whether you are a seasoned Erlang/Elixir developer looking to venture into Gleam or a newcomer to the Erlang ecosystem, this documentation will guide you through the process of building functional real-time server-side components with Sprocket.
                  ",
              ),
            ],
          ),
          p(
            [],
            [
              text(
                "
                    Familiarity with functional programming concepts and the Erlang ecosystem will be beneficial, but not mandatory, as this documentation aims to be accessible to developers from various backgrounds.
                  ",
              ),
            ],
          ),
          h2([], [text("Getting Started")]),
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
